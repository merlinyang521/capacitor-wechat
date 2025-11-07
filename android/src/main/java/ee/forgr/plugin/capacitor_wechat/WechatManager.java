package ee.forgr.plugin.capacitor_wechat;

import android.content.Context;
import android.text.TextUtils;

import com.tencent.mm.opensdk.modelbase.BaseReq;
import com.tencent.mm.opensdk.modelbase.BaseResp;
import com.tencent.mm.opensdk.openapi.IWXAPI;
import com.tencent.mm.opensdk.openapi.WXAPIFactory;

import java.lang.ref.WeakReference;
import java.util.Queue;
import java.util.concurrent.ConcurrentLinkedQueue;

final class WechatManager {
    private static final WechatManager INSTANCE = new WechatManager();

    private final Queue<BaseResp> pendingResponses = new ConcurrentLinkedQueue<>();
    private final Queue<BaseReq> pendingRequests = new ConcurrentLinkedQueue<>();

    private WeakReference<WechatResponseListener> listenerRef = new WeakReference<>(null);
    private IWXAPI api;
    private String currentAppId;
    private Context appContext;

    static WechatManager getInstance() {
        return INSTANCE;
    }

    synchronized void configure(Context context, String appId) {
        this.appContext = context.getApplicationContext();
        if (TextUtils.isEmpty(appId)) {
            return;
        }

        if (appId.equals(currentAppId) && api != null) {
            return;
        }

        currentAppId = appId;
        api = WXAPIFactory.createWXAPI(appContext, appId, true);
        api.registerApp(appId);
    }

    synchronized IWXAPI getApi() {
        return api;
    }

    synchronized IWXAPI getOrCreateApi(Context context) {
        if (api == null) {
            String storedAppId = WechatPreferences.getAppId(context);
            if (!TextUtils.isEmpty(storedAppId)) {
                configure(context, storedAppId);
            }
        }
        return api;
    }

    void registerListener(WechatResponseListener listener) {
        listenerRef = new WeakReference<>(listener);
        flushQueues();
    }

    void unregisterListener(WechatResponseListener listener) {
        WechatResponseListener current = listenerRef.get();
        if (current == listener) {
            listenerRef = new WeakReference<>(null);
        }
    }

    void handleResponse(BaseResp resp) {
        WechatResponseListener listener = listenerRef.get();
        if (listener != null) {
            listener.onWechatResponse(resp);
        } else {
            pendingResponses.add(resp);
        }
    }

    void handleRequest(BaseReq req) {
        WechatResponseListener listener = listenerRef.get();
        if (listener != null) {
            listener.onWechatRequest(req);
        } else {
            pendingRequests.add(req);
        }
    }

    private void flushQueues() {
        WechatResponseListener listener = listenerRef.get();
        if (listener == null) {
            return;
        }
        BaseResp resp;
        while ((resp = pendingResponses.poll()) != null) {
            listener.onWechatResponse(resp);
        }
        BaseReq req;
        while ((req = pendingRequests.poll()) != null) {
            listener.onWechatRequest(req);
        }
    }
}
