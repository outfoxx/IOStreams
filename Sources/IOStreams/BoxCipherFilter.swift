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

/// Cryptographic box sealing or opening cipher ``Sink``.
///
/// Treats incoming data buffers as an ordered series of
/// cryptographic boxes that will be sealed or opened,
/// depending on the operating mode.
///
public class BoxCipherFilter: Filter {

  /// Box cipher alogorithm type.
  ///
  public enum Algorithm {
    /// AES-GCM
    ///
    /// Uses AES-GCM (with 12 byte nonces) for box operations.
    ///
    case aesGcm
    /// ChaCha20-Poly1305.
    ///
    /// Uses ChaCha20-Poly1305 (as described in RFC 7539 with 96-bit nonces)
    /// for box operations.
    ///
    case chaCha20Poly
  }

  /// Box cipher operation type.
  ///
  public enum Operation {
    /// Seal each data buffer inside a crytographic box.
    case seal
    /// Open each data buffer from a crytographic box.
    case open
  }

  /// Additional authentication data added to each box.
  private struct AAD {
    public let index: UInt64
    public let isFinal: Bool
  }

  /// Size of the random nonce prepended to each box data.
  public static let nonceSize = 12
  /// Size of the tag produced by the seal operation and appended to the box data.
  public static let tagSize = 16

  /// Reports the size of a sealed box for a given box data size.
  ///
  /// - Parameter dataSize: Size of data in box.
  ///
  public static func sealedBoxSize(dataSize: Int) -> Int { dataSize + nonceSize + tagSize }

  /// Key used to seal or open boxes.
  public let key: SymmetricKey

  private let operation: (Data, AAD, SymmetricKey) throws -> Data
  private let algorthm: Algorithm
  private var boxIndex: UInt64 = 0
  private var boxDataSize: Int
  private var input = Data()

  /// Initializes the cipher with the given ``Operation``, ``Algorithm``, and
  /// cryptographic key.
  ///
  /// - Parameters:
  ///   - operation: Operation to perform on the passed in data.
  ///   - algorithm: Box cipher algorithm to use.
  ///   - key: Cryptographic key to use for sealing/opening.
  ///   - boxDataSize: Size of each cryptographic box; final box may be smaller.
  ///
  public init(
    operation: Operation,
    algorithm: Algorithm,
    key: SymmetricKey,
    boxDataSize: Int = BufferedSource.segmentSize
  ) {
    algorthm = algorithm
    switch (algorithm, operation) {
    case (.aesGcm, .seal):
      self.operation = Self.AESGCMOps.seal(data:aad:key:)
      self.boxDataSize = boxDataSize
    case (.aesGcm, .open):
      self.operation = Self.AESGCMOps.open(data:aad:key:)
      self.boxDataSize = Self.sealedBoxSize(dataSize: boxDataSize)
    case (.chaCha20Poly, .seal):
      self.operation = Self.ChaChaPolyOps.seal(data:aad:key:)
      self.boxDataSize = boxDataSize
    case (.chaCha20Poly, .open):
      self.operation = Self.ChaChaPolyOps.open(data:aad:key:)
      self.boxDataSize = Self.sealedBoxSize(dataSize: boxDataSize)
    }
    self.key = key
  }

  /// Treats `data` as a cryptographic box of data and seals
  /// or opens the box according to the ``Operation`` initialized
  /// with.
  ///
  public func process(data: Data) throws -> Data {

    input.append(data)
    var output = Data()

    while input.count >= (boxDataSize * 2) {

      output.append(try processNextInputBox())
    }

    return output
  }

  /// Finishes processig the sequence of boxes and
  /// returns the last one (if available).
  ///
  public func finish() throws -> Data? {

    guard !input.isEmpty else {
      return nil
    }

    var output = Data()

    if input.count >= boxDataSize {
      output.append(try processNextInputBox())
    }

    // process any leftover data as a final (potentially smaller) box
    if !input.isEmpty {
      output.append(try operation(input, AAD(index: boxIndex, isFinal: true), key))
      input.removeAll()
    }

    return output
  }

  private func processNextInputBox() throws -> Data {
    precondition(input.count >= boxDataSize)

    let range = 0 ..< boxDataSize

    let processed = try operation(input.subdata(in: range), AAD(index: boxIndex, isFinal: false), key)

    boxIndex += 1

    input.removeSubrange(range)

    return processed
  }

  private enum AESGCMOps {

    fileprivate static func seal(data: Data, aad: AAD, key: SymmetricKey) throws -> Data {

      let aad = withUnsafeBytes(of: aad) { Data($0) }

      guard let sealedData = try AES.GCM.seal(data, using: key, authenticating: aad).combined else {
        fatalError()
      }

      return sealedData
    }

    fileprivate static func open(data: Data, aad: AAD, key: SymmetricKey) throws -> Data {

      let aad = withUnsafeBytes(of: aad) { Data($0) }

      return try AES.GCM.open(AES.GCM.SealedBox(combined: data), using: key, authenticating: aad)
    }

  }

  private enum ChaChaPolyOps {

    fileprivate static func seal(data: Data, aad: AAD, key: SymmetricKey) throws -> Data {

      let aad = withUnsafeBytes(of: aad) { Data($0) }

      return try ChaChaPoly.seal(data, using: key, authenticating: aad).combined
    }

    fileprivate static func open(data: Data, aad: AAD, key: SymmetricKey) throws -> Data {

      let aad = withUnsafeBytes(of: aad) { Data($0) }

      return try ChaChaPoly.open(ChaChaPoly.SealedBox(combined: data), using: key, authenticating: aad)
    }

  }

}

public extension Source {

  /// Applies a box ciphering filter to this stream.
  ///
  /// - Parameters:
  ///   - algorithm: Alogorithm for box ciphering.
  ///   - operation: Operation (seal or open) to apply.
  ///   - key: Key to use for cipher.
  ///   - boxDataSize: Size of data in each box; final box may be smaller.
  /// - Returns: Box ciphered source stream reading from this stream.
  func boxCiphered(
    algorithm: BoxCipherFilter.Algorithm,
    operation: BoxCipherFilter.Operation,
    key: SymmetricKey,
    boxDataSize: Int = BufferedSource.segmentSize
  ) -> Source {
    filtered(filter: BoxCipherFilter(operation: operation, algorithm: algorithm, key: key, boxDataSize: boxDataSize))
  }

}

public extension Sink {

  /// Applies a box ciphering filter to this stream.
  ///
  /// - Parameters:
  ///   - algorithm: Alogorithm for box ciphering.
  ///   - operation: Operation (seal or open) to apply.
  ///   - key: Key to use for cipher.
  ///   - boxDataSize: Size of data in each box; final box may be smaller.
  /// - Returns: Box ciphered sink stream writing to this stream.
  func boxCiphered(
    algorithm: BoxCipherFilter.Algorithm,
    operation: BoxCipherFilter.Operation,
    key: SymmetricKey,
    boxDataSize: Int = BufferedSource.segmentSize
  ) -> Sink {
    filtered(filter: BoxCipherFilter(operation: operation, algorithm: algorithm, key: key, boxDataSize: boxDataSize))
  }

}
