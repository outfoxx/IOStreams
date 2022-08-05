//
//  BoxCipherFilterTests.swift
//  
//
//  Created by Kevin Wooten on 8/5/22.
//

import XCTest
import CryptoKit
@testable import IOStreams

final class BoxCipherFilterTests: XCTestCase {

  func testRountTrip() async throws {

    let data = Data(repeating: 0x5A, count: (512 * 1024) + 3333)
    let sink = DataSink()

    let key = SymmetricKey(size: .bits256)

    let cipherSource = data.source().boxCiphered(algorithm: .aesGcm, operation: .seal, key: key)
    do {

      let cipherSink = sink.boxCiphered(algorithm: .aesGcm, operation: .open, key: key)
      do {

        try await cipherSource.pipe(to: cipherSink)

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
