import Foundation
import UIKit
import WechatOpenSDK

public final class CapacitorWechat: NSObject {
    public static let shared = CapacitorWechat()

    let storageAppIdKey = "CapacitorWechat.appId"
    let storageUniversalLinkKey = "CapacitorWechat.universalLink"
    let workerQueue = DispatchQueue(label: "CapacitorWechat.worker", qos: .userInitiated)

    var appId: String?
    var universalLink: String?

    var authCompletion: ((Result<WechatAuthResponse, Error>) -> Void)?
    var shareCompletion: ((Result<Void, Error>) -> Void)?
    var payCompletion: ((Result<Void, Error>) -> Void)?
    var miniProgramCompletion: ((Result<String?, Error>) -> Void)?
    var invoiceCompletion: ((Result<[[String: String]], Error>) -> Void)?

    override private init() {
        super.init()
    }
}
