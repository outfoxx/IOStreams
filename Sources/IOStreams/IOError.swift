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

import Foundation

/// I/O related errors
public enum IOError: Error {

  /// An I/O operation was attempted on a file that does not exist.
  case noSuchFile

  /// End-of-stream was encountered during a read.
  case endOfStream

  /// The I/O operation was cancelled by its parent task.
  case cancelled

  /// The stream is closed.
  case streamClosed

  /// Filter operation failed.
  /// - Parameter Error: The filter error that cause the I/O error.
  case filterFailure(Error)

  /// An unknown I/O operation occurred.
  case unknown

  /// A non-specific I/O errorr occurred that was caused by another error.
  /// - Parameter Error: The original error that cause the I/O error.
  case causedBy(Error)


  static func map(error: Error) -> Error {
    switch error {
    case is CancellationError:
      return error

    case let posixError as POSIXError:
      switch posixError.code {
      case .ENOENT:
        return Self.noSuchFile
      case .ECANCELED:
        return Self.cancelled
      default:
        return Self.causedBy(posixError)
      }

    case let cocoaError as CocoaError:
      switch cocoaError.code {
      case .fileNoSuchFile, .fileReadNoSuchFile:
        return Self.noSuchFile
      default:
        return Self.causedBy(cocoaError)
      }

    default:
      return Self.causedBy(error)
    }
  }

}
