import Foundation
import UIKit

#if canImport(WechatOpenSDK)
import WechatOpenSDK
#endif

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

#if canImport(WechatOpenSDK)
public class CapacitorWechat: NSObject, WXApiDelegate {
    public static let shared = CapacitorWechat()

    private let storageAppIdKey = "CapacitorWechat.appId"
    private let storageUniversalLinkKey = "CapacitorWechat.universalLink"
    private let workerQueue = DispatchQueue(label: "CapacitorWechat.worker", qos: .userInitiated)

    private var appId: String?
    private var universalLink: String?

    private var authCompletion: ((Result<WechatAuthResponse, Error>) -> Void)?
    private var shareCompletion: ((Result<Void, Error>) -> Void)?
    private var payCompletion: ((Result<Void, Error>) -> Void)?
    private var miniProgramCompletion: ((Result<String?, Error>) -> Void)?
    private var invoiceCompletion: ((Result<[[String: String]], Error>) -> Void)?

    private override init() {
        super.init()
    }

    func bootstrap(appId: String?, universalLink: String?) {
        let storedAppId = appId ?? UserDefaults.standard.string(forKey: storageAppIdKey)
        let storedLink = universalLink ?? UserDefaults.standard.string(forKey: storageUniversalLinkKey)
        if let storedAppId {
            try? configure(appId: storedAppId, universalLink: storedLink)
        }
    }

    func configure(appId: String, universalLink: String?) throws {
        self.appId = appId
        self.universalLink = universalLink

        UserDefaults.standard.set(appId, forKey: storageAppIdKey)
        if let universalLink {
            UserDefaults.standard.set(universalLink, forKey: storageUniversalLinkKey)
        } else {
            UserDefaults.standard.removeObject(forKey: storageUniversalLinkKey)
        }

        DispatchQueue.main.async {
            WXApi.registerApp(appId, universalLink: universalLink)
        }
    }

    func isWechatInstalled() -> Bool {
        WXApi.isWXAppInstalled()
    }

    func auth(scope: String, state: String?, presenter: UIViewController, completion: @escaping (Result<WechatAuthResponse, Error>) -> Void) throws {
        try ensureConfigured()
        guard WXApi.isWXAppInstalled() else {
            throw WechatError.wechatNotInstalled
        }
        guard authCompletion == nil else {
            throw WechatError.operationInProgress("auth")
        }
        authCompletion = completion

        DispatchQueue.main.async {
            let req = SendAuthReq()
            req.scope = scope
            req.state = state ?? UUID().uuidString
            WXApi.sendAuthReq(req, viewController: presenter, delegate: self) { success in
                if !success {
                    self.consumeAuth(with: .failure(WechatError.requestFailed))
                }
            }
        }
    }

    func share(options: WechatShareOptions, completion: @escaping (Result<Void, Error>) -> Void) throws {
        try ensureConfigured()
        guard WXApi.isWXAppInstalled() else {
            throw WechatError.wechatNotInstalled
        }
        guard shareCompletion == nil else {
            throw WechatError.operationInProgress("share")
        }
        shareCompletion = completion

        workerQueue.async {
            do {
                let request = try self.buildShareRequest(options: options)
                DispatchQueue.main.async {
                    if !WXApi.send(request, completion: { success in
                        if !success {
                            self.consumeShare(with: .failure(WechatError.requestFailed))
                        }
                    }) {
                        self.consumeShare(with: .failure(WechatError.requestFailed))
                    }
                }
            } catch {
                self.consumeShare(with: .failure(error))
            }
        }
    }

