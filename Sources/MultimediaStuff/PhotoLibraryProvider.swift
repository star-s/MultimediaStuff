//
//  File.swift
//  
//
//  Created by Sergey Starukhin on 04/11/2019.
//

import Foundation
import Photos

@available(iOS 10.0, *)
public struct PhotoLibraryProvider: MediaItemsProvider {
    
    var momentsOptions: PHFetchOptions?
    var assetOptions: PHFetchOptions?
    
    public init() {}
    
    public func loadItems(completion: @escaping Completion<[MediaItemsCollection]>) -> Progress {
        let progress = Progress()
        DispatchQueue.global().async {
            var sections: [MediaItemsSection] = []
            let result = PHAssetCollection.fetchMoments(with: self.momentsOptions)
            progress.totalUnitCount = Int64(result.count)
            result.enumerateObjects { (collection, idx, _) in
                var items: [MediaItem] = []
                let assets = PHAsset.fetchAssets(in: collection, options: self.assetOptions)
                assets.enumerateObjects { (asset, _, _) in
                    items.append(PhotoLibraryItem.asset(asset))
                }
                var section = MediaItemsSection()
                section.title = collection.localizedTitle
                section.items = items
                sections.insert(section, at: 0)//append(section)
                progress.completedUnitCount = Int64(idx + 1)
            }
            DispatchQueue.main.async {
                if progress.isCancelled {
                    completion(.failure(CocoaError(.userCancelled)))
                } else {
                    completion(.success(sections))
                }
            }
        }
        return progress
    }
}
