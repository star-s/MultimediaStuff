import Foundation
import CoreServices

public typealias Completion<T> = (Result<T, Error>)->Void

public extension URL {
    
    func deletingFragment() -> URL {
        guard fragment != nil else { return self }
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return self }
        components.fragment = nil
        guard let url = components.url else { return self }
        return url
    }
}

import CoreServices
import CoreImage

@available(iOS 10.0, *)
extension CIImage: DataUrlRepresentable {
    
    public enum Representation: RepresentationFormat {
        case jpeg(CGFloat)
        
        public var uti: CFString {
            switch self {
            case .jpeg(_):
                return kUTTypeJPEG
            }
        }
    }
    
    public func data(_ rep: Representation) -> Data {
        guard let colorSpace = colorSpace else { fatalError("Color space must not be nil") }
        switch rep {
        case .jpeg(let quality):
            let options = [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: quality]
            if let data = CIContext().jpegRepresentation(of: self, colorSpace: colorSpace, options: options) {
                return data
            }
        }
        fatalError("Wrong image: \(self)")
    }
}

import UIKit

@available(iOS 9.0, *)
extension UIView {
    
    func makeActivityIndicator(style: UIActivityIndicatorView.Style) -> UIActivityIndicatorView {
        let activityView = UIActivityIndicatorView(style: style)
        activityView.translatesAutoresizingMaskIntoConstraints = false
        activityView.center = CGPoint(x: bounds.midX, y: bounds.midY)
        addSubview(activityView)
        NSLayoutConstraint.activate([
            activityView.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        activityView.startAnimating()
        return activityView
    }
}

extension UIImage: DataUrlRepresentable, ThunbnailGenerator {

    public enum Representation: RepresentationFormat {
        case png
        case jpeg(CGFloat)
        
        public var uti: CFString {
            switch self {
            case .png:
                return kUTTypePNG
            case .jpeg(_):
                return kUTTypeJPEG
            }
        }
    }
    
    public func data(_ rep: Representation = .png) -> Data {
        switch rep {
        case .png:
            if let data = pngData() {
                return data
            }
        case .jpeg(let quality):
            if let data = jpegData(compressionQuality: quality) {
                return data
            }
        }
        fatalError("Wrong image: \(self)")
    }
    
    public func makeImageSource() -> CGImageSource {
        if let source = CGImageSourceCreateWithData(data() as CFData, nil) {
            return source
        }
        fatalError()
    }
    /*
    func getThumbnail(maxSize: Int = 250) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data() as CFData, nil) else { return nil }
        let options = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxSize
        ] as CFDictionary
        guard let imageReference = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
        return UIImage(cgImage: imageReference)
    }*/
}
/*
import Photos

public extension PHAsset {
    
    enum UrlParameter: String {
        case id
        case ext
    }

    var path: String {
        switch mediaType {
        case .image:
            return "/asset.JPG"
        case .video:
            return "/asset.MOV"
        default:
            fatalError("Unsupported media type")
        }
    }
    
    var host: String {
        "asset"
    }
    
    var uuid: UUID {
        if let id = UUID.init(uuidString: String(localIdentifier.prefix(36))) {
            return id
        }
        fatalError()
    }
    
    var urlRepresentation: URL {
        var components = URLComponents()
        components.scheme = PhotoLibraryURLProtocol.scheme
        components.host = host
        components.path = path
        components.queryItems = [
            URLQueryItem(name: UrlParameter.id.rawValue, value: uuid.uuidString),
            URLQueryItem(name: UrlParameter.ext.rawValue, value: (path as NSString).pathExtension)
        ]
        if let url = components.url {
            return url
        }
        fatalError("Wrong url components: \(components)")
    }
}
*/