    func sendPaymentRequest(options: WechatPaymentOptions, completion: @escaping (Result<Void, Error>) -> Void) throws {
        try ensureConfigured()
        guard WXApi.isWXAppInstalled() else {
            throw WechatError.wechatNotInstalled
        }
        guard payCompletion == nil else {
            throw WechatError.operationInProgress("payment")
        }
        guard let timeStamp = UInt32(options.timeStamp) else {
            throw WechatError.invalidArguments("Invalid timestamp value.")
        }

        let partnerId = options.partnerId
        let prepayId = options.prepayId
        let nonceStr = options.nonceStr
        let packageValue = options.package
        let sign = options.sign

        let req = PayReq()
        req.partnerId = partnerId
        req.prepayId = prepayId
        req.nonceStr = nonceStr
        req.timeStamp = timeStamp
        req.package = packageValue
        req.sign = sign

        payCompletion = completion
        DispatchQueue.main.async {
            if !WXApi.send(req, completion: { success in
                if !success {
                    self.consumePay(with: .failure(WechatError.requestFailed))
                }
            }) {
                self.consumePay(with: .failure(WechatError.requestFailed))
            }
        }
    }

    func openMiniProgram(options: WechatMiniProgramOptions, completion: @escaping (Result<String?, Error>) -> Void) throws {
        try ensureConfigured()
        guard WXApi.isWXAppInstalled() else {
            throw WechatError.wechatNotInstalled
        }
        guard miniProgramCompletion == nil else {
            throw WechatError.operationInProgress("miniProgram")
        }
        guard !options.username.isEmpty else {
            throw WechatError.invalidArguments("username is required.")
        }

        let req = WXLaunchMiniProgramReq.object()
        req.userName = options.username
        req.path = options.path
        req.miniProgramType = UInt32(options.type ?? 0)

        miniProgramCompletion = completion
        DispatchQueue.main.async {
            if !WXApi.send(req, completion: { success in
                if !success {
                    self.consumeMiniProgram(with: .failure(WechatError.requestFailed))
                }
            }) {
                self.consumeMiniProgram(with: .failure(WechatError.requestFailed))
            }
        }
    }

    func chooseInvoice(options: WechatInvoiceOptions, completion: @escaping (Result<[[String: String]], Error>) -> Void) throws {
        try ensureConfigured()
        guard WXApi.isWXAppInstalled() else {
            throw WechatError.wechatNotInstalled
        }
        guard invoiceCompletion == nil else {
            throw WechatError.operationInProgress("invoice")
        }

        guard
            !options.appId.isEmpty,
            !options.cardSign.isEmpty,
            !options.signType.isEmpty,
            !options.timeStamp.isEmpty,
            !options.nonceStr.isEmpty
        else {
            throw WechatError.invalidArguments("Missing invoice parameters.")
        }

        let req = WXChooseInvoiceReq()
        req.appID = options.appId
        req.cardSign = options.cardSign
        req.nonceStr = options.nonceStr
        req.signType = options.signType
        req.timeStamp = UInt32(options.timeStamp) ?? 0

        invoiceCompletion = completion
        DispatchQueue.main.async {
            if !WXApi.send(req, completion: { success in
                if !success {
                    self.consumeInvoice(with: .failure(WechatError.requestFailed))
                }
            }) {
                self.consumeInvoice(with: .failure(WechatError.requestFailed))
            }
        }
    }

    @discardableResult
    func handleOpenURL(_ url: URL) -> Bool {
        WXApi.handleOpen(url, delegate: self)
    }

    @discardableResult
    func handleUniversalLink(_ activity: NSUserActivity) -> Bool {
        WXApi.handleOpenUniversalLink(activity, delegate: self)
    }

    // MARK: - WXApiDelegate

    public func onReq(_ req: BaseReq) {}

