//
//  CompressionFilter.swift
//  
//
//  Created by Kevin Wooten on 8/8/22.
//

import Foundation
import Compression

/// Compressing or decompressing ``Sink``
///
/// Compresses or decompresses the data according to
/// the operation the filter was initialized with.
///
public class CompressionFilter: Filter {

  private var filter: OutputFilter?
  private var output: Data?

  /// Initializes the filter with the given `operation` and `algorithm`.
  /// 
  /// - Parameters:
  ///   - operation: Operation to perform on the passed in data.
  ///   - algorithm: Compression algorithm to use.
  ///
  public init(operation: FilterOperation, algorithm: Algorithm) throws {
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

    try filter.write(data)

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
  func compression(operation: FilterOperation, algorithm: Algorithm) throws -> Source {
    filtered(filter: try CompressionFilter(operation: operation, algorithm: algorithm))
  }

  /// Applies a compression filter to this stream.
  ///
  /// - Parameters:
  ///   - algorithm: Algorithm to compress with.
  /// - Returns: Compressed source stream reading from this stream.
  func compress(algorithm: Algorithm) throws -> Source {
    try compression(operation: .compress, algorithm: algorithm)
  }

  /// Applies a decompression filter to this stream.
  ///
  /// - Parameters:
  ///   - algorithm: Algorithm to decompress with.
  /// - Returns: Decompressed source stream reading from this stream.
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
  func compression(operation: FilterOperation, algorithm: Algorithm) throws -> Sink {
    filtered(filter: try CompressionFilter(operation: operation, algorithm: algorithm))
  }

  /// Applies a compression filter to this stream.
  ///
  /// - Parameters:
  ///   - algorithm: Algorithm to compress with.
  /// - Returns: Compressed sink stream writing to this stream.
  func compress(algorithm: Algorithm) throws -> Sink {
    try compression(operation: .compress, algorithm: algorithm)
  }

  /// Applies a decompression filter to this stream.
  ///
  /// - Parameters:
  ///   - algorithm: Algorithm to decompress with.
  /// - Returns: Decompressed sink stream writing to this stream.
  func decompress(algorithm: Algorithm) throws -> Sink {
    try compression(operation: .decompress, algorithm: algorithm)
  }

}
