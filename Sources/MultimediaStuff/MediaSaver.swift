//
//  MediaSaver.swift
//
//  Created by Sergey Starukhin on 02/11/2019.
//

import Foundation
import UIKit
import AssetsLibrary
import Photos

@available(iOS 10.0, *)
public enum SaveTarget {
    case memory
    case file
    case photoLibrary
    
    var directory: URL { FileManager.default.temporaryDirectory.appendingPathComponent("photos", isDirectory: true) }
    var filename: String { UUID().uuidString }
}

@available(iOS 10.0, *)
public enum ImageVariant {
    case image(UIImage)
    case imageWithMetadata(UIImage, [CFString : Any])
    
    var cgImage: CGImage {
        switch self {
        case .image(let image), .imageWithMetadata(let image, _):
            if let cgImage = image.cgImage {
                return cgImage
            }
            fatalError("Wrong image format")
        }
    }
    
    var metadata: [CFString : Any] {
        switch self {
        case .imageWithMetadata(_, let metadata):
            return metadata
        default:
            return [:]
        }
    }
    
    var ciImage: CIImage { CIImage(cgImage: cgImage, options: [CIImageOption.properties: metadata]) }
    
    var representation: CIImage.Representation { .jpeg(1.0) }
    var imageData: Data { ciImage.data(representation) }
}

@available(iOS 10.0, *)
public extension ImageVariant {
    var orientation: ALAssetOrientation {
        switch self {
        case .image(let image), .imageWithMetadata(let image, _):
            return image.imageOrientation as! ALAssetOrientation
        }
    }
}

@available(iOS 10.0, *)
public protocol MediaSaver {
    func save(imageVariant: ImageVariant, target: SaveTarget, completion: @escaping Completion<MediaItem>) -> Progress
}

@available(iOS 10.0, *)
public extension MediaSaver {
    
    @discardableResult
    func save(imageVariant: ImageVariant, target: SaveTarget, completion: @escaping Completion<MediaItem>) -> Progress {
        let progress = Progress(totalUnitCount: 1)
        switch target {
        case .memory:
            DispatchQueue.global().async {
                let imageData = imageVariant.imageData
                let source = CGImageSourceCreateWithData(imageData as CFData, nil)!
                let options = [
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceThumbnailMaxPixelSize: 250
                ] as CFDictionary
                let imageReference = CGImageSourceCreateThumbnailAtIndex(source, 0, options)!
                let preview = UIImage(cgImage: imageReference).dataURL(.png)
                let url = imageData.urlRepresentation(imageVariant.representation.mimeType)
                let item = MediaFile(url, thumbnail: .url(preview))
                DispatchQueue.main.async {
                    progress.completedUnitCount = 1
                    if progress.isCancelled {
                        completion(.failure(CocoaError(.userCancelled)))
                    } else {
                        completion(.success(item))
                    }
                }
            }
        case .file:
            DispatchQueue.global().async {
                do {
                    let url = target.directory
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                    let file = url.appendingPathComponent(target.filename).appendingPathExtension(imageVariant.representation.pathExtension)
                    try imageVariant.imageData.write(to: file)
                    DispatchQueue.main.async {
                        progress.completedUnitCount = 1
                        if progress.isCancelled {
                            completion(.failure(CocoaError(.userCancelled)))
                        } else {
                            completion(.success(MediaFile(file)))
                        }
                    }
                } catch {
                    progress.completedUnitCount = 1
                    DispatchQueue.main.async { completion(.failure( progress.isCancelled ? CocoaError(.userCancelled) : error)) }
                }
            }
        case .photoLibrary:
            let completionBlock: ALAssetsLibraryWriteImageCompletionBlock = { (url, error) in
                progress.completedUnitCount = 1
                if progress.isCancelled {
                    completion(.failure(CocoaError(.userCancelled)))
                } else if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(PhotoLibraryItem.url(url)))
                } else {
                    fatalError("Unexpected result")
                }
            }
            let library = ALAssetsLibrary()
            switch imageVariant {
            case .image(_):
                library.writeImage(toSavedPhotosAlbum: imageVariant.cgImage, orientation: imageVariant.orientation, completionBlock: completionBlock)
            case .imageWithMetadata(_):
                library.writeImage(toSavedPhotosAlbum: imageVariant.cgImage, metadata: imageVariant.metadata, completionBlock: completionBlock)
            }
        }
        return progress
        /*PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { (success, error) in
            if success {
                self.handler(.success(nil))
            }
        }*/
    }
}