//
//  DataUrlRepresentable.swift
//
//  Created by Sergey Starukhin on 02/11/2019.
//

import Foundation
import CoreServices

@available(iOS 10.0, *)
public protocol RepresentationFormat {
    var uti: CFString { get }
}

@available(iOS 10.0, *)
public extension RepresentationFormat {
    
    var mimeType: String {
        if let mimeType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType) {
            return mimeType.takeRetainedValue() as String
        }
        fatalError()
    }
    
    var pathExtension: String {
        if let ext = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassFilenameExtension) {
            return ext.takeRetainedValue() as String
        }
        fatalError()
    }
    
    //func dataURL(data: Data) -> URL { data.urlRepresentation(mimeType) }
}

@available(iOS 10.0, *)
public protocol DataUrlRepresentable {
    associatedtype Representation: RepresentationFormat
    func dataURL(_ rep: Representation) -> URL
    func data(_ rep: Representation) -> Data
}

@available(iOS 10.0, *)
public extension DataUrlRepresentable {
    func dataURL(_ rep: Representation) -> URL { data(rep).urlRepresentation(rep.mimeType) }
}

public extension Data {
    
    func urlRepresentation(_ mimeType: String) -> URL {
        if let url = URL(string: "data:\(mimeType);base64,\(base64EncodedString())") {
            return url
        }
        fatalError()
    }
}
