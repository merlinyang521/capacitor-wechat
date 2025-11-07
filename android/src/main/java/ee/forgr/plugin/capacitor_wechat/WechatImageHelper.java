package ee.forgr.plugin.capacitor_wechat;

import android.content.ContentResolver;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.net.Uri;
import android.text.TextUtils;
import android.util.Base64;
import java.io.ByteArrayOutputStream;
import java.io.Closeable;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;

final class WechatImageHelper {

    private static final int MAX_THUMB_BYTES = 128 * 1024;

    private WechatImageHelper() {}

    static Bitmap loadBitmap(Context context, String source) throws IOException {
        if (TextUtils.isEmpty(source)) {
            return null;
        }

        if (source.startsWith("data:")) {
            return decodeBase64(source);
        }

        if (source.startsWith("http://") || source.startsWith("https://")) {
            return downloadBitmap(source);
        }

        if (source.startsWith("content://")) {
            return decodeFromContentUri(context, source);
        }

        if (source.startsWith("file://")) {
            return BitmapFactory.decodeFile(Uri.parse(source).getPath());
        }

        File file = new File(source);
        if (file.exists()) {
            return BitmapFactory.decodeFile(file.getAbsolutePath());
        }

        // Try loading from cache directory relative path
        File cacheRelative = new File(context.getCacheDir(), source);
        if (cacheRelative.exists()) {
            return BitmapFactory.decodeFile(cacheRelative.getAbsolutePath());
        }

        return null;
    }

    static byte[] bitmapToBytes(Bitmap bitmap) {
        if (bitmap == null) {
            return null;
        }
        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
        byte[] data = stream.toByteArray();
        closeQuietly(stream);
        return data;
    }

    static byte[] buildThumbnail(Bitmap bitmap) {
        if (bitmap == null) {
            return null;
        }

        Bitmap scaled = bitmap;
        int quality = 90;
        byte[] data = compress(scaled, quality);

        while (data != null && data.length > MAX_THUMB_BYTES && quality > 10) {
            quality -= 10;
            data = compress(scaled, quality);
        }

        if (data != null && data.length > MAX_THUMB_BYTES) {
            float ratio = (float) Math.sqrt((double) data.length / MAX_THUMB_BYTES);
            int width = Math.max(1, (int) (scaled.getWidth() / ratio));
            int height = Math.max(1, (int) (scaled.getHeight() / ratio));
            Bitmap resized = Bitmap.createScaledBitmap(scaled, width, height, true);
            data = compress(resized, quality);
            if (resized != scaled) {
                resized.recycle();
            }
        }

        return data;
    }

    private static byte[] compress(Bitmap bitmap, int quality) {
        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.JPEG, quality, stream);
        byte[] data = stream.toByteArray();
        closeQuietly(stream);
        return data;
    }

    private static Bitmap decodeBase64(String dataUrl) {
        int commaIndex = dataUrl.indexOf(',');
        String base64 = commaIndex >= 0 ? dataUrl.substring(commaIndex + 1) : dataUrl;
        byte[] decoded = Base64.decode(base64, Base64.DEFAULT);
        return BitmapFactory.decodeByteArray(decoded, 0, decoded.length);
    }

    private static Bitmap downloadBitmap(String urlString) throws IOException {
        HttpURLConnection connection = null;
        InputStream stream = null;
        try {
            URL url = new URL(urlString);
            connection = (HttpURLConnection) url.openConnection();
            connection.setConnectTimeout(10000);
            connection.setReadTimeout(15000);
            connection.connect();
            if (connection.getResponseCode() != HttpURLConnection.HTTP_OK) {
                throw new IOException("HTTP " + connection.getResponseCode() + " when fetching " + urlString);
            }
            stream = connection.getInputStream();
            return BitmapFactory.decodeStream(stream);
        } finally {
            if (connection != null) {
                connection.disconnect();
            }
            closeQuietly(stream);
        }
    }

    private static Bitmap decodeFromContentUri(Context context, String uriString) throws IOException {
        ContentResolver resolver = context.getContentResolver();
        InputStream stream = null;
        try {
            stream = resolver.openInputStream(Uri.parse(uriString));
            if (stream == null) {
                return null;
            }
            return BitmapFactory.decodeStream(stream);
        } finally {
            closeQuietly(stream);
        }
    }

    static Bitmap scaleDown(Bitmap bitmap, int maxSize) {
        if (bitmap == null) {
            return null;
        }
        int width = bitmap.getWidth();
        int height = bitmap.getHeight();
        if (width <= maxSize && height <= maxSize) {
            return bitmap;
        }
        float ratio = Math.min((float) maxSize / width, (float) maxSize / height);
        Matrix matrix = new Matrix();
        matrix.postScale(ratio, ratio);
        Bitmap scaled = Bitmap.createBitmap(bitmap, 0, 0, width, height, matrix, true);
        bitmap.recycle();
        return scaled;
    }

    private static void closeQuietly(Closeable closeable) {
        if (closeable != null) {
            try {
                closeable.close();
            } catch (IOException ignored) {}
        }
    }
}
