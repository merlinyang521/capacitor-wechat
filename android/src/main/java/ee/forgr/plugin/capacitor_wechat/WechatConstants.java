package ee.forgr.plugin.capacitor_wechat;

final class WechatConstants {
    static final String PREFS_NAME = "CapacitorWechatConfig";
    static final String PREF_APP_ID = "appId";
    static final String PREF_UNIVERSAL_LINK = "universalLink";

    static final String ERROR_NOT_CONFIGURED = "WeChat SDK is not configured. Call initialize() or set plugin config.";
    static final String ERROR_APP_ID_MISSING = "Missing appId parameter.";
    static final String ERROR_SDK_NOT_READY = "Failed to initialize the WeChat SDK.";
    static final String ERROR_WECHAT_NOT_INSTALLED = "WeChat is not installed on this device.";
    static final String ERROR_OPERATION_IN_PROGRESS = "Another WeChat request is already in progress.";
    static final String ERROR_INVALID_ARGUMENTS = "Invalid or missing arguments.";
    static final String ERROR_REQUEST_FAILED = "Failed to send request to WeChat.";
    static final String ERROR_BITMAP_LOAD = "Unable to load media content for sharing.";

    private WechatConstants() {}
}
