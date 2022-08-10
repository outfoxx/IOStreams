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

import Darwin
import Foundation

/// ``Source`` that sequentially reads data from a file.
///
/// - Note: ``FileSource`` uses high performance `DispatchIO`.
///
public class FileSource: FileStream, Source {

  public private(set) var bytesRead: Int = 0

  /// Initialize the source from a file `URL`.
  ///
  /// - Parameter url: `URL` of the file to operate on.
  ///
  public convenience init(url: URL) throws {
    try self.init(fileHandle: FileHandle(forReadingFrom: url))
  }

  /// Initialize the source from a file path.
  ///
  /// - Parameter path: path of the file to operate on.
  ///
  public convenience init(path: String) throws {
    guard let fileHandle = FileHandle(forReadingAtPath: path) else {
      throw IOError.noSuchFile
    }
    try self.init(fileHandle: fileHandle)
  }

  public func read(max: Int) async throws -> Data? {
    guard !closedState.closed else { throw IOError.streamClosed }

    let data: Data? = try await withCheckedThrowingContinuation { continuation in
      withUnsafeCurrentTask { task in

        var collectedData = Data()

        io.read(offset: 0, length: max, queue: .taskPriority) { done, data, error in

          if task?.isCancelled ?? false {
            continuation.resume(throwing: CancellationError())
            return
          }

          if error != 0 {

            let errorCode = POSIXError.Code(rawValue: error) ?? .EIO

            continuation.resume(throwing: POSIXError(errorCode))
          }
          else if let data = data, !data.isEmpty {

            collectedData.append(Data(data))

            if done {
              continuation.resume(returning: collectedData)
            }
          }
          else if done {
            // error is 0, data is empty, and done is true.. flags EOF

            if collectedData.isEmpty {
              // Signal EOF to caller
              continuation.resume(returning: nil)
            }
            else {
              // Return the collected data... EOF will be signaled on next read
              continuation.resume(returning: collectedData)
            }
          }
        }
      }
    }

    bytesRead += data?.count ?? 0

    return data
  }
}


/// ``Sink`` that sequentially writes data to a file.
///
/// - Note: ``FileSink`` uses high performance `DispatchIO`.
///
public class FileSink: FileStream, Sink {

  public private(set) var bytesWritten: Int = 0

  /// Initialize the sink from a file `URL`.
  ///
  /// - Parameter url: `URL` of the file to operate on.
  ///
  public convenience init(url: URL) throws {
    try self.init(fileHandle: FileHandle(forWritingTo: url))
  }

  /// Initialize the sink from a file path.
  ///
  /// - Parameter path: path of the file to operate on.
  ///
  public convenience init(path: String) throws {
    guard let fileHandle = FileHandle(forWritingAtPath: path) else {
      throw IOError.noSuchFile
    }
    try self.init(fileHandle: fileHandle)
  }

  public func write(data: Data) async throws {
    guard !closedState.closed else { throw IOError.streamClosed }

    try await withCheckedThrowingContinuation { continuation in

      withUnsafeCurrentTask { task in

        data.withUnsafeBytes { dataPtr in

          let data = DispatchData(bytes: dataPtr)

          io.write(offset: 0, data: data, queue: .taskPriority) { _, _, error in

            if task?.isCancelled ?? false {
              continuation.resume(throwing: CancellationError())
              return
            }

            if error != 0 {

              let errorCode = POSIXError.Code(rawValue: error) ?? .EIO

              continuation.resume(throwing: POSIXError(errorCode))
            }
            else {
              continuation.resume()
            }
          }

        }

      }
    } as Void

    bytesWritten += Int(data.count)
  }

}


/// Common ``Stream`` that operates on a file.
///
/// - Note: ``FileStream`` uses high performance `DispatchIO`.
///
public class FileStream: Stream {

  private static let progressReportLimits = (
    lowWaterMark: 8 * 1024,
    highWaterMark: 64 * 1024,
    maxInterval: DispatchTimeInterval.microseconds(50)
  )

  struct CloseState {
    var closed = false
    var error: Error?
  }

  fileprivate let fileHandle: FileHandle
  fileprivate var io: DispatchIO!
  fileprivate var closedState = CloseState()

  /// Initialize the stream from a file handle.
  ///
  /// - Parameter fileHandle: Handle of the file to operate on.
  ///
  public required init(fileHandle: FileHandle) throws {

    self.fileHandle = fileHandle
    io = DispatchIO(type: .stream, fileDescriptor: fileHandle.fileDescriptor, queue: .taskPriority) { error in
      let closeError: Error?
      if error != 0 {

        let errorCode = POSIXError.Code(rawValue: error) ?? .EIO

        closeError = IOError.map(error: POSIXError(errorCode))
      }
      else {
        closeError = nil
      }

      self.close(error: closeError)
    }

    // Ensure handlers are called frequently to allow timely cancellation
    io.setLimit(lowWater: Self.progressReportLimits.lowWaterMark)
    io.setLimit(highWater: Self.progressReportLimits.highWaterMark)
    io.setInterval(interval: Self.progressReportLimits.maxInterval, flags: [])
  }

  fileprivate func close(error: Error?) {
    guard !closedState.closed else { return }
    closedState.closed = true
    closedState.error = error
    io.close(flags: [.stop])
  }

  public func close() throws {
    if let error = closedState.error {
      throw error
    }
    close(error: nil)
  }

}


private extension DispatchQueue {

  static var taskPriority: DispatchQueue {

    let qos: DispatchQoS.QoSClass
    switch Task.currentPriority {
    case .userInitiated, .high:
      qos = .userInitiated
    case .utility:
      qos = .utility
    case .background, .low:
      qos = .background
    default:
      qos = .default
    }

    return DispatchQueue.global(qos: qos)
  }

}
