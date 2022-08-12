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

import Compression
import Foundation

/// Compressing or decompressing ``Sink``
///
/// Compresses or decompresses the data according to
/// the operation the filter was initialized with.
///
public class CompressionFilter: Filter {

  private static let bufferSize = BufferedSink.segmentSize

  private var filter: OutputFilter?
  private var input: Data
  private var output: Data?

  /// Initializes the filter with the given `operation` and `algorithm`.
  ///
  /// - Parameters:
  ///   - operation: Operation to perform on the passed in data.
  ///   - algorithm: Compression algorithm to use.
  ///
  public init(operation: FilterOperation, algorithm: Algorithm) throws {
    input = Data(capacity: Self.bufferSize)
    filter = try OutputFilter(operation, using: algorithm) { [self] data in
      guard let data = data else { return }

      if output == nil {
        output = data
      }
      else {
        output!.append(data)
      }
    }
  }

  /// Apply the compression operation to the provided data.
  ///
  /// - Parameter data: Data to be compressed or decompressed.
  /// - Returns: Next amount of ready data that has been processed.
  ///
  public func process(data: Data) throws -> Data {
    guard let filter = filter else { fatalError() }

    input.append(data)

    while input.count >= Self.bufferSize {

      let range = 0 ..< Self.bufferSize

      try filter.write(input.subdata(in: range))

      input.removeSubrange(range)
    }

    defer { output = nil }

    return output ?? Data()
  }

  /// Finalize the compression operation.
  ///
  /// - Returns: Final data after the compression operation
  ///   has been finalized.
  ///
  public func finish() throws -> Data? {
    guard let filter = filter else { return nil }

    try filter.write(input)

    try filter.finalize()

    defer { self.filter = nil }

    return output
  }

}

public extension Source {

  /// Applies a compression/decompression filter to this stream.
  ///
  /// - Parameters:
  ///   - operation: Compression or decompression operation to perform.
  ///   - algorithm: Algorithm to compress with.
  /// - Returns: Compression source stream reading from this stream.
  /// - SeeAlso: ``CompressionFilter``
  ///
  func compression(operation: FilterOperation, algorithm: Algorithm) throws -> Source {
    filtered(filter: try CompressionFilter(operation: operation, algorithm: algorithm))
  }

  /// Applies a compression filter to this stream.
  ///
  /// - Parameters:
  ///   - algorithm: Algorithm to compress with.
  /// - Returns: Compressed source stream reading from this stream.
  /// - SeeAlso: ``CompressionFilter``
  ///
  func compress(algorithm: Algorithm) throws -> Source {
    try compression(operation: .compress, algorithm: algorithm)
  }

  /// Applies a decompression filter to this stream.
  ///
  /// - Parameters:
  ///   - algorithm: Algorithm to decompress with.
  /// - Returns: Decompressed source stream reading from this stream.
  /// - SeeAlso: ``CompressionFilter``
  ///
  func decompress(algorithm: Algorithm) throws -> Source {
    try compression(operation: .decompress, algorithm: algorithm)
  }

}

public extension Sink {

  /// Applies a compression/decompression filter to this stream.
  ///
  /// - Parameters:
  ///   - operation: Compression or decrompression operation to perform.
  ///   - algorithm: Algorithm to compress with.
  /// - Returns: Compression sink stream writing to this stream.
  /// - SeeAlso: ``CompressionFilter``
  ///
  func compression(operation: FilterOperation, algorithm: Algorithm) throws -> Sink {
    filtered(filter: try CompressionFilter(operation: operation, algorithm: algorithm))
  }

  /// Applies a compression filter to this stream.
  ///
  /// - Parameters:
  ///   - algorithm: Algorithm to compress with.
  /// - Returns: Compressed sink stream writing to this stream.
  /// - SeeAlso: ``CompressionFilter``
  ///
  func compress(algorithm: Algorithm) throws -> Sink {
    try compression(operation: .compress, algorithm: algorithm)
  }

  /// Applies a decompression filter to this stream.
  ///
  /// - Parameters:
  ///   - algorithm: Algorithm to decompress with.
  /// - Returns: Decompressed sink stream writing to this stream.
  /// - SeeAlso: ``CompressionFilter``
  ///
  func decompress(algorithm: Algorithm) throws -> Sink {
    try compression(operation: .decompress, algorithm: algorithm)
  }

}
