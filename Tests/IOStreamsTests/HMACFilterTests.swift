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

final class HMACFilterTests: XCTestCase {

  func testRountTrip() async throws {

    let data = Data(repeating: 0x5A, count: (512 * 1024) + 3333)
    let sink = DataSink()

    let key = SymmetricKey(size: .bits256)

    let (hmacSource, sourceResult) = data.source().authenticating(algorithm: .sha256, key: key)
    do {

      let (hmacSink, sinkResult) = sink.authenticating(algorithm: .sha256, key: key)
      do {

        try await hmacSource.pipe(to: hmacSink)

        try await hmacSink.close()
        try await hmacSource.close()

        XCTAssertEqual(sourceResult.digest, sinkResult.digest)
        XCTAssertEqual(sourceResult.digest, Data(HMAC<SHA256>.authenticationCode(for: data, using: key)))
      }
      catch {
        try await hmacSink.close()
        throw error
      }

    }
    catch {
      try await hmacSource.close()
      throw error
    }
  }

}