    public func onResp(_ resp: BaseResp) {
        switch resp {
        case let authResp as SendAuthResp:
            if resp.errCode == WXSuccess.rawValue {
                let response = WechatAuthResponse(code: authResp.code ?? "", state: authResp.state)
                consumeAuth(with: .success(response))
            } else {
                consumeAuth(with: .failure(mapError(code: resp.errCode)))
            }
        case _ as SendMessageToWXResp:
            if resp.errCode == WXSuccess.rawValue {
                consumeShare(with: .success(()))
            } else {
                consumeShare(with: .failure(mapError(code: resp.errCode)))
            }
        case _ as PayResp:
            if resp.errCode == WXSuccess.rawValue {
                consumePay(with: .success(()))
            } else {
                consumePay(with: .failure(mapError(code: resp.errCode)))
            }
        case let miniResp as WXLaunchMiniProgramResp:
            if resp.errCode == WXSuccess.rawValue {
                consumeMiniProgram(with: .success(miniResp.extMsg))
            } else {
                consumeMiniProgram(with: .failure(mapError(code: resp.errCode)))
            }
        case let invoiceResp as WXChooseInvoiceResp:
            if resp.errCode == WXSuccess.rawValue {
                let items = invoiceResp.cardAry?.compactMap { item -> [String: String]? in
                    guard let card = item as? WXInvoiceItem else { return nil }
                    return [
                        "cardId": card.cardId ?? "",
                        "encryptCode": card.encryptCode ?? ""
                    ]
                } ?? []
                consumeInvoice(with: .success(items))
            } else {
                consumeInvoice(with: .failure(mapError(code: resp.errCode)))
            }
        default:
            break
        }
    }

    // MARK: - Helpers

    private func ensureConfigured() throws {
        guard appId != nil else {
            throw WechatError.notConfigured
        }
    }

    private func mapError(code: Int32) -> Error {
        switch code {
        case WXErrCodeUserCancel.rawValue:
            return WechatError.userCancelled
        case WXErrCodeAuthDeny.rawValue:
            return WechatError.invalidArguments("Authorization denied.")
        case WXErrCodeUnsupport.rawValue:
            return WechatError.invalidArguments("Operation not supported.")
        case WXErrCodeSentFail.rawValue:
            return WechatError.requestFailed
        default:
            return WechatError.unknown(code)
        }
    }

    private func buildShareRequest(options: WechatShareOptions) throws -> SendMessageToWXReq {
        let req = SendMessageToWXReq()
        req.scene = Int32(options.scene)

        guard let type = options.type else {
            throw WechatError.invalidArguments("Share type is required.")
        }

        switch type {
        case "text":
            let text = options.text ?? ""
            req.bText = true
            req.text = text
        default:
            req.bText = false
            let message = WXMediaMessage()
            message.title = options.title
            message.description = options.description

            switch type {
            case "image":
                guard let source = options.imageUrl else {
                    throw WechatError.invalidArguments("imageUrl is required for image shares.")
                }
                let imageData = try loadData(from: source)
                let imageObject = WXImageObject()
                imageObject.imageData = imageData
                message.mediaObject = imageObject
                message.thumbData = makeThumbnail(from: imageData)
            case "link":
                guard let link = options.link else {
                    throw WechatError.invalidArguments("link is required for link shares.")
                }
                let page = WXWebpageObject()
                page.webpageUrl = link
                message.mediaObject = page
                if let thumb = options.thumbUrl {
                    message.thumbData = makeThumbnail(from: try loadData(from: thumb))
                }
            case "music":
                guard let mediaUrl = options.mediaUrl else {
                    throw WechatError.invalidArguments("mediaUrl is required for music shares.")
                }
                let music = WXMusicObject()
                music.musicUrl = mediaUrl
                message.mediaObject = music
                if let thumb = options.thumbUrl {
                    message.thumbData = makeThumbnail(from: try loadData(from: thumb))
                }
            case "video":
                guard let mediaUrl = options.mediaUrl else {
                    throw WechatError.invalidArguments("mediaUrl is required for video shares.")
                }
                let video = WXVideoObject()
                video.videoUrl = mediaUrl
                message.mediaObject = video
                if let thumb = options.thumbUrl {
                    message.thumbData = makeThumbnail(from: try loadData(from: thumb))
                }
            case "miniprogram":
                guard let username = options.miniProgramUsername else {
                    throw WechatError.invalidArguments("miniProgramUsername is required for mini program shares.")
                }
                let mini = WXMiniProgramObject()
                mini.userName = username
                mini.path = options.miniProgramPath
                mini.miniprogramType = UInt32(options.miniProgramType ?? 0)
                mini.webpageUrl = options.miniProgramWebPageUrl
                if let hdImage = options.imageUrl {
                    mini.hdImageData = try loadData(from: hdImage)
                }
                message.mediaObject = mini
                req.scene = Int32(WXSceneSession.rawValue)
            default:
                throw WechatError.invalidArguments("Unsupported share type \(type).")
            }

            req.message = message
        }

        return req
    }

