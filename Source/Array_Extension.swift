//
//  Array_Extension.swift
//  SwiftCrypto
//
//  Created by Alexander Cyon on 2018-06-05.
//  Copyright © 2018 Alexander Cyon. All rights reserved.
//

import Foundation

extension Array where Element == Bool {
    var and: Bool {
        return !contains(false)
    }
}
