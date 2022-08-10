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

/// ``Source`` that reads directly from a `Data` buffer.
///
public class DataSource: Source {

  /// Data buffer source is reading from.
  public private(set) var data: Data
  public private(set) var bytesRead = 0

  private var closed = false

  /// Initialize the stream with a specified source `data` buffer.
  ///
  /// - Parameter data: Data buffer to read from.
  ///
  public init(data: Data) {
    self.data = data
  }

  public func read(max maxLength: Int) throws -> Data? {
    guard !closed else { throw IOError.streamClosed }

    guard !data.isEmpty else {
      return nil
    }

    let result = data.prefix(maxLength)

    data.removeSubrange(0 ..< result.count)

    bytesRead += result.count

    return result
  }

  public func close() {
    closed = true
  }

}

/// ``Sink`` that writes directly to a `Data` buffer.
///
public class DataSink: Sink {

  /// Data buffer sink is writing to.
  public private(set) var data: Data
  public var bytesWritten: Int { data.count }

  private var closed = false

  /// Initialize the stream with a specified target `data` buffer.
  ///
  /// - Parameter data: Data buffer to write to. Defaults to
  /// the empty buffer.
  ///
  public init(data: Data = Data()) {
    self.data = data
  }

  public func write(data: Data) throws {
    guard !closed else { throw IOError.streamClosed }

    self.data.append(data)
  }

  public func close() {
    closed = true
  }

}

public extension Data {

  func source() -> DataSource { DataSource(data: self) }

}
