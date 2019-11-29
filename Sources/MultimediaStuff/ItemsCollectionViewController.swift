//
//  File.swift
//  
//
//  Created by Sergey Starukhin on 04/11/2019.
//

import Foundation
import UIKit
import ViewBlocking

public struct MediaItemsSection: MediaItemsCollection {
    public var items: [MediaItem]
    public var title: String?
    
    public init(_ items: [MediaItem] = [], title: String? = nil) {
        self.items = items
        self.title = title
    }
}

@available(iOS 9.0, *)
open class ItemsCollectionViewController: UICollectionViewController, UICollectionViewDataSourcePrefetching {
    
    open var sections: [MediaItemsCollection]?
    
    open var imageFetcher = ImageFetcher()

    public static let reuseIdentifier = "ItemsCollectionCell"
    public static let headerIdentifier = "ItemsCollectionHeader"

    // MARK: - UICollectionViewDataSourcePrefetching
    
    open func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        indexPaths.compactMap({ request(at: $0) }).forEach({ imageFetcher.start(fetching: $0) })
    }
    
    open func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        indexPaths.compactMap({ request(at: $0) }).forEach({ imageFetcher.cancel(fetching: $0) })
    }

    // MARK: - UICollectionViewDataSource

    override open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections?.count ?? 0
    }

    override open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections?[section].items.count ?? 0
    }
    
    override open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = ItemsCollectionViewController.reuseIdentifier
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? ImageViewCollectionCell else {
            fatalError("Wrong cell")
        }
        guard let request = request(at: indexPath) else { fatalError("Request must not be nil") }
        switch imageFetcher.start(fetching: request) {
        case .inProgress(let progress):
            imageFetcher.addFinishWork(request: request) { [weak cell] (result) in
                switch result {
                case .success(let image):
                    cell?.imageView?.image = image
                case .failure(let error):
                    if let image = self.imageFetcher.imageProvider.placeholder(for: error) {
                        cell?.imageView?.image = image
                    }
                    //cell?.presentError(error)
                    print(error)
                }
            }
            cell.imageLoadProgress = progress
        case .done(let image):
            cell.imageView?.image = image
        }
        return cell
    }

    override open func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            fatalError("Wrong kind of supplementary element - \(kind)")
        }
        let identifier = ItemsCollectionViewController.headerIdentifier
        if let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: identifier, for: indexPath) as? ItemsCollectionSectionHeader {
            header.textLabel?.text = sections?[indexPath.section].title
            return header
        }
        fatalError()
    }

    // MARK: - UICollectionViewDelegate
    
    // MARK: -
    
    public func request(at indexPath: IndexPath) -> URLRequest? {
        guard let sections = sections else { return nil }
        return URLRequest(url: sections[indexPath.section].items[indexPath.item].thumbnail)
    }
    
    public func indexPath(for item: MediaItem) -> IndexPath? {
        guard let sections = sections else { return nil }
        for section in sections.enumerated() {
            if let index = section.element.items.firstIndex(where: { $0.source == item.source }) {
                return IndexPath(item: index, section: section.offset)
            }
        }
        return nil
    }
}

@available(iOS 10.0, *)
open class UpdatebleItemsCollection: ItemsCollectionViewController {
    
    public var provider: MediaItemsProvider = PhotoLibraryProvider()
    
    var selectedItems: [MediaItem]?
    
    weak var loadProgress: Progress?
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if sections == nil {
            collectionView.refreshControl?.sendActions(for: .valueChanged)
        } else {
            restoreSelections()
        }
    }
    
    @IBAction func refreshSections(_ sender: UIRefreshControl) {
        loadProgress?.cancel()
        if selectedItems == nil {
            selectedItems = collectionView.indexPathsForSelectedItems?.compactMap({ sections?[$0.section].items[$0.item] })
        }
        let progress = provider.loadItems { (result) in
            switch result {
            case .success(let sections):
                self.sections = sections
                self.collectionView.reloadData()
                self.restoreSelections()
            case .failure(let error):
                print(error)
            }
        }
        if sender.isRefreshing {
            sender.endRefreshingAfterFinish(progress)
        } else {
            view.makeActivityIndicator(style: .gray).removeFromSuperviewAfterFinish(progress)
        }
        loadProgress = progress
    }
    
    func restoreSelections(animated: Bool = false) {
        guard let selected = selectedItems else { return }
        selected.compactMap({ indexPath(for: $0) }).forEach { collectionView.selectItem(at: $0, animated: animated, scrollPosition: []) }
        selectedItems = nil
    }
}
