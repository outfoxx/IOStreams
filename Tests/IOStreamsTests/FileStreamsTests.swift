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

@testable import IOStreams
import XCTest

final class FileStreamsTests: XCTestCase {

  var fileURL: URL!

  override func setUp() async throws {

    fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    if !FileManager.default.createFile(atPath: fileURL.path, contents: nil) {
      throw CocoaError(.fileWriteUnknown)
    }
  }

  override func tearDown() async throws {
    try? FileManager.default.removeItem(at: fileURL)
  }

  func testSourceReadsCompletely() async throws {

    let fileSize = 50 * 1024 * 1024
    let fileHandle = try FileHandle(forUpdating: fileURL)
    try fileHandle.truncate(atOffset: UInt64(fileSize))
    try fileHandle.seek(toOffset: 0)
    try fileHandle.close()

    let source = try FileSource(url: fileURL)

    for try await _ in source.buffers() {
      // read all buffers to test bytesRead
    }

    XCTAssertEqual(source.bytesRead, fileSize)
  }

  func testSourceCancels() async throws {

    let fileSize = 256 * 1024
    let fileHandle = try FileHandle(forUpdating: fileURL)
    try fileHandle.truncate(atOffset: UInt64(fileSize))
    try fileHandle.seek(toOffset: 0)
    try fileHandle.close()

    let source = try FileSource(url: fileURL)

    let reader = Task {
      for try await _ /* data */ in source.buffers(size: 3079) {
        // print("Read \(data.count) bytes of data")
      }
    }

    do {
      reader.cancel()
      try await reader.value
    }
    catch is CancellationError {}

    XCTAssertEqual(source.bytesRead, 0)
  }

  func testSourceCancelsAfterStart() async throws {

    let fileSize = 1 * 1024 * 1024
    let fileHandle = try FileHandle(forUpdating: fileURL)
    try fileHandle.truncate(atOffset: UInt64(fileSize))
    try fileHandle.seek(toOffset: 0)
    try fileHandle.close()

    let source = try FileSource(url: fileURL)

    let reader = Task {
      for try await _ in source.buffers(size: 133) {
        withUnsafeCurrentTask { $0!.cancel() }
      }
    }

    do {
      try await reader.value
      XCTFail("Expected cancellation error")
    }
    catch is CancellationError {
      // expected
    }
    catch {
      XCTFail("Unexpected error thrown: \(error.localizedDescription)")
    }

    XCTAssert(source.bytesRead > 0, "Data should have been read from source")
    XCTAssert(source.bytesRead < fileSize, "Source should have cancelled iteration")
  }

  func testSourceContinuesAfterCancel() async throws {

    let fileSize = 256 * 1024
    let fileHandle = try FileHandle(forUpdating: fileURL)
    try fileHandle.truncate(atOffset: UInt64(fileSize))
    try fileHandle.seek(toOffset: 0)
    try fileHandle.close()

    let source = try FileSource(url: fileURL)

    let reader = Task {
      for try await _ /* data */ in source.buffers(size: 3079) {
        // print("Read \(data.count) bytes of data")
      }
    }

    do {
      reader.cancel()
      try await reader.value
      XCTFail("Expected cancellation error")
    }
    catch is CancellationError {
      // expected
    }
    catch {
      XCTFail("Unexpected error thrown: \(error.localizedDescription)")
    }

    XCTAssertEqual(source.bytesRead, 0)

    do {
      _ = try await source.read(exactly: 1000)
    }
    catch {
      XCTFail("Unexpected error thrown: \(error.localizedDescription)")
    }

    XCTAssertEqual(source.bytesRead, 1000)
  }

  func testSinkCancels() async throws {

    let source = DataSource(data: Data(count: 1024 * 1024))
    let sink = try FileSink(url: fileURL)

    let reader = Task {
      for try await buffer in source.buffers() {
        try await sink.write(data: buffer)
      }
    }

    do {
      reader.cancel()
      try await reader.value
      XCTFail("Expected cancellation error")
    }
    catch is CancellationError {
      // expected
    }
    catch {
      XCTFail("Unexpected error thrown: \(error.localizedDescription)")
    }

    XCTAssertEqual(sink.bytesWritten, 0)
  }

  func testSinkCancelsAfterStart() async throws {

    let source = DataSource(data: Data(count: 1024 * 1024))
    let sink = try FileSink(url: fileURL)

    let reader = Task {
      for try await buffer in source.buffers(size: 113) {
        try await sink.write(data: buffer)
      }
    }

    try await Task.sleep(nanoseconds: 5_000_000)

    do {
      reader.cancel()
      try await reader.value
      XCTFail("Expected cancellation error")
    }
    catch is CancellationError {
      // expected
    }
    catch {
      XCTFail("Unexpected error thrown: \(error.localizedDescription)")
    }

    XCTAssert(sink.bytesWritten > 0, "Data should have been written to sink")
    XCTAssert(sink.bytesWritten < source.data.count, "Sink should have cancelled iteration")
  }

  func testSinkContinuesAfterCancel() async throws {

    let source = DataSource(data: Data(count: 1024 * 1024))
    let sink = try FileSink(url: fileURL)

    let reader = Task {
      for try await buffer in source.buffers(size: 100) {
        try await sink.write(data: buffer)
      }
    }

    do {
      reader.cancel()
      try await reader.value
      XCTFail("Expected cancellation error")
    }
    catch is CancellationError {
      // expected
    }
    catch {
      XCTFail("Unexpected error thrown: \(error.localizedDescription)")
    }

    XCTAssertEqual(sink.bytesWritten, 0)
    XCTAssertEqual(try fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize, 0)

    try await sink.write(data: Data(count: 1000))
    try sink.close()

    XCTAssertEqual(sink.bytesWritten, 1000)
    fileURL.removeAllCachedResourceValues()
    XCTAssertEqual(try fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize, 1000)
  }

  func testInvalidFileSourceThrows() async throws {

    do {

      _ = try FileSource(path: "/non-esixtent-file")

    }
    catch let error as CocoaError {

      XCTAssertEqual(error.code, .fileReadNoSuchFile)

    }
    catch {

      XCTFail("Incorrect exception caught")
    }

  }

  func testInvalidFileSinkThrows() async throws {

    do {

      _ = try FileSink(path: "/non-esixtent-file")

    }
    catch let error as CocoaError {

      XCTAssertEqual(error.code, .fileNoSuchFile)

    }
    catch {

      XCTFail("Incorrect exception caught")
    }

  }

}
