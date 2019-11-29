//
//  File.swift
//  
//
//  Created by Sergey Starukhin on 03/11/2019.
//

import UIKit
import ViewBlocking

@available(iOS 9.0, *)
open class ImageViewController: UIViewController {
    
    let mediaItem: MediaItem
    
    public var imageFetcher = ImageFetcher()
    
    var hostView: ImageScrollView? { view as? ImageScrollView }
    
    var request: URLRequest {
        if let fullScreenItem = mediaItem as? FullScreenMediaItem {
            return URLRequest(url: fullScreenItem.fullScreen)
        }
        return URLRequest(url: mediaItem.source)
    }

    required public init(_ item: MediaItem) {
        mediaItem = item
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func loadView() {
        view = ImageScrollView(frame: .zero)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        switch imageFetcher.start(fetching: request) {
        case .inProgress(let progress):
            imageFetcher.addFinishWork(request: request) { (result) in
                switch result {
                case .success(let image):
                    self.hostView?.zoomView = UIImageView(image: image)
                case .failure(let error):
                    if let image = self.imageFetcher.imageProvider.placeholder(for: error) {
                        self.hostView?.zoomView = UIImageView(image: image)
                    }
                    print(error)
                }
            }
            view.makeActivityIndicator(style: .whiteLarge).removeFromSuperviewAfterFinish(progress)
        case .done(let image):
            self.hostView?.zoomView = UIImageView(image: image)
        }
    }
}

final public class ImageScrollView: UIScrollView, UIScrollViewDelegate {
    
    public var zoomView: UIImageView? {
        willSet {
            zoomView?.removeFromSuperview()
            // reset our zoomScale to 1.0 before doing any further calculations
            zoomScale = 1.0
            
            if let view = newValue {
                addSubview(view)
            }
        }
        didSet {
            configureForImageSize(zoomView?.image?.size ?? .zero)
        }
    }
    
    var imageSize: CGSize = .zero
    
    var pointToCenterAfterResize: CGPoint = .zero
    var scaleToRestoreAfterResize: CGFloat = 0.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        bouncesZoom = true
        decelerationRate = .fast
        delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        guard let zoomView = zoomView else { return }
        // center the zoom view as it becomes smaller than the size of the screen
        let boundsSize = bounds.size
        var frameToCenter = zoomView.frame
        
        // center horizontally
        if (frameToCenter.size.width < boundsSize.width) {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
        } else {
            frameToCenter.origin.x = 0
        }
        // center vertically
        if (frameToCenter.size.height < boundsSize.height) {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
        } else {
            frameToCenter.origin.y = 0
        }
        zoomView.frame = frameToCenter
    }
    
    override public var frame: CGRect {
        get {
            super.frame
        }
        set {
            let sizeChanging = !newValue.size.equalTo(frame.size)
            if sizeChanging {
                prepareToResize()
            }
            super.frame = newValue
            if sizeChanging {
                recoverFromResizing()
            }
        }
    }
    
    // MARK: - UIScrollViewDelegate
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        zoomView
    }
    
    // MARK:- Configure scrollView to display new image
    
    /*func display(_ image: UIImage) {
        // clear the previous image
        zoomView?.removeFromSuperview()
        zoomView = nil
        
        // reset our zoomScale to 1.0 before doing any further calculations
        zoomScale = 1.0

        // make a new UIImageView for the new image
        let zoomView = UIImageView(image: image)
        addSubview(zoomView)
        self.zoomView = zoomView
        
        configureForImageSize(image.size)
    }*/

    func configureForImageSize(_ size: CGSize) {
        imageSize = size
        contentSize = size
        setMaxMinZoomScalesForCurrentBounds()
        zoomScale = minimumZoomScale
    }
    
    func setMaxMinZoomScalesForCurrentBounds() {
        let boundsSize = bounds.size
                    
        // calculate min/max zoomscale
        let xScale = boundsSize.width  / imageSize.width    // the scale needed to perfectly fit the image width-wise
        let yScale = boundsSize.height / imageSize.height   // the scale needed to perfectly fit the image height-wise
        
        // fill width if the image and phone are both portrait or both landscape; otherwise take smaller scale
        let imagePortrait = imageSize.height > imageSize.width
        let phonePortrait = boundsSize.height > boundsSize.width
        var minScale = imagePortrait == phonePortrait ? xScale : min(xScale, yScale)
        
        // on high resolution screens we have double the pixel density, so we will be seeing every pixel if we limit the
        // maximum zoom scale to 0.5.
        let maxScale = 1.0 / UIScreen.main.scale

        // don't let minScale exceed maxScale. (If the image is smaller than the screen, we don't want to force it to be zoomed.)
        if (minScale > maxScale) {
            minScale = maxScale
        }
        maximumZoomScale = maxScale
        minimumZoomScale = minScale
    }
    
    // MARK: - Methods called during rotation to preserve the zoomScale and the visible portion of the image
    
    func prepareToResize() {
        let boundsCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        
        pointToCenterAfterResize = convert(boundsCenter, to: zoomView)

        scaleToRestoreAfterResize = zoomScale
        
        // If we're at the minimum zoom scale, preserve that by returning 0, which will be converted to the minimum
        // allowable scale when the scale is restored.
        if (scaleToRestoreAfterResize <= minimumZoomScale + CGFloat(Float.ulpOfOne)) {
            scaleToRestoreAfterResize = 0
        }
    }
    
    func recoverFromResizing() {
        setMaxMinZoomScalesForCurrentBounds()
        
        // Step 1: restore zoom scale, first making sure it is within the allowable range.
        let maxZoomScale = max(minimumZoomScale, scaleToRestoreAfterResize)
        zoomScale = min(maximumZoomScale, maxZoomScale)
        
        // Step 2: restore center point, first making sure it is within the allowable range.
        
        // 2a: convert our desired center point back to our own coordinate space
        let boundsCenter = convert(pointToCenterAfterResize, from: zoomView)//[self convertPoint:_pointToCenterAfterResize fromView:_zoomView];

        // 2b: calculate the content offset that would yield that center point
        var offset = CGPoint(x: boundsCenter.x - bounds.size.width / 2.0, y: boundsCenter.y - bounds.size.height / 2.0)
        
        // 2c: restore offset, adjusted to be within the allowable range
        let maxOffset = maximumContentOffset
        let minOffset = minimumContentOffset
        
        var realMaxOffset = min(maxOffset.x, offset.x)
        offset.x = max(minOffset.x, realMaxOffset)
        
        realMaxOffset = min(maxOffset.y, offset.y)
        offset.y = max(minOffset.y, realMaxOffset)
        
        contentOffset = offset
    }
    
    var maximumContentOffset: CGPoint {
        let boundsSize = bounds.size
        return CGPoint(x: contentSize.width - boundsSize.width, y: contentSize.height - boundsSize.height)
    }
    
    var minimumContentOffset: CGPoint {
        .zero
    }
}
