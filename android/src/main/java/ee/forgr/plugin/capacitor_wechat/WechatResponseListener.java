package ee.forgr.plugin.capacitor_wechat;

import com.tencent.mm.opensdk.modelbase.BaseReq;
import com.tencent.mm.opensdk.modelbase.BaseResp;

interface WechatResponseListener {
    void onWechatResponse(BaseResp resp);
    void onWechatRequest(BaseReq req);
}
