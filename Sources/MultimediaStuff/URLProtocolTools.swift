//
//  File.swift
//  
//
//  Created by Sergey Starukhin on 14/11/2019.
//

import Foundation

final class ThreadWorkItem: NSObject {
    
    let work: ()->Void
    let wait: Bool
    
    init(_ block: @escaping @convention(block) () -> Void, waitUntilDone: Bool) {
        work = block
        wait = waitUntilDone
        super.init()
    }
}

extension Thread {
    
    @objc
    func runWorkItem(_ item: ThreadWorkItem) {
        if Thread.current == self {
            item.work()
        } else {
            perform(#selector(runWorkItem(_:)), on: self, with: item, waitUntilDone: item.wait)
        }
    }
}

public extension Thread {
    
    func async(execute work: @escaping @convention(block) () -> Void) {
        runWorkItem(ThreadWorkItem(work, waitUntilDone: false))
    }

    func sync(execute work: @escaping @convention(block) () -> Void) {
        runWorkItem(ThreadWorkItem(work, waitUntilDone: true))
    }
}

protocol URLProtocolTools {
    
    var clientThread: Thread { get }
    var isNotCancelled: Bool { get }
}

extension URLProtocolTools where Self: URLProtocol {
    
    func didLoad(data: Data, mimeType: String, cachePolicy: URLCache.StoragePolicy) {
        guard let url = request.url else { fatalError() }
        didReceive(response: URLResponse(url: url, mimeType: mimeType, expectedContentLength: data.count, textEncodingName: nil), cachePolicy: cachePolicy)
        didLoad(data: data)
        didFinishLoading(error: nil)
    }
    
    func didReceive(response: URLResponse, cachePolicy: URLCache.StoragePolicy) {
        guard isNotCancelled else { return }
        clientThread.sync {
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: cachePolicy)
        }
    }

    func didLoad(data: Data) {
        guard isNotCancelled else { return }
        clientThread.sync {
            self.client?.urlProtocol(self, didLoad: data)
        }
    }
    
    func didFinishLoading(error: Error?) {
        guard isNotCancelled else { return }
        clientThread.sync {
            if let error = error {
                self.client?.urlProtocol(self, didFailWithError: error)
            } else {
                self.client?.urlProtocolDidFinishLoading(self)
            }
        }
    }
}
