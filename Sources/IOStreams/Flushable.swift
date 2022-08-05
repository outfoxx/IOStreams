//
//  Flushable.swift
//  
//
//  Created by Kevin Wooten on 8/5/22.
//

import Foundation

/// Any type that supports a ``flush()`` operation.
/// 
public protocol Flushable {
  
  /// Writes any pending data to the destination sink.
  ///
  /// - Throws: ``IOError`` if writing pending data fails.
  ///
  func flush() async throws

}
