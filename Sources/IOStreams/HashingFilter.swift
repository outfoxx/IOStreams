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

/// Provides access to the result of a hashing filter, after
/// the stream that is using has been closed.
///
public protocol HashingResult {

  /// Computed digest result.
  ///
  /// - Note: The value is not valid until the
  /// stream that is using the related filter is
  /// closed.
  ///
  var digest: Data { get }

}

/// Filter that computes a hash of the processed data.
///
public class HashingFilter: Filter, HashingResult {

  /// Hash Algorithm
  ///
  public enum Algorithm {

    /// Secure Hashing Algorithm 2 (SHA-2) hashing with a 512-bit digest.
    case sha512

    /// Secure Hashing Algorithm 2 (SHA-2) hashing with a 384-bit digest.
    case sha384

    /// Secure Hashing Algorithm 2 (SHA-2) hashing with a 256-bit digest.
    case sha256

    /// Secure Hashing Algorithm 1 (SHA-1) hashing with a 160-bit digest.
    ///
    /// - Warning: SHA-1 is considered insecure and should not be used
    /// for cryptographic operations.
    ///
    case sha1

    /// MD5 Hashing Algorithm.
    ///
    /// - Warning: MD5 is considered insecure and should not be used
    /// for cryptographic operations.
    ///
    case md5
  }

  private struct AnyFunction<HF: HashFunction>: Function {

    var hashFunction: HF

    mutating func update(data: Data) { hashFunction.update(data: data) }
    mutating func finalize() -> Data { Data(hashFunction.finalize()) }

  }

  private var function: Function

  /// Calculated hash digest
  ///
  /// - Note: Available after calling the ``finish()``, which
  /// is called when ``FilterSink/close()`` or ``FilterSource/close()``
  ///
  public private(set) var digest = Data()

  /// Initialize the instance to use the algorithm provided by
  /// `algorithm`.
  ///
  /// - Parameter algorithm: Hashing algorithm used to compute ``digest``.
  ///
  public init(algorithm: Algorithm) {
    switch algorithm {
    case .md5:
      function = AnyFunction(hashFunction: Insecure.MD5())
    case .sha1:
      function = AnyFunction(hashFunction: Insecure.SHA1())
    case .sha256:
      function = AnyFunction(hashFunction: SHA256())
    case .sha384:
      function = AnyFunction(hashFunction: SHA384())
    case .sha512:
      function = AnyFunction(hashFunction: SHA512())
    }
  }

  internal init<HF: HashFunction>(_ hashFunction: HF) {
    function = AnyFunction(hashFunction: hashFunction)
  }

  /// Updates the hash calculation and returns the
  /// data provided in `data`.
  ///
  /// - Parameter data: Data to upate the hash calculation with.
  ///
  public func process(data: Data) -> Data {

    function.update(data: data)

    return data
  }


  /// Finishes the hash calculation and saves the
  /// result in the ``digest`` property.
  ///
  public func finish() async throws -> Data? {

    digest = function.finalize()

    return nil
  }

}

public extension Source {

  /// Applies a hashing filter to this stream.
  ///
  /// - Parameters:
  ///   - algorithm: Hashing algorithm to calculate.
  /// - Returns: Hashing source stream reading from this stream and an
  ///   result object that provides access to the calculated digest.
  /// - SeeAlso: ``HashingFilter``
  ///
  func hashing(algorithm: HashingFilter.Algorithm) -> (Source, HashingResult) {
    let filter = HashingFilter(algorithm: algorithm)
    return (filtered(filter: filter), filter)
  }

}

public extension Sink {

  /// Applies a hashing filter to this stream.
  ///
  /// - Parameters:
  ///   - algorithm: Hashing algorithm to calculate.
  /// - Returns: Hashing sink stream writing to this stream and an
  ///   result object that provides access to the calculated digest.
  /// - SeeAlso: ``HashingFilter``
  ///
  func hashing(algorithm: HashingFilter.Algorithm) -> (Sink, HashingResult) {
    let filter = HashingFilter(algorithm: algorithm)
    return (filtered(filter: filter), filter)
  }

}

private protocol Function {
  mutating func update(data: Data)
  mutating func finalize() -> Data
}
