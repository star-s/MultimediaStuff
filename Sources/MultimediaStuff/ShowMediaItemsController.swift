//
//  File.swift
//  
//
//  Created by Sergey Starukhin on 03/11/2019.
//

import UIKit
import CoreServices
import AVKit

public protocol MediaItemPageProvider {
    func viewComtroller(for item: MediaItem) -> UIViewController
}

@available(iOS 9.0, *)
public struct DefaultMediaItemPageProvider: MediaItemPageProvider {
    
    public func viewComtroller(for item: MediaItem) -> UIViewController {
        if UTTypeConformsTo(item.uti, kUTTypeImage) {
            return ImageViewController(item)
        } else if UTTypeConformsTo(item.uti, kUTTypeAudiovisualContent) {
            let playerVC = AVPlayerViewController() // FIXME: need custom subclass?
            playerVC.player = AVPlayer(url: item.source)
            //playerVC.player?.play()
            return playerVC
        }
        fatalError("Unsupported media type")
    }
}

@available(iOS 9.0, *)
final public class ShowMediaItemsController: UINavigationController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    var items: [MediaItem] = []
    var startIndex = 0

    var pageProvider: MediaItemPageProvider = DefaultMediaItemPageProvider()
    
    static public func makeViewController(items:[MediaItem], startIndex: Int? = nil, provider: MediaItemPageProvider? = nil) -> ShowMediaItemsController {
        guard !items.isEmpty else {
            fatalError("Items must not be empty")
        }
        let pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [UIPageViewController.OptionsKey.interPageSpacing: 12])
        let result = ShowMediaItemsController(rootViewController: pageVC)
        if let provider = provider {
            result.pageProvider = provider
        }
        result.items = items
        if let index = startIndex {
            result.startIndex = index
        }
        return result
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let pageVC = topViewController as? UIPageViewController, pageVC.viewControllers?.isEmpty ?? true {
            pageVC.delegate = self
            pageVC.dataSource = self
            pageVC.view.backgroundColor = .black
            let vc = makeViewController(for: startIndex)
            pageVC.setViewControllers([vc], direction: .forward, animated: animated) { (finished) in
                pageVC.navigationItem.title = vc.title
            }
            if pageVC.navigationItem.rightBarButtonItem == nil {
                pageVC.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close(_:)))
            }
        }
    }
    
    func makeViewController(for index: Int) -> UIViewController {
        let vc = pageProvider.viewComtroller(for: items[index])
        if vc.title == nil {
            vc.title = "\(index + 1) из \(items.count)"
        }
        vc.itemIndex = index
        return vc
    }
    
    @IBAction func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UIPageViewControllerDataSource
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let index = viewController.itemIndex
        guard index > 0 else { return nil }
        return makeViewController(for: index - 1)
    }

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let index = viewController.itemIndex
        guard index < items.count - 1 else { return nil }
        return makeViewController(for: index + 1)
    }
    
    // MARK: - UIPageViewControllerDelegate
    
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if finished {
            pageViewController.navigationItem.title = pageViewController.viewControllers?.first?.title
        }
    }
}

import ObjectiveC

private var AssociatedObjectHandle: Void?

private extension UIViewController {
    
    var itemIndex: Int {
        get { objc_getAssociatedObject(self, &AssociatedObjectHandle) as? Int ?? 0 }
        set { objc_setAssociatedObject(self, &AssociatedObjectHandle, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}
