import Foundation
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(CapacitorWechatPlugin)
public class CapacitorWechatPlugin: CAPPlugin, CAPBridgedPlugin {
    private let PLUGIN_VERSION: String = "7.0.5"
    public let identifier = "CapacitorWechatPlugin"
    public let jsName = "CapacitorWechat"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "isInstalled", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "auth", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "share", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "sendPaymentRequest", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openMiniProgram", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "chooseInvoice", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getPluginVersion", returnType: CAPPluginReturnPromise)
    ]

    private let implementation = CapacitorWechat()

    @objc func isInstalled(_ call: CAPPluginCall) {
        call.resolve([
            "installed": implementation.isInstalled()
        ])
    }

    @objc func auth(_ call: CAPPluginCall) {
        guard let scope = call.getString("scope") else {
            call.reject("Missing scope parameter")
            return
        }

        let state = call.getString("state")

        implementation.auth(scope: scope, state: state) { result in
            switch result {
            case .success(let response):
                call.resolve([
                    "code": response.code,
                    "state": response.state ?? ""
                ])
            case .failure(let error):
                call.reject("Authentication failed: \(error.localizedDescription)")
            }
        }
    }

    @objc func share(_ call: CAPPluginCall) {
        guard let scene = call.getInt("scene"),
              let type = call.getString("type") else {
            call.reject("Missing required parameters")
            return
        }

        let options = WechatShareOptions(
            scene: scene,
            type: type,
            text: call.getString("text"),
            title: call.getString("title"),
            description: call.getString("description"),
            link: call.getString("link"),
            imageUrl: call.getString("imageUrl"),
            thumbUrl: call.getString("thumbUrl"),
            mediaUrl: call.getString("mediaUrl"),
            miniProgramUsername: call.getString("miniProgramUsername"),
            miniProgramPath: call.getString("miniProgramPath"),
            miniProgramType: call.getInt("miniProgramType"),
            miniProgramWebPageUrl: call.getString("miniProgramWebPageUrl")
        )

        implementation.share(options: options) { result in
            switch result {
            case .success:
                call.resolve()
            case .failure(let error):
                call.reject("Share failed: \(error.localizedDescription)")
            }
        }
    }

    @objc func sendPaymentRequest(_ call: CAPPluginCall) {
        guard let partnerId = call.getString("partnerId"),
              let prepayId = call.getString("prepayId"),
              let nonceStr = call.getString("nonceStr"),
              let timeStamp = call.getString("timeStamp"),
              let package = call.getString("package"),
              let sign = call.getString("sign") else {
            call.reject("Missing required payment parameters")
            return
        }

        let options = WechatPaymentOptions(
            partnerId: partnerId,
            prepayId: prepayId,
            nonceStr: nonceStr,
            timeStamp: timeStamp,
            package: package,
            sign: sign
        )

        implementation.sendPaymentRequest(options: options) { result in
            switch result {
            case .success:
                call.resolve()
            case .failure(let error):
                call.reject("Payment failed: \(error.localizedDescription)")
            }
        }
    }

    @objc func openMiniProgram(_ call: CAPPluginCall) {
        guard let username = call.getString("username") else {
            call.reject("Missing username parameter")
            return
        }

        let path = call.getString("path")
        let type = call.getInt("type") ?? 0

        implementation.openMiniProgram(username: username, path: path, type: type) { result in
            switch result {
            case .success:
                call.resolve()
            case .failure(let error):
                call.reject("Failed to open mini program: \(error.localizedDescription)")
            }
        }
    }

    @objc func chooseInvoice(_ call: CAPPluginCall) {
        guard let appId = call.getString("appId"),
              let signType = call.getString("signType"),
              let cardSign = call.getString("cardSign"),
              let timeStamp = call.getString("timeStamp"),
              let nonceStr = call.getString("nonceStr") else {
            call.reject("Missing required invoice parameters")
            return
        }

        let options = WechatInvoiceOptions(
            appId: appId,
            signType: signType,
            cardSign: cardSign,
            timeStamp: timeStamp,
            nonceStr: nonceStr
        )

        implementation.chooseInvoice(options: options) { result in
            switch result {
            case .success(let cards):
                call.resolve(["cards": cards])
            case .failure(let error):
                call.reject("Failed to choose invoice: \(error.localizedDescription)")
            }
        }
    }

    @objc func getPluginVersion(_ call: CAPPluginCall) {
        call.resolve(["version": self.PLUGIN_VERSION])
    }

}
