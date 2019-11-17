//
//  File.swift
//  
//
//  Created by Sergey Starukhin on 10/11/2019.
//

import Foundation
import UIKit

@available(iOS 9.0, *)
open class ItemsCollectionSectionHeader : UICollectionReusableView {
    
    @IBOutlet open var textLabel: UILabel?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .darkText
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 8.0),
            label.leftAnchor.constraint(equalTo: leftAnchor, constant: 8.0),
            label.rightAnchor.constraint(equalTo: rightAnchor, constant: 8.0),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 8.0)
        ])
        textLabel = label
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        //fatalError("init(coder:) has not been implemented")
    }
}
