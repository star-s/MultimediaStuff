//
//  ThunbnailGenerator.swift
//
//  Created by Sergey Starukhin on 02/11/2019.
//

import Foundation
import UIKit

public protocol ThunbnailGenerator {
    func makeImageSource() -> CGImageSource
    func getThumbnail(maxSize: Int) -> UIImage?
}

public extension ThunbnailGenerator {
    
    func getThumbnail(maxSize: Int = 250) -> UIImage? {
        let options = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxSize
        ] as CFDictionary
        guard let imageReference = CGImageSourceCreateThumbnailAtIndex(makeImageSource(), 0, options) else { return nil }
        return UIImage(cgImage: imageReference)
    }
}
