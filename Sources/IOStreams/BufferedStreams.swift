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

/// ``Source`` that buffers data read from ``source``.
///
public class BufferedSource: Source {

  /// Size of segments read from ``BufferedSource/source``
  public static let segmentSize = 64 * 1024

  /// ``Source``that data is read from.
  public let source: Source

  /// Size of buffers that will be requested from ``source``.
  public let segmentSize: Int

  public private(set) var bytesRead: Int = 0
  private var closed = false

  private var data = Data()

  /// Initializes instance to read data from `source` using
  /// requested size of `segmentSize`.
  ///
  /// - Parameters:
  ///   - source: ``Source`` that data will be written to.
  ///   - segmentSize: Size of data buffers written to `sink`.
  ///
  public init(source: Source, segmentSize: Int = BufferedSource.segmentSize) {
    self.source = source
    self.segmentSize = segmentSize
  }

  /// Requires that the internal buffer has at least
  /// `requiredSize` bytes available.
  ///
  /// - Parameter requiredSize: Number of bytes required to be avilable
  /// - Returns: True if the
  public func require(count requiredSize: Int) async throws -> Bool {
    guard !closed else { throw IOError.streamClosed }

    while data.count < requiredSize {

      try Task.checkCancellation()

      guard let more = try await source.read(max: segmentSize) else {
        return false
      }

      data.append(more)
    }

    return true
  }

  public func read(max: Int) async throws -> Data? {
    guard !closed else { throw IOError.streamClosed }

    if data.isEmpty {

      guard let data = try await source.read(next: max) else {
        return nil
      }

      self.data.append(data)
    }

    let data = data.prefix(max)
    self.data = self.data.subdata(in: data.count ..< self.data.count)

    bytesRead += data.count

    return data
  }

  public func read(next: Int) async throws -> Data? {
    guard !closed else { throw IOError.streamClosed }

    _ = try await require(count: next)

    return try await read(max: next)
  }

  public func close() async throws {
    guard !closed else { return }
    defer { closed = true }

    try await source.close()
  }

}

/// ``Sink`` that buffers data before writing to ``sink``.
///
public class BufferedSink: Sink, Flushable {

  /// Size of segments written to ``BufferedSink/sink``
  public static let segmentSize = BufferedSource.segmentSize

  /// ``Sink`` that data is written to.
  public let sink: Sink

  /// Size of buffers that will be written to ``sink``.
  public let segmentSize: Int

  /// Number of bytes written to this stream.
  public private(set) var bytesWritten: Int = 0

  private var data = Data()
  private var closed = false

  /// Initializes instance to write data to `sink` with a minimum
  /// buffer size of `segmentSize`.
  ///
  /// - Parameters:
  ///   - sink: ``Sink`` data will be written to.
  ///   - segmentSize: Miniumum size of data buffers written to ``sink``.
  ///
  public init(sink: Sink, segmentSize: Int = BufferedSink.segmentSize) {
    self.sink = sink
    self.segmentSize = segmentSize
  }

  public func write(data: Data) async throws {
    guard !closed else { return }

    bytesWritten += data.count

    self.data.append(data)

    if data.count > segmentSize {
      try await flush()
    }
  }

  public func flush() async throws {
    guard !closed else { return }

    try await flush(size: segmentSize)
  }

  private func flush(size: Int) async throws {

    while data.count > size {

      try Task.checkCancellation()

      try await sink.write(data: data.prefix(segmentSize))

      data = data.dropFirst(segmentSize)
    }
  }

  public func close() async throws {
    guard !closed else { return }
    defer { closed = true }

    try await flush(size: 0)

    try await sink.close()
  }

}

public extension Source {

  /// Applies buffering to this source via ``BufferedSource``.
  ///
  /// - Parameter segmentSize: Size of buffers that will be read from this stream.
  /// - Returns: Buffered source stream reading from this stream.
  func buffering(segmentSize: Int = BufferedSource.segmentSize) -> Source {
    if self is BufferedSource {
      return self
    }
    return BufferedSource(source: self, segmentSize: segmentSize)
  }

}

public extension Sink {

  /// Applies buffering to this sink via ``BufferedSink``.
  ///
  /// - Parameter segmentSize: Size of buffers that will be written to this stream.
  /// - Returns: Buffered sink stream writing to this stream.
  func buffering(segmentSize: Int = BufferedSink.segmentSize) -> Sink {
    if self is BufferedSink {
      return self
    }
    return BufferedSink(sink: self, segmentSize: segmentSize)
  }

}