    private func loadData(from source: String) throws -> Data {
        if source.hasPrefix("data:") {
            guard let comma = source.firstIndex(of: ",") else {
                throw WechatError.invalidArguments("Invalid data URI.")
            }
            let base64 = String(source[source.index(after: comma)...])
            guard let data = Data(base64Encoded: base64) else {
                throw WechatError.invalidArguments("Invalid Base64 data.")
            }
            return data
        }

        if let url = URL(string: source), url.scheme == "http" || url.scheme == "https" {
            return try Data(contentsOf: url)
        }

        let fileURL: URL
        if source.hasPrefix("file://") {
            guard let url = URL(string: source) else {
                throw WechatError.invalidArguments("Invalid file URL.")
            }
            fileURL = url
        } else {
            fileURL = URL(fileURLWithPath: source)
        }

        return try Data(contentsOf: fileURL)
    }

    private func makeThumbnail(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        var compression: CGFloat = 0.8
        var result = image.jpegData(compressionQuality: compression)
        while let current = result, current.count > 128 * 1024, compression > 0.2 {
            compression -= 0.1
            result = image.jpegData(compressionQuality: compression)
        }
        return result
    }

    private func consumeAuth(with result: Result<WechatAuthResponse, Error>) {
        guard let completion = authCompletion else { return }
        authCompletion = nil
        DispatchQueue.main.async {
            completion(result)
        }
    }

    private func consumeShare(with result: Result<Void, Error>) {
        guard let completion = shareCompletion else { return }
        shareCompletion = nil
        DispatchQueue.main.async {
            completion(result)
        }
    }

    private func consumePay(with result: Result<Void, Error>) {
        guard let completion = payCompletion else { return }
        payCompletion = nil
        DispatchQueue.main.async {
            completion(result)
        }
    }

    private func consumeMiniProgram(with result: Result<String?, Error>) {
        guard let completion = miniProgramCompletion else { return }
        miniProgramCompletion = nil
        DispatchQueue.main.async {
            completion(result)
        }
    }

    private func consumeInvoice(with result: Result<[[String: String]], Error>) {
        guard let completion = invoiceCompletion else { return }
        invoiceCompletion = nil
        DispatchQueue.main.async {
            completion(result)
        }
    }
}
#else
public class CapacitorWechat: NSObject {
    public static let shared = CapacitorWechat()

    private override init() {
        super.init()
    }

    func bootstrap(appId: String?, universalLink: String?) {}

    func configure(appId: String, universalLink: String?) throws {
        throw WechatError.sdkUnavailable
    }

    func isWechatInstalled() -> Bool {
        false
    }

    func auth(scope: String, state: String?, presenter: UIViewController, completion: @escaping (Result<WechatAuthResponse, Error>) -> Void) throws {
        throw WechatError.sdkUnavailable
    }

    func share(options: WechatShareOptions, completion: @escaping (Result<Void, Error>) -> Void) throws {
        throw WechatError.sdkUnavailable
    }

    func sendPaymentRequest(options: WechatPaymentOptions, completion: @escaping (Result<Void, Error>) -> Void) throws {
        throw WechatError.sdkUnavailable
    }

    func openMiniProgram(options: WechatMiniProgramOptions, completion: @escaping (Result<String?, Error>) -> Void) throws {
        throw WechatError.sdkUnavailable
    }

    func chooseInvoice(options: WechatInvoiceOptions, completion: @escaping (Result<[[String: String]], Error>) -> Void) throws {
        throw WechatError.sdkUnavailable
    }

    @discardableResult
    func handleOpenURL(_ url: URL) -> Bool {
        false
    }

    @discardableResult
    func handleUniversalLink(_ activity: NSUserActivity) -> Bool {
        false
    }
}
#endif
