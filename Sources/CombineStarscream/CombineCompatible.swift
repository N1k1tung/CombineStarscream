//
//  CombineCompatible.swift
//  
//
//  Created by Nikita Rodin on 20.02.23.
//

import Foundation

public struct CombineWrapper<Base> {
    public let base: Base
}

public protocol CombineCompatible {
    associatedtype Base

    var cb: CombineWrapper<Base> { get set }
}

extension CombineCompatible {

    public var cb: CombineWrapper<Self> {
        get { CombineWrapper(base: self) }
        set {}
    }

}

extension NSObject: CombineCompatible {}
