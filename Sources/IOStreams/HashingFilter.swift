//
//  HashingFilter.swift
//  
//
//  Created by Kevin Wooten on 8/8/22.
//

import Foundation
import CryptoKit

public protocol HashingResult {

  var digest: Data? { get }

}

/// Filter that computes a hash of the processed data.
///
public class HashingFilter: Filter, HashingResult {

  public enum Algorithm {
    /// Secure Hashing Algorithm 2 (SHA-2) hashing with a 512-bit digest.
    case sha512
    /// Secure Hashing Algorithm 2 (SHA-2) hashing with a 384-bit digest.
    case sha384
    /// Secure Hashing Algorithm 2 (SHA-2) hashing with a 256-bit digest.
    case sha256
    /// Secure Hashing Algorithm 1 (SHA-1) hashing with a 160-bit digest.
    case sha1
    /// MD5 Hashing Algorithm
    case md5
  }

  private struct AnyFunction<HF: HashFunction> : Function {

    var hashFunction: HF

    mutating func update(data: Data) { hashFunction.update(data: data) }
    mutating func finalize() -> Data { Data(hashFunction.finalize()) }

  }

  private var function: Function

  /// Calculated hash digest
  ///
  /// - Note: Available after calling the ``finish()``, which
  /// is called when ``FilterSink/close()`` or ``FileSource/close()``
  ///
  public private(set) var digest: Data?

  /// Initialize the instance to use the algorithm provided by
  /// `algorithm`.
  ///
  /// - Parameter algorithm: Hashing algorithm used to compute ``digest``.
  ///
  public init(algorithm: Algorithm) {
    switch algorithm {
    case .md5:
      self.function = AnyFunction(hashFunction: Insecure.MD5())
    case .sha1:
      self.function = AnyFunction(hashFunction: Insecure.SHA1())
    case .sha256:
      self.function = AnyFunction(hashFunction: SHA256())
    case .sha384:
      self.function = AnyFunction(hashFunction: SHA384())
    case .sha512:
      self.function = AnyFunction(hashFunction: SHA512())
    }
  }

  internal init<HF: HashFunction>(_ hashFunction: HF) {
    self.function = AnyFunction(hashFunction: hashFunction)
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
  func hashing(algorithm: HashingFilter.Algorithm) -> (Sink, HashingResult) {
    let filter = HashingFilter(algorithm: algorithm)
    return (filtered(filter: filter), filter)
  }

}

private protocol Function {
  mutating func update(data: Data) -> Void
  mutating func finalize() -> Data
}
