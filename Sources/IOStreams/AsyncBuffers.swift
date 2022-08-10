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

import Foundation

/// An `AsyncSequence` of `Data` buffers read from a specific ``Source``
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
      }
      else {
        return try await source.read(max: readSize)
      }
    }

  }

  private let source: Source
  private var readSize: Int
  private var required: Bool

  init(source: Source, maxReadSize: Int) {
    self.source = source
    readSize = maxReadSize
    required = false
  }

  init(source: Source, requiredReadSize: Int) {
    self.source = source
    readSize = requiredReadSize
    required = true
  }

  public func makeAsyncIterator() -> AsyncIterator {
    return AsyncIterator(source: source, readSize: readSize, required: required)
  }

}
