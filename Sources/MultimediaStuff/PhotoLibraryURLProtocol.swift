//
//  PhotoLibraryURLProtocol.swift
//
//  Created by Sergey Starukhin on 03/11/2019.
//

import Foundation
import Photos
import CoreServices
import UIKit

@available(iOS 10.0, *)
public final class PhotoLibraryURLProtocol: URLProtocol, URLProtocolTools {
    
    enum ResultType {
        case fullResolutionImage
        case fullScreenImage
        case thumbnail
    }
    
    enum Fragment: String {
        case thumbnail
        case fullscreen
        
        init?(_ fragment: String? = nil) {
            guard let fragment = fragment else { return nil }
            self.init(rawValue: fragment)
        }
    }
    
    enum Parameter: String {
        case id
        case ext
        
        func get(from url: URL) -> URLQueryItem? {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                return components.queryItems?.first(where: { $0.name == self.rawValue })
            }
            return nil
        }
    }
    
    static public let scheme = "assets-library"
    
    var requestId: PHImageRequestID? = nil
    
    var clientThread: Thread = .current
    var isNotCancelled: Bool = true
    
    override public class func canInit(with request: URLRequest) -> Bool {
        guard let scheme = request.url?.scheme else { return false }
        return scheme == PhotoLibraryURLProtocol.scheme
    }
    
    override public class func canInit(with task: URLSessionTask) -> Bool {
        guard let scheme = task.currentRequest?.url?.scheme else { return false }
        return scheme == PhotoLibraryURLProtocol.scheme
    }
    
    var resultType: ResultType {
        guard let url = request.url, let fragment = Fragment(url.fragment) else { return .fullResolutionImage }
        switch fragment {
        case .thumbnail:
            return .thumbnail
        case .fullscreen:
            return .fullScreenImage
        }
    }
    
    var resultSize: CGSize {
        switch resultType {
        case .thumbnail:
            let scale = UIScreen.main.scale
            return CGSize(width: 75 * scale, height: 75 * scale)
        case .fullScreenImage:
            return UIScreen.main.bounds.size
        default:
            return .zero
        }
    }
    
    var assetLocalId: String {
        guard let url = request.url else { fatalError() }
        if let id = Parameter.id.get(from: url)?.value {
            return id
        }
        fatalError("Wrong url")
    }
    
    var manager: PHImageManager { PHImageManager.default() }
    
    lazy var options: PHImageRequestOptions = {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        return options
    }()
    
    var representation: UIImage.Representation = .png
    
    override public func startLoading() {
        clientThread = .current
        if let cached = cachedResponse {
            //print(cached)
        }
        DispatchQueue.global().async {
            if let asset = PHAsset.fetchAssets(withLocalIdentifiers: [self.assetLocalId], options: nil).firstObject {
                switch self.resultType {
                case .thumbnail, .fullScreenImage:
                    self.requestId = self.manager.requestImage(for: asset, targetSize: self.resultSize, contentMode: .aspectFill, options: self.options, resultHandler: { (image, info) in
                        self.handle(image: image, info: info)
                    })
                default:
                    self.requestId = self.manager.requestImageData(for: asset, options: self.options, resultHandler: { (data, uti, orientation, info) in
                        self.handle(imageData: data, dataUTI: uti, orientation: orientation, info: info)
                    })
                }
            } else {
                self.didFinishLoading(error: URLError(.resourceUnavailable))
            }
        }
    }
    
    override public func stopLoading() {
        isNotCancelled = false
        if let requestId = requestId {
            manager.cancelImageRequest(requestId)
        }
    }
    
    func handle(image: UIImage?, info:[AnyHashable: Any]?) {
        guard let info = info as? [String : Any] else { fatalError() }
        if let isRequestCancelled = info[PHImageCancelledKey] as? Bool, isRequestCancelled {
            return
        }
        if let image = image {
            didLoad(data: image.data(representation), mimeType: representation.mimeType, cachePolicy: .allowedInMemoryOnly)
        } else {
            if let error = info[PHImageErrorKey] as? Error {
                didFinishLoading(error: error)
            } else {
                didFinishLoading(error: URLError(.resourceUnavailable))
            }
        }
    }
    
    func handle(imageData: Data?, dataUTI: String?, orientation: UIImage.Orientation, info: [AnyHashable: Any]?) {
        guard let info = info as? [String : Any] else { fatalError() }
        if let isRequestCancelled = info[PHImageCancelledKey] as? Bool, isRequestCancelled {
            return
        }
        if let imageData = imageData, let uti = dataUTI {
            guard let mimeType = UTTypeCopyPreferredTagWithClass(uti as CFString, kUTTagClassMIMEType) else { fatalError("Wrong UTI: \(uti)") }
            didLoad(data: imageData, mimeType: mimeType.takeRetainedValue() as String, cachePolicy: .allowed)
        } else {
            if let error = info[PHImageErrorKey] as? Error {
                didFinishLoading(error: error)
            } else {
                didFinishLoading(error: URLError(.resourceUnavailable))
            }
        }
    }
}

@available(iOS 10.0, *)
extension PhotoLibraryURLProtocol {
    
    static public func makeUrlRepresentationAsset(_ localIdentifier: String, mediaType: PHAssetMediaType) -> URL {
        
        guard let uuid = UUID(uuidString: String(localIdentifier.prefix(36))) else { fatalError("Wrong identifier: \(localIdentifier)") }
        var queryItems = [ URLQueryItem(name: Parameter.id.rawValue, value: uuid.uuidString) ]
        
        var components = URLComponents()
        components.scheme = self.scheme
        components.host = "asset"
        switch mediaType {
        case .image:
            components.path = "/asset.JPG"
            queryItems.append(URLQueryItem(name: Parameter.ext.rawValue, value: "JPG"))
        case .video:
            components.path = "/asset.MOV"
            queryItems.append(URLQueryItem(name: Parameter.ext.rawValue, value: "MOV"))
        default:
            fatalError("Unsupported media type")
        }
        components.queryItems = queryItems
        if let url = components.url {
            return url
        }
        fatalError("Wrong url components: \(components)")
    }
}
