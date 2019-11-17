//
//  MediaItem.swift
//
//  Created by Sergey Starukhin on 03/11/2019.
//

import Foundation
import CoreServices

// MARK: - MediaItem

public protocol MediaItem {
    var source: URL { get }
    var uti: CFString { get }
    var thumbnail: URL { get }
}

public extension MediaItem {
    
    var uti: CFString {
        if let type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, source.pathExtension as CFString, nil) {
            return type.takeRetainedValue()
        }
        return kUTTypeContent
    }
    
    var thumbnail: URL { source }
}

public protocol FullScreenMediaItem: MediaItem {
    var fullScreen: URL { get }
}

// MARK: - Collection of multimedia items

public protocol MediaItemsCollection {
    var items: [MediaItem] { get }
    var title: String? { get }
}

extension MediaItemsCollection {
    var title: String? { nil }
}

// MARK: - Provider

public protocol MediaItemsProvider {
    func loadItems(completion: @escaping Completion<[MediaItemsCollection]>) -> Progress
}

// MARK: - Specific implementations

import Photos
import UIKit

@available(iOS 10.0, *)
public enum PhotoLibraryItem: FullScreenMediaItem {
    case url(URL)
    case asset(PHAsset)
    
    public var source: URL {
        switch self {
        case .url(let url):
            guard url.scheme == PhotoLibraryURLProtocol.scheme else { fatalError("Wrong url scheme: \(url.scheme ?? "") must be \(PhotoLibraryURLProtocol.scheme)://") }
            return url
        case .asset(let asset):
            return PhotoLibraryURLProtocol.makeUrlRepresentationAsset(asset.localIdentifier, mediaType: asset.mediaType)
        }
    }
    
    public var thumbnail: URL {
        var components = URLComponents(url: source, resolvingAgainstBaseURL: false)!
        components.fragment = PhotoLibraryURLProtocol.Fragment.thumbnail.rawValue
        return components.url!
    }
    
    public var fullScreen: URL {
        var components = URLComponents(url: source, resolvingAgainstBaseURL: false)!
        components.fragment = PhotoLibraryURLProtocol.Fragment.fullscreen.rawValue
        return components.url!
    }
}

@available(iOS 10.0, *)
public struct MediaFile: MediaItem {
    enum Preview {
        case none
        case url(URL)
        case image(UIImage)
        case data(Data, String)
    }
    
    public let source: URL
    let preview: Preview
    let typeId: CFString?
    
    init(_ file: URL, thumbnail: Preview = .none, uti: CFString? = nil) {
        source = file
        preview = thumbnail
        typeId = uti
    }
    
    public var uti: CFString {
        if let type = typeId {
            return type
        }
        return source.uti
    }
    
    public var thumbnail: URL {
        switch preview {
        case .url(let url):
            return url
        case .image(let image):
            return image.dataURL(.png)
        case .data(let imageData, let mimeType):
            return imageData.urlRepresentation(mimeType)
        default:
            return source
        }
    }
}

extension URL: MediaItem {
    public var source: URL { self }
}
