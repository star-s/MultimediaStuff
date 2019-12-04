//
//  File.swift
//  
//
//  Created by Sergey Starukhin on 04/11/2019.
//

import Foundation
import UIKit

public protocol ImageProvider {
    func image(from cachedResponse: CachedURLResponse) -> UIImage?
    func image(from imageData: Data, response: URLResponse) -> UIImage?
    func placeholder(for error: Error) -> UIImage?
}

extension ImageProvider {
    
    public func image(from cachedResponse: CachedURLResponse) -> UIImage? {
        image(from: cachedResponse.data, response: cachedResponse.response)
    }
    
    public func placeholder(for error: Error) -> UIImage? {
        nil
    }
}

public struct DefaultImageProvider: ImageProvider {
    
    public init() {}
    
    public func image(from imageData: Data, response: URLResponse) -> UIImage? {
        if let image = UIImage(data: imageData) {
            return image
        }
        return nil
    }
}
