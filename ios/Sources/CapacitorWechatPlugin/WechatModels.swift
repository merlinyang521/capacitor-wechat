import Foundation

public struct WechatAuthResponse {
    let code: String
    let state: String?
}

public struct WechatShareOptions {
    let scene: Int
    let type: String?
    let text: String?
    let title: String?
    let description: String?
    let link: String?
    let imageUrl: String?
    let thumbUrl: String?
    let mediaUrl: String?
    let miniProgramUsername: String?
    let miniProgramPath: String?
    let miniProgramType: Int?
    let miniProgramWebPageUrl: String?
}

public struct WechatPaymentOptions {
    let partnerId: String
    let prepayId: String
    let nonceStr: String
    let timeStamp: String
    let package: String
    let sign: String
}

public struct WechatMiniProgramOptions {
    let username: String
    let path: String?
    let type: Int?
}

public struct WechatInvoiceOptions {
    let appId: String
    let signType: String
    let cardSign: String
    let timeStamp: String
    let nonceStr: String
}

enum WechatError: LocalizedError {
    case sdkUnavailable
    case notConfigured
    case wechatNotInstalled
    case userCancelled
    case presenterMissing
    case operationInProgress(String)
    case invalidArguments(String)
    case requestFailed
    case unknown(Int32)

    var errorDescription: String? {
        switch self {
        case .sdkUnavailable:
            return "WechatOpenSDK is not linked. Follow the installation guide to add the official SDK."
        case .notConfigured:
            return "WeChat SDK is not configured yet. Call initialize() or set the plugin config."
        case .wechatNotInstalled:
            return "WeChat is not installed on this device."
        case .presenterMissing:
            return "No view controller available to present WeChat UI."
        case .operationInProgress(let name):
            return "A \(name) operation is already running."
        case .invalidArguments(let reason):
            return reason
        case .userCancelled:
            return "User cancelled the WeChat operation."
        case .requestFailed:
            return "Failed to send the request to WeChat."
        case .unknown(let code):
            return "WeChat returned error code \(code)."
        }
    }
}
