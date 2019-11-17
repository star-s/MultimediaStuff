//
//  File.swift
//  
//
//  Created by Sergey Starukhin on 04/11/2019.
//

import Foundation
import UIKit

@available(iOS 10.0, *)
public protocol SelectMediaItemsControllerDelegate : NSObjectProtocol {
    func selectMediaItemsController(_ controller: SelectMediaItemsController, didFinishSelectItems items: [Any])
    func selectMediaItemsControllerDidCancel(_ controller: SelectMediaItemsController)
}

@available(iOS 9.0, *)
open class SelectImageViewCollectionCell: ImageViewCollectionCell {
    
    @IBOutlet open weak var overlayImageView: UIImageView?
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        overlayImageView?.isHidden = true
    }
    
    override open func prepareForReuse() {
        super.prepareForReuse()
        overlayImageView?.isHidden = true
    }
    
    override open var isSelected: Bool {
        willSet { overlayImageView?.isHidden = !newValue }
    }
}

@available(iOS 10.0, *)
final public class SelectMediaItemsController: UINavigationController, UICollectionViewDelegateFlowLayout {
    
    public weak var selectDelegate: SelectMediaItemsControllerDelegate?

    var maximumSelectedItemsCount: Int?

    @IBInspectable public var registerDefaultClasses: Bool = true
    
    static public func makeViewController(selected:[MediaItem]? = nil, maxCount: Int? = nil, provider: MediaItemsProvider? = nil) -> SelectMediaItemsController {
        let layout = ColumnCollectionViewLayout()
        layout.columnCount = 3
        layout.squareItems = true
        let collectionVC = UpdatebleItemsCollection(collectionViewLayout: layout)
        if let provider = provider {
            collectionVC.provider = provider
        }
        collectionVC.selectedItems = selected
        let result = SelectMediaItemsController(rootViewController: collectionVC)
        result.maximumSelectedItemsCount = maxCount
        return result
    }
    
    static public func selectItemsControllerFromNib(boardName: String, vcID: String ,selected:[MediaItem]? = nil, maxCount: Int? = nil, provider: MediaItemsProvider? = nil) -> SelectMediaItemsController {
        let board = UIStoryboard(name: boardName, bundle: nil)
        if let vc = board.instantiateViewController(withIdentifier: vcID) as? SelectMediaItemsController {
            vc.maximumSelectedItemsCount = maxCount
            guard let collectionVC = vc.topViewController as? UpdatebleItemsCollection else { fatalError() }
            if let provider = provider {
                collectionVC.provider = provider
            }
            collectionVC.selectedItems = selected
            return vc
        }
        fatalError()
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        if let collectionVC = topViewController as? UpdatebleItemsCollection, let collectionView = collectionVC.collectionView {
            if registerDefaultClasses {
                collectionView.register(SelectImageViewCollectionCell.self,
                                        forCellWithReuseIdentifier: ItemsCollectionViewController.reuseIdentifier)
                
                collectionView.register(ItemsCollectionSectionHeader.self,
                                        forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                        withReuseIdentifier: ItemsCollectionViewController.headerIdentifier)
            }
            collectionView.delegate = self
            collectionView.prefetchDataSource = collectionVC
            collectionView.refreshControl = UIRefreshControl()
            collectionView.refreshControl?.addTarget(collectionVC, action: #selector(UpdatebleItemsCollection.refreshSections(_:)), for: .valueChanged)
            collectionView.allowsMultipleSelection = true
            collectionVC.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneSelect(_:)))
            collectionVC.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelSelect(_:)))
        }
    }
    
    // MARK: - UICollectionViewDelegate
    
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if let maximum = maximumSelectedItemsCount, let selected = collectionView.indexPathsForSelectedItems {
            return selected.count < maximum
        }
        return true
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let collectionVC = topViewController as? ItemsCollectionViewController else { return .zero }
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }
        return collectionVC.sections?[section].title == nil ? .zero : layout.headerReferenceSize
    }

    // MARK: -
    
    @IBAction func doneSelect(_ sender: Any) {
        if let itemsCollection = topViewController as? ItemsCollectionViewController, let sections = itemsCollection.sections {
            let selectedItems = itemsCollection.collectionView.indexPathsForSelectedItems?.sorted().compactMap({ sections[$0.section].items[$0.item] }) ?? []
            selectDelegate?.selectMediaItemsController(self, didFinishSelectItems: selectedItems)
        }
    }
    
    @IBAction func cancelSelect(_ sender: Any) {
        selectDelegate?.selectMediaItemsControllerDidCancel(self)
    }
}
