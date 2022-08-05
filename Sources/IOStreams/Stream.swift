//
//  Stream.swift
//  
//
//  Created by Kevin Wooten on 8/4/22.
//

import Foundation

/// Common stream base protocol.
public protocol Stream {
  
  /// Closes the stream.
  /// 
  /// - Throws: ``IOError`` if stream finalization and/or close fails.
  func close() async throws
  
}

