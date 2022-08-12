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

final class BoxCipherFilterTests: XCTestCase {

  func testRountTrip() async throws {

    let data = Data(repeating: 0x5A, count: (512 * 1024) + 3333)
    let sink = DataSink()

    let key = SymmetricKey(size: .bits256)

    let cipherSource = data.source().boxCiphered(algorithm: .aesGcm, operation: .seal, key: key)
    do {

      let cipherSink = sink.boxCiphered(algorithm: .aesGcm, operation: .open, key: key)
      do {

        try await cipherSource.pipe(to: cipherSink, bufferSize: BufferedSource.segmentSize + 31)

        try await cipherSink.close()
      }
      catch {
        try await cipherSink.close()
        throw error
      }

      try await cipherSource.close()
    }
    catch {
      try await cipherSource.close()
      throw error
    }

    XCTAssertEqual(data, sink.data)
  }

}
