//
//  File.swift
//  
//
//  Created by Sergey Starukhin on 05/11/2019.
//

import Foundation
import UIKit

public protocol ImageLoader {
    
    var session: URLSession { get }
    
    var imageProvider: ImageProvider { get }
    
    func loadImageFromCache(_ request: URLRequest) -> UIImage?
    func loadImage(_ request: URLRequest, completion: @escaping Completion<UIImage>) -> Progress
}

public extension ImageLoader {
    
    var imageProvider: ImageProvider { DefaultImageProvider() }
    
    func loadImageFromCache(_ request: URLRequest) -> UIImage? {
        if let cachedResponse = session.configuration.urlCache?.cachedResponse(for: request) {
            return imageProvider.image(from: cachedResponse)
        }
        return nil
    }
    
    func loadImage(_ request: URLRequest, completion: @escaping Completion<UIImage>) -> Progress {
        let provider = self.imageProvider
        let progress = Progress(totalUnitCount: 1)
        let task = session.dataTask(with: request) { (data, response, error) in
            progress.completedUnitCount = 1
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else if let imageData = data, let response = response {
                    completion(.success(provider.image(from: imageData, response: response)))
                } else {
                    fatalError("Unexpected response")
                }
            }
        }
        task.resume()
        if #available(iOS 11.0, *) {
            return task.progress
        } else {
            progress.cancellationHandler = { [weak task] in
                task?.cancel()
            }
            return progress
        }
    }
}

public class ImageFetcher: ImageLoader {
    
    public enum Status {
        case inProgress(Progress)
        case done(UIImage)
    }

    class Task {
        var progress: Progress
        var completionBlocks: [Completion<UIImage>] = []

        init(_ loadProgress: Progress) { progress = loadProgress }
    }
    
    public let session: URLSession

    var tasks: [URLRequest:Task] = [:]
    
    public var imageProvider: ImageProvider = DefaultImageProvider()

    public init(_ provider: ImageProvider? = nil, _ urlSession: URLSession = .shared) {
        if let provider = provider {
            imageProvider = provider
        }
        session = urlSession
    }
    
    @discardableResult
    public func start(fetching request: URLRequest) -> Status {
        switch request.cachePolicy {
        case .returnCacheDataElseLoad, .useProtocolCachePolicy:
            if let image = loadImageFromCache(request) {
                return .done(image)
            }
        case .returnCacheDataDontLoad:
            if let image = loadImageFromCache(request) {
                return .done(image)
            }
            fatalError("No image in cache")
        default:
            break
        }
        if let task = tasks[request] {
            return .inProgress(task.progress)
        }
        let progress = loadImage(request) { [weak self] (result) in
            self?.tasks.removeValue(forKey: request)?.completionBlocks.forEach({ $0(result) })
        }
        tasks[request] = Task(progress)
        return .inProgress(progress)
    }
    
    public func cancel(fetching request: URLRequest) {
        tasks.removeValue(forKey: request)?.progress.cancel()
    }
    
    public func addFinishWork(request: URLRequest, work: @escaping Completion<UIImage>) {
        if let task = tasks[request] {
            task.completionBlocks.append(work)
        }
    }
}
