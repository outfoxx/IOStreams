//
//  FilterSink.swift
//  
//
//  Created by Kevin Wooten on 8/5/22.
//

import Foundation

/// Data processing filter.
///
public protocol Filter {

  /// Continues the filtering process by transforming a
  /// single data buffer and return the resultant data buffer.
  ///
  func process(data: Data) async throws -> Data

  /// Finishes the filtering process and returns any
  /// final data produced.
  ///
  func finish() async throws -> Data?

}

/// ``Source`` that transforms data using a ``Filter`` after
/// reading from an originating ``Source``.
///
open class FilterSource: Source {

  /// The ``Source`` filtered data is read from.
  open private(set) var source: Source

  open private(set) var bytesRead: Int = 0

  private var filter: Filter
  private var closed = false

  public required init(source: Source, filter: Filter) {
    self.source = source
    self.filter = filter
  }

  open func read(max: Int) async throws -> Data? {
    guard !closed else { throw IOError.streamClosed }

    guard let readData = try await source.read(next: max) else {

      guard let finalData = try await finish(filter: filter) else {
        return nil
      }

      bytesRead += finalData.count

      return finalData
    }

    let processedData = try await process(filter: filter, data: readData)

    bytesRead += processedData.count

    return processedData
  }

  open func close() async throws {
    closed = true
  }

}

/// ``Sink`` that transforms data using a ``Filter`` before
/// writing to an accepting ``Sink``
///
open class FilterSink: Sink {

  /// The ``Sink`` transformed data is written to.
  open private(set) var sink: Sink

  open private(set) var bytesWritten: Int = 0

  private var filter: Filter
  private var closed = false

  public required init(sink: Sink, filter: Filter) {
    self.sink = sink
    self.filter = filter
  }

  open func write(data: Data) async throws {
    guard !closed else { return }

    let processedData = try await process(filter: filter, data: data)

    bytesWritten += processedData.count

    try await sink.write(data: processedData)
  }
  
  /// Closes the stream after writing any final data to the
  /// destination ``sink``.
  ///
  /// - Throws: ``IOError`` if stream finalization and/or close fails.
  open func close() async throws {
    guard !closed else { return }
    defer { closed = true }

    if let data = try await finish(filter: filter) {

      bytesWritten += data.count

      try await sink.write(data: data)
    }
  }
  
}

public extension Source {

  /// Applies the filter `filter` to this stream via ``FilterSource``.
  ///
  /// - Parameter filter: Filter to apply.
  /// - Returns: Filtered source stream reading from this stream.
  func filtered(filter: Filter) -> Source {
    FilterSource(source: self, filter: filter)
  }

}

public extension Sink {

  /// Applies the filter `filter` to this stream via ``FilterSink``.
  ///
  /// - Parameter filter: Filter to apply.
  /// - Returns: Filtered sink stream writing to this stream.
  func filtered(filter: Filter) -> Sink {
    FilterSink(sink: self, filter: filter)
  }

}


// Wraps filter process failures in IOError
private func process(filter: Filter, data: Data) async throws -> Data {
  do {
    return try await filter.process(data: data)
  }
  catch {
    throw IOError.filterFailure(error)
  }
}

// Wraps filter finish failures in IOError
private func finish(filter: Filter) async throws -> Data? {
  do {
    return try await filter.finish()
  }
  catch {
    throw IOError.filterFailure(error)
  }
}
