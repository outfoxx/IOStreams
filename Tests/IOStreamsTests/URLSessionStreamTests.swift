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

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
final class URLSessionStreamsTests: XCTestCase {

  func testSourceReadsCompletely() async throws {

    let source = URL(string: "https://github.com")!.source()

    for try await buffer in source.buffers() {
      print("### Received \(buffer.count) bytes")
    }

    XCTAssertGreaterThan(source.bytesRead, 50 * 1024)
  }

  func testSourceCancels() async throws {

    let source = URL(string: "https://github.com")!.source()

    let reader = Task {
      for try await buffer in source.buffers(size: 3079) {
        print("### Received \(buffer.count) bytes")
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

    let source = URL(string: "https://github.com")!.source()

    let task = Task {
      for try await _ in source.buffers(size: 1024) {
        withUnsafeCurrentTask { $0?.cancel() }
      }
    }
    try await task.value

    XCTAssert(source.bytesRead > 0, "Data should have been read from source")
    XCTAssert(source.bytesRead < 50 * 1024, "Source should have cancelled iteration")
  }

  func testSourceThrowsInvalidStatus() async throws {

    do {

      _ = try await URLSessionSource(url: URL(string: "http://example.com/non-existent-url")!).read(max: .max)

    }
    catch let error as URLSessionSource.HTTPError {

      XCTAssertEqual(error, .invalidStatus)

    }
    catch {

      XCTFail("Unexpected error thrown")
    }

  }
}
