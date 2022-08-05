//
//  File.swift
//  
//
//  Created by Kevin Wooten on 8/5/22.
//

import Foundation
//
//  DataStreams.swift
//  MirrorShared
//
//  Created by Kevin Wooten on 8/2/22.
//

import Foundation

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

    data.removeSubrange(0..<result.count)

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
