//
//  File.swift
//  
//
//  Created by Sergey Starukhin on 05/11/2019.
//

import Foundation
import UIKit

open class ColumnCollectionViewLayout: UICollectionViewFlowLayout {
    
    @IBInspectable open var columnCount: Int = 0
    @IBInspectable open var squareItems: Bool = false
    
    open override func prepare() {
        if let collectionView = collectionView, columnCount > 0 {
            let sectionBounds = collectionView.bounds.inset(by: sectionInset)
            var columnWidth: CGFloat = (sectionBounds.width - (CGFloat(columnCount - 1) * minimumInteritemSpacing)) / CGFloat(columnCount)
            columnWidth = CGFloat(truncf(Float(columnWidth)))
            if squareItems {
                itemSize = CGSize(width: columnWidth, height: columnWidth)
            } else {
                itemSize = CGSize(width: columnWidth, height: itemSize.height)
            }
        }
        super.prepare()
    }
}
