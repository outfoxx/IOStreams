//
//  CompressionFilterTests.swift
//  
//
//  Created by Kevin Wooten on 8/5/22.
//

import XCTest
import CryptoKit
@testable import IOStreams

final class CompressionFilterTests: XCTestCase {

  func testRountTrip() async throws {

    let data = Data(repeating: 0x5A, count: (512 * 1024) + 3333)
    let sink = DataSink()

    let compressingSource = try data.source().compress(algorithm: .lz4)
    do {

      let decompressingSink = try sink.decompress(algorithm: .lz4)
      do {

        try await compressingSource.pipe(to: decompressingSink)

        try await decompressingSink.close()
      }
      catch {
        try await decompressingSink.close()
        throw error
      }

      try await compressingSource.close()
    }
    catch {
      try await compressingSource.close()
      throw error
    }

    XCTAssertEqual(data, sink.data)
  }

}
