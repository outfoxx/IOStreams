//
//  BufferedStreamsTests.swift
//  
//
//  Created by Kevin Wooten on 8/8/22.
//

import XCTest
@testable import IOStreams

final class BufferedStreamsTests: XCTestCase {

  func testSourceReadSizes() async throws {

    let data = Data((0 ..< 1024).map { _ in UInt8.random(in: 0 ... 255) })

    let source = ReadSizeValidator(source: data.source(), size: 128).buffered(segmentSize: 128)

    var read = try await source.read(exactly: 1)
    XCTAssertEqual(read, data[0..<1])

    read = try await source.read(exactly: 2)
    XCTAssertEqual(read, data[1..<3])

    read = try await source.read(exactly: 4)
    XCTAssertEqual(read, data[3..<7])

    read = try await source.read(exactly: 8)
    XCTAssertEqual(read, data[7..<15])

    read = try await source.read(exactly: 16)
    XCTAssertEqual(read, data[15..<31])

    read = try await source.read(exactly: 32)
    XCTAssertEqual(read, data[31..<63])

    read = try await source.read(exactly: 64)
    XCTAssertEqual(read, data[63..<127])

    read = try await source.read(exactly: 128)
    XCTAssertEqual(read, data[127..<255])

    read = try await source.read(exactly: 256)
    XCTAssertEqual(read, data[255..<511])

    read = try await source.read(exactly: 512)
    XCTAssertEqual(read, data[511..<1023])

    read = try await source.read(exactly: 1)
    XCTAssertEqual(read, data[1023..<1024])

  }

  func testSinkWriteSize() async throws {

    let data = Data((0 ..< 1024).map { _ in UInt8.random(in: 0 ... 255) })

    let dataSink = DataSink()
    let sink = WriteSizeValidator(sink: dataSink, size: 128).buffered(segmentSize: 128)

    try await sink.write(data: data[0..<1])
    try await sink.write(data: data[1..<3])
    try await sink.write(data: data[3..<7])
    try await sink.write(data: data[7..<15])
    try await sink.write(data: data[15..<31])
    try await sink.write(data: data[31..<63])
    try await sink.write(data: data[63..<127])
    try await sink.write(data: data[127..<255])
    try await sink.write(data: data[255..<511])
    try await sink.write(data: data[511..<1023])
    try await sink.write(data: data[1023..<1024])

    try await sink.close()

    XCTAssertEqual(dataSink.data, data)
  }

}


struct ReadSizeValidator: Source {

  let source: Source
  let size: Int

  var bytesRead: Int {
    get async throws { try await source.bytesRead }
  }

  func read(max: Int) async throws -> Data? {

    XCTAssertEqual(max, size)

    return try await source.read(max: max)
  }

  func close() async throws {
    try await source.close()
  }
}

struct WriteSizeValidator: Sink {

  let sink: Sink
  let size: Int

  var bytesWritten: Int {
    get async throws { try await sink.bytesWritten }
  }

  func write(data: Data) async throws {

    XCTAssertEqual(data.count, size)

    try await sink.write(data: data)
  }

  func close() async throws {
    try await sink.close()
  }
}
