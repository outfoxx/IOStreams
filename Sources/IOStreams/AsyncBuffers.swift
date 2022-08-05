//
//  AsyncBuffers.swift
//  
//
//  Created by Kevin Wooten on 8/5/22.
//

import Foundation

/// An `AsynSequence` of `Data` buffers read from a spcific ``Source``
/// 
public struct AsyncBuffers: AsyncSequence {

  public typealias Element = Data

  public struct AsyncIterator: AsyncIteratorProtocol {

    let source: Source
    let readSize: Int
    let required: Bool

    public func next() async throws -> Data? {
      if required {
        return try await source.read(next: readSize)
      } else {
        return try await source.read(max: readSize)
      }
    }

  }

  private let source: Source
  private var readSize: Int
  private var required: Bool

  init(source: Source, maxReadSize: Int) {
    self.source = source
    self.readSize = maxReadSize
    self.required = false
  }

  init(source: Source, requiredReadSize: Int) {
    self.source = source
    self.readSize = requiredReadSize
    self.required = true
  }

  public func makeAsyncIterator() -> AsyncIterator {
    return AsyncIterator(source: source, readSize: readSize, required: required)
  }

}
