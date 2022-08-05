//
//  Sink.swift
//  
//
//  Created by Kevin Wooten on 8/4/22.
//

import Foundation

/// ``Stream`` that accepts data.
public protocol Sink: Stream {
  
  /// Number of bytes written to this stream.
  ///
  /// - Throws: `IOError` if the # of bytes written cannot be determined.
  var bytesWritten: Int { get async throws }
  
  /// Write the given `data` to the stream.
  ///
  /// - Note: The complete `data` will always be written unless
  ///   an error is thrown.
  /// - Parameters:
  ///   - data: data to write
  /// - Throws: ``IOError`` if the complete data cannot be written.
  func write(data: Data) async throws
  
}
