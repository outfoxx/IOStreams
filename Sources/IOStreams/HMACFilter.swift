/*
 * Copyright 2022 Outfox, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import CryptoKit
import Foundation

/// Filter that computes an HMAC of the processed data.
///
public class HMACFilter: Filter, HashingResult {

  public typealias Algorithm = HashingFilter.Algorithm

  private var hmac: AnyHMAC
  public private(set) var digest = Data()

  /// Initializes the instance with the given ``HMACFilter/Algorithm``, and
  /// a cryptographic `key`.
  ///
  /// - Parameters:
  ///   - algorithm: Hashing algorithm used to compute the HMAC.
  ///   - key: Cryptographic key to used to compute the HMAC.
  ///
  public init(algorithm: HMACFilter.Algorithm, key: SymmetricKey) {
    switch algorithm {
    case .sha256:
      hmac = HMAC<SHA256>(key: key)
    case .sha384:
      hmac = HMAC<SHA384>(key: key)
    case .sha512:
      hmac = HMAC<SHA512>(key: key)
    case .sha1:
      hmac = HMAC<Insecure.SHA1>(key: key)
    case .md5:
      hmac = HMAC<Insecure.MD5>(key: key)
    }
  }

  /// Updates the HMAC calculation and returns the
  /// data provided in `data`.
  ///
  /// - Parameter data: Data to upate the HMAC calculation with.
  ///
  public func process(data: Data) throws -> Data {
    hmac.update(data: data)
    return data
  }

  /// Finishes the HMAC calculation and saves the
  /// result in the ``digest`` property.
  ///
  public func finish() throws -> Data? {

    digest = hmac.finalizeData()

    return nil
  }

}

public extension Source {

  /// Applies a HMAC computation filter to this stream.
  ///
  /// - Parameters:
  ///   - algorithm: Hashing algorithm used to compute the HMAC.
  ///   - key: Cryptographic key to used to compute the HMAC.
  /// - Returns: HMAC computing stream reading from this stream and
  ///   a result object that provides access to the calculated digest.
  /// - SeeAlso: ``HMACFilter``
  ///
  func authenticating(
    algorithm: HMACFilter.Algorithm,
    key: SymmetricKey
  ) -> (Source, HashingResult) {
    let filter = HMACFilter(algorithm: algorithm, key: key)
    return (filtering(using: filter), filter)
  }

}

public extension Sink {

  /// Applies a HMAC computation filter to this stream.
  ///
  /// - Parameters:
  ///   - algorithm: Hashing algorithm used to compute the HMAC.
  ///   - key: Cryptographic key to used to compute the HMAC.
  /// - Returns: HMAC computing stream writing to this stream and
  ///   a result object that provides access to the calculated digest.
  /// - SeeAlso: ``HMACFilter``
  ///
  func authenticating(
    algorithm: HMACFilter.Algorithm,
    key: SymmetricKey
  ) -> (Sink, HashingResult) {
    let filter = HMACFilter(algorithm: algorithm, key: key)
    return (filtering(using: filter), filter)
  }

}


private protocol AnyHMAC {
  mutating func update<D : DataProtocol>(data: D)
  func finalizeData() -> Data
}

extension HMAC: AnyHMAC {

  func finalizeData() -> Data {
    return Data(finalize())
  }

}
