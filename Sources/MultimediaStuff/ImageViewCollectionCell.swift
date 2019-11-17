//
//  File.swift
//  
//
//  Created by Sergey Starukhin on 04/11/2019.
//

import Foundation
import UIKit

@available(iOS 9.0, *)
open class ImageViewCollectionCell: UICollectionViewCell {
    
    open weak var imageLoadProgress: Progress?
    
    @IBOutlet open var imageView: UIImageView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let imageView = UIImageView(frame: contentView.bounds)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            imageView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        self.imageView = imageView
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        //fatalError("init(coder:) has not been implemented")
    }
    
    override open func prepareForReuse() {
        super.prepareForReuse()
        imageLoadProgress?.cancel()
        imageLoadProgress = nil
        imageView?.image = nil
    }
}
