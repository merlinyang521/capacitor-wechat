import Foundation
import UIKit
import WechatOpenSDK

extension CapacitorWechat: WXApiDelegate {
    public func onReq(_ req: BaseReq) {}

    public func onResp(_ resp: BaseResp) {
        switch resp {
        case let authResp as SendAuthResp:
            resolve(resp: authResp) { response in
                let payload = WechatAuthResponse(code: response.code ?? "", state: response.state)
                consumeAuth(with: .success(payload))
            }
        case is SendMessageToWXResp:
            resolve(resp: resp) { _ in consumeShare(with: .success(())) }
        case is PayResp:
            resolve(resp: resp) { _ in consumePay(with: .success(())) }
        case let miniResp as WXLaunchMiniProgramResp:
            resolve(resp: miniResp) { response in
                consumeMiniProgram(with: .success(response.extMsg))
            }
        case let invoiceResp as WXChooseInvoiceResp:
            resolve(resp: invoiceResp) { response in
                consumeInvoice(with: .success(CapacitorWechat.mapInvoices(response.cardAry)))
            }
        default:
            break
        }
    }
}

extension CapacitorWechat {
    func ensureConfigured() throws {
        guard appId != nil else {
            throw WechatError.notConfigured
        }
    }

    func resolve<T: BaseResp>(resp: T, success: (T) -> Void) {
        if resp.errCode == WXSuccess.rawValue {
            success(resp)
        } else {
            let error = mapError(code: resp.errCode)
            routeFailure(for: resp, error: error)
        }
    }

    func routeFailure<T: BaseResp>(for resp: T, error: Error) {
        switch resp {
        case is SendAuthResp:
            consumeAuth(with: .failure(error))
        case is SendMessageToWXResp:
            consumeShare(with: .failure(error))
        case is PayResp:
            consumePay(with: .failure(error))
        case is WXLaunchMiniProgramResp:
            consumeMiniProgram(with: .failure(error))
        case is WXChooseInvoiceResp:
            consumeInvoice(with: .failure(error))
        default:
            break
        }
    }

    func mapError(code: Int32) -> Error {
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

    static func mapInvoices(_ items: [Any]?) -> [[String: String]] {
        guard let items else { return [] }
        return items.compactMap { entry in
            guard let invoice = entry as? WXInvoiceItem else { return nil }
            return [
                "cardId": invoice.cardId ?? "",
                "encryptCode": invoice.encryptCode ?? ""
            ]
        }
    }

    func consumeAuth(with result: Result<WechatAuthResponse, Error>) {
        guard let completion = authCompletion else { return }
        authCompletion = nil
        DispatchQueue.main.async {
            completion(result)
        }
    }

    func consumeShare(with result: Result<Void, Error>) {
        guard let completion = shareCompletion else { return }
        shareCompletion = nil
        DispatchQueue.main.async {
            completion(result)
        }
    }

    func consumePay(with result: Result<Void, Error>) {
        guard let completion = payCompletion else { return }
        payCompletion = nil
        DispatchQueue.main.async {
            completion(result)
        }
    }

    func consumeMiniProgram(with result: Result<String?, Error>) {
        guard let completion = miniProgramCompletion else { return }
        miniProgramCompletion = nil
        DispatchQueue.main.async {
            completion(result)
        }
    }

    func consumeInvoice(with result: Result<[[String: String]], Error>) {
        guard let completion = invoiceCompletion else { return }
        invoiceCompletion = nil
        DispatchQueue.main.async {
            completion(result)
        }
    }
}
