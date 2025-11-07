package ee.forgr.plugin.capacitor_wechat;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;

import com.tencent.mm.opensdk.modelbase.BaseReq;
import com.tencent.mm.opensdk.modelbase.BaseResp;
import com.tencent.mm.opensdk.openapi.IWXAPI;
import com.tencent.mm.opensdk.openapi.IWXAPIEventHandler;

/**
 * Extend this activity from your app's {@code package.wxapi.WXEntryActivity} and {@code WXPayEntryActivity}.
 */
public class WechatResponseActivity extends Activity implements IWXAPIEventHandler {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        handleIntent(getIntent());
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        handleIntent(intent);
    }

    private void handleIntent(Intent intent) {
        IWXAPI api = WechatManager.getInstance().getOrCreateApi(this);
        if (api == null) {
            finish();
            return;
        }
        api.handleIntent(intent, this);
    }

    @Override
    public void onReq(BaseReq baseReq) {
        WechatManager.getInstance().handleRequest(baseReq);
        finish();
    }

    @Override
    public void onResp(BaseResp baseResp) {
        WechatManager.getInstance().handleResponse(baseResp);
        finish();
    }
}
