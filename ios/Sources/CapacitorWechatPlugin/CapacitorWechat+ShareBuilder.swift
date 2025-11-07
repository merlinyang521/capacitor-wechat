import Foundation
import UIKit
import WechatOpenSDK

extension CapacitorWechat {
    func buildShareRequest(options: WechatShareOptions) throws -> SendMessageToWXReq {
        guard let type = options.type else {
            throw WechatError.invalidArguments("Share type is required.")
        }

        if type == "text" {
            return buildTextShare(options: options)
        }

        let message = try buildMediaMessage(for: type, options: options)
        let req = SendMessageToWXReq()
        req.message = message
        let sessionScene = Int(WXSceneSession.rawValue)
        let sceneValue = type == "miniprogram" ? sessionScene : options.scene
        req.scene = Int32(sceneValue)
        req.bText = false
        return req
    }

    func buildTextShare(options: WechatShareOptions) -> SendMessageToWXReq {
        let req = SendMessageToWXReq()
        req.bText = true
        req.text = options.text ?? ""
        req.scene = Int32(options.scene)
        return req
    }

    func buildMediaMessage(for type: String, options: WechatShareOptions) throws -> WXMediaMessage {
        let message = WXMediaMessage()
        message.title = options.title ?? ""
        message.description = options.description ?? ""

        switch type {
        case "image":
            let (object, thumb) = try buildImageObject(options: options)
            message.mediaObject = object
            message.thumbData = thumb
        case "link":
            message.mediaObject = try buildWebpageObject(options: options)
        case "music":
            message.mediaObject = try buildMusicObject(options: options)
        case "video":
            message.mediaObject = try buildVideoObject(options: options)
        case "miniprogram":
            let result = try buildMiniProgramObject(options: options)
            message.mediaObject = result.object
            if let thumb = result.thumb {
                message.thumbData = thumb
            }
        default:
            throw WechatError.invalidArguments("Unsupported share type \(type).")
        }

        if message.thumbData == nil, let thumb = options.thumbUrl {
            message.thumbData = try loadThumbnail(source: thumb)
        }

        return message
    }

    func buildImageObject(options: WechatShareOptions) throws -> (WXImageObject, Data?) {
        guard let source = options.imageUrl else {
            throw WechatError.invalidArguments("imageUrl is required for image shares.")
        }
        let data = try loadData(from: source)
        let imageObject = WXImageObject()
        imageObject.imageData = data
        return (imageObject, makeThumbnail(from: data))
    }

    func buildWebpageObject(options: WechatShareOptions) throws -> WXWebpageObject {
        guard let link = options.link else {
            throw WechatError.invalidArguments("link is required for link shares.")
        }
        let webpage = WXWebpageObject()
        webpage.webpageUrl = link
        return webpage
    }

    func buildMusicObject(options: WechatShareOptions) throws -> WXMusicObject {
        guard let url = options.mediaUrl else {
            throw WechatError.invalidArguments("mediaUrl is required for music shares.")
        }
        let music = WXMusicObject()
        music.musicUrl = url
        return music
    }

    func buildVideoObject(options: WechatShareOptions) throws -> WXVideoObject {
        guard let url = options.mediaUrl else {
            throw WechatError.invalidArguments("mediaUrl is required for video shares.")
        }
        let video = WXVideoObject()
        video.videoUrl = url
        return video
    }

    func buildMiniProgramObject(options: WechatShareOptions) throws -> (object: WXMiniProgramObject, thumb: Data?) {
        guard let username = options.miniProgramUsername else {
            throw WechatError.invalidArguments("miniProgramUsername is required for mini program shares.")
        }
        let mini = WXMiniProgramObject()
        mini.userName = username
        mini.path = options.miniProgramPath
        let miniTypeValue = UInt(options.miniProgramType ?? 0)
        mini.miniProgramType = WXMiniProgramType(rawValue: miniTypeValue) ?? .release
        mini.webpageUrl = options.miniProgramWebPageUrl ?? ""

        let thumbData: Data?
        if let imageSource = options.imageUrl {
            thumbData = try loadThumbnail(source: imageSource)
        } else {
            thumbData = nil
        }

        return (mini, thumbData)
    }

    func loadData(from source: String) throws -> Data {
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

    func loadThumbnail(source: String) throws -> Data? {
        let data = try loadData(from: source)
        return makeThumbnail(from: data)
    }

    func makeThumbnail(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        var compression: CGFloat = 0.8
        var result = image.jpegData(compressionQuality: compression)
        while let current = result, current.count > 128 * 1024, compression > 0.2 {
            compression -= 0.1
            result = image.jpegData(compressionQuality: compression)
        }
        return result
    }
}
