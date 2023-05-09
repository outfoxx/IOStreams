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
public enum IOError: Error, LocalizedError {

  /// End-of-stream was encountered during a read.
  case endOfStream

  /// The stream is closed.
  case streamClosed

  /// Filter operation failed.
  /// - Parameter Error: The filter error that cause the I/O error.
  case filterFailure(Error)

  public var errorDescription: String? {
    switch self {
    case .endOfStream: return "End of Stream"
    case .streamClosed: return "Stream Closed"
    case .filterFailure(let error): return "Filter Failed: \(error.localizedDescription)"
    }
  }

}
