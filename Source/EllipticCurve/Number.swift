//
//  Number.swift
//  SwiftCrypto
//
//  Created by Alexander Cyon on 2018-07-06.
//  Copyright © 2018 Alexander Cyon. All rights reserved.
//

import Foundation
import BigInt

public typealias Number = BigInt

public extension Number {

    public init(sign: Number.Sign = .plus, _ words: [Number.Word]) {
        let magnitude = Number.Magnitude(words: words)
        self.init(sign: sign, magnitude: magnitude)
    }

    public init(sign: Number.Sign = .plus, data: Data) {
        let magnitude = Number.Magnitude(data)
        self.init(sign: sign, magnitude: magnitude)
    }

    public init?(hexString: String) {
        var hexString = hexString
        if hexString.starts(with: "0x") {
            hexString = String(hexString.dropFirst(2))
        }
        self.init(hexString, radix: 16)
    }

    public init?(decimalString: String) {
        self.init(decimalString, radix: 10)
    }

    var isEven: Bool {
        guard self.sign == .plus else { fatalError("what to do when negative?") }
        return magnitude[bitAt: 0] == false
    }

    func asHexString(uppercased: Bool = true) -> String {
        return toString(uppercased: uppercased, radix: 16)
    }

    func asDecimalString(uppercased: Bool = true) -> String {
        return toString(uppercased: uppercased, radix: 10)
    }

    func toString(uppercased: Bool = true, radix: Int) -> String {
        let stringRepresentation = String(self, radix: radix)
        guard uppercased else { return stringRepresentation }
        return stringRepresentation.uppercased()
    }

    func asHexStringLength64(uppercased: Bool = true) -> String {
        var hexString = toString(uppercased: uppercased, radix: 16)
        while hexString.count < 64 {
            hexString = "0\(hexString)"
        }
        return hexString
    }

    func asData() -> Data {
        return Data(hex: asHexStringLength64())
    }
}

extension Data {
    func toNumber() -> Number {
        return Number(data: self)
    }
}
