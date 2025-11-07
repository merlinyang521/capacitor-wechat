package ee.forgr.plugin.capacitor_wechat;

import android.content.Context;
import android.content.SharedPreferences;

final class WechatPreferences {

    private WechatPreferences() {}

    static void persist(Context context, String appId, String universalLink) {
        SharedPreferences prefs = context.getSharedPreferences(WechatConstants.PREFS_NAME, Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = prefs.edit();
        editor.putString(WechatConstants.PREF_APP_ID, appId);
        if (universalLink != null) {
            editor.putString(WechatConstants.PREF_UNIVERSAL_LINK, universalLink);
        } else {
            editor.remove(WechatConstants.PREF_UNIVERSAL_LINK);
        }
        editor.apply();
    }

    static String getAppId(Context context) {
        SharedPreferences prefs = context.getSharedPreferences(WechatConstants.PREFS_NAME, Context.MODE_PRIVATE);
        return prefs.getString(WechatConstants.PREF_APP_ID, null);
    }

    static String getUniversalLink(Context context) {
        SharedPreferences prefs = context.getSharedPreferences(WechatConstants.PREFS_NAME, Context.MODE_PRIVATE);
        return prefs.getString(WechatConstants.PREF_UNIVERSAL_LINK, null);
    }
}
