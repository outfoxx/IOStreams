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

final class ErrorTests: XCTestCase {

  func testIOErrorDescription() throws {

    XCTAssertEqual(IOError.endOfStream.errorDescription, "End of Stream")
    XCTAssertEqual(IOError.streamClosed.errorDescription, "Stream Closed")
    XCTAssertEqual(IOError.filterFailure(IOError.endOfStream).errorDescription, "Filter Failed: End of Stream")
  }

  @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
  func testHTTPErrorDescription() throws {

    XCTAssertEqual(URLSessionSource.HTTPError.invalidResponse.errorDescription, "Invalid Response")
    XCTAssertEqual(URLSessionSource.HTTPError.invalidStatus.errorDescription, "Invalid Status")
  }

}
