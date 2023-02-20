//
//  DelegateProxy.swift
//  
//
//  Created by Nikita Rodin on 20.02.23.
//

import Foundation
import ObjectiveC.runtime

class DelegateProxy: NSObject {
    static var associatedKey = "delegateProxy"

    public required override init() {
        super.init()
    }

    static func delegateProxy(for object: AnyObject) -> Self {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        let delegateProxy: Self

        if let associatedObject = objc_getAssociatedObject(object, &associatedKey) as? Self {
            delegateProxy = associatedObject
        } else {
            delegateProxy = .init()
            objc_setAssociatedObject(object, &associatedKey, delegateProxy, .OBJC_ASSOCIATION_RETAIN)
        }

        return delegateProxy
    }
}
