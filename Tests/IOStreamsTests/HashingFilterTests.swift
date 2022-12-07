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

import CryptoKit
@testable import IOStreams
import XCTest

final class HashingFilterTests: XCTestCase {

  func testRoundTrip() async throws {

    let data = Data(repeating: 0x5A, count: (512 * 1024) + 3333)
    let sink = DataSink()

    let (hashingSource, sourceResult) = data.source().hashing(algorithm: .sha256)
    do {

      let (hashingSink, sinkResult) = sink.hashing(algorithm: .sha256)
      do {

        try await hashingSource.pipe(to: hashingSink)

        try await hashingSink.close()
        try await hashingSource.close()

        XCTAssertEqual(sourceResult.digest, sinkResult.digest)
        XCTAssertEqual(sourceResult.digest, Data(SHA256.hash(data: data)))
      }
      catch {
        try await hashingSink.close()
        throw error
      }

    }
    catch {
      try await hashingSource.close()
      throw error
    }
  }

}
