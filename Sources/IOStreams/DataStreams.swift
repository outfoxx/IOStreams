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
//
//  DataStreams.swift
//  MirrorShared
//
//  Created by Kevin Wooten on 8/2/22.
//


public class DataSource: Source {

  public private(set) var data: Data
  public private(set) var bytesRead = 0

  private var closed = false

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

public class DataSink: Sink {

  public private(set) var data: Data
  public var bytesWritten: Int { data.count }

  private var closed = false

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
