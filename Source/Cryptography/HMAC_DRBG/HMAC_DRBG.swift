//
//  HMAC_DRBG.swift
//  EllipticCurveKit
//
//  Created by Alexander Cyon on 2018-09-17.
//  Copyright © 2018 Alexander Cyon. All rights reserved.
//

import Foundation


/// HMAC_DRBG is a Deterministic Random Bit Generator (DRBG) using HMAC as hash function.
public final class HMAC_DRBG {

    /// Typically sha256
    private let hasher: UpdatableHasher

    private var K: DataConvertible
    private var V: DataConvertible
    private let minimumEntropyByteCount: Int
    private var iterationsLeftUntilReseed: Number

    /// 2^48, which is NIST's recommended value
    private static let reseedInterval: Number = 0x1000000000000
    private var hashType: HashType {
        return hasher.type
    }

    public init(
        hasher: UpdatableHasher = UpdatableHashProvider.hasher(variant: .sha2sha256),
        entropy: Data,
        nonce: Data,
        personalization: Data? = nil,
        additionalInput: Data? = nil,
        minimumEntropyByteCount: Int? = nil,
        expected: (initV: String, initK: String)? = nil
        ) {
        self.hasher = hasher
        self.iterationsLeftUntilReseed = HMAC_DRBG.reseedInterval
        self.minimumEntropyByteCount = {
            guard let minimumEntropyByteCount = minimumEntropyByteCount else {
                switch hasher.type {
                // https://github.com/indutny/hash.js/blob/9db0a25077e0237e91c1257552a8d37df1c6e17a/lib/hash/sha/256.js#L56
                case .sha2sha256: return 192/8
                }
            }
            return minimumEntropyByteCount
        }()

        self.K = Data(repeating: 0x00, count: hasher.digestLength)
        self.V = Data(repeating: 0x01, count: hasher.digestLength)

        let seed = entropy + nonce + (personalization ?? Data())
        updateSeed(seed)
    }
}

public extension HMAC_DRBG {

    convenience init<Curve>(message: Message, privateKey: PrivateKey<Curve>, personalization: Data?) {
        self.init(entropy: privateKey.asData(), nonce: message.asData(), personalization: personalization)
    }

    func generateNumberOfLength(byteCount: Int, additionalData: Data? = nil) -> Data {
        return generateNumberOfLength(byteCount, additionalData: additionalData).result
    }

    func reseed(entropy: Data, additionalData: Data = Data()) {
        defer { iterationsLeftUntilReseed = HMAC_DRBG.reseedInterval }
        precondition(entropy.count >= minimumEntropyByteCount, "Not enough entropy. Minimum is #\(minimumEntropyByteCount) bytes")
        updateSeed(entropy + additionalData)
    }
}

extension HMAC_DRBG {
    /// Psuedocode at page 5: https://eprint.iacr.org/2018/349.pdf
    /// Return value `state` is only used by unit tests
    func generateNumberOfLength(_ byteCount: Int, additionalData: Data? = nil) -> (result: Data, state: KeyValue) {
        defer {
            iterationsLeftUntilReseed -= 1
        }
        guard iterationsLeftUntilReseed > 0 else {
            fatalError("Reseed is required")
        }

        if let additionalData = additionalData {
            updateSeed(additionalData)
        }

        var generated = Data()
        while generated.count < byteCount {
            V = HMAC_K(V)
            generated += V.asData
        }
        generated = generated.prefix(byteCount)
        updateSeed(additionalData)
        return (result: generated, state: KeyValue(v: V.asHex, key: K.asHex))
    }
}

private extension HMAC_DRBG {

    func updateSeed(_ _seed: Data? = nil) {
        let seed = _seed ?? Data()
        func update(_ magicByte: Byte) {
            K = HMAC_K(V + magicByte + seed)
            V = HMAC_K(V)
        }
        update(0x00)
        if _seed == nil { return }
        update(0x01)
    }

    func HMAC_K(_ data: DataConvertible) -> Data {
        let bytes = try! Crypto.hmacSha256(key: K.asData.bytes, data: data.asData.bytes)
        return Data(bytes)
    }
}
