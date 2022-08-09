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

/// ``Stream`` that accepts data.
public protocol Sink: Stream {
  
  /// Number of bytes written to this stream.
  ///
  /// - Throws: `IOError` if the # of bytes written cannot be determined.
  var bytesWritten: Int { get async throws }
  
  /// Write the given `data` to the stream.
  ///
  /// - Note: The complete `data` will always be written unless
  ///   an error is thrown.
  /// - Parameters:
  ///   - data: data to write
  /// - Throws: ``IOError`` if the complete data cannot be written.
  func write(data: Data) async throws
  
}
