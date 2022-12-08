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

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public class URLSessionSource: Source {

  public enum HTTPError: Error {
    case invalidResponse
    case invalidStatus
  }

  public typealias Stream = AsyncThrowingStream<Data, Error>

  public private(set) var bytesRead = 0

  private var iterator: Stream.AsyncIterator?

  public convenience init(url: URL, session: URLSession = .shared) {
    self.init(request: URLRequest(url: url), session: session)
  }

  public init(
    request: URLRequest,
    session: URLSession = .shared,
    bufferingPolicy: Stream.Continuation.BufferingPolicy = .unbounded
  ) {

    let stream = Stream(Data.self, bufferingPolicy: bufferingPolicy) { continuation -> Void in

      let task = session.dataTask(with: request)
      task.delegate = DataTaskDelegate(continuation: continuation)

      continuation.onTermination = { _ in
        task.cancel()
      }

      task.resume()
    }

    iterator = stream.makeAsyncIterator()
  }

  public func read(max: Int) async throws -> Data? {
    guard iterator != nil else { throw IOError.streamClosed }

    let next = try await iterator?.next()

    bytesRead += next?.count ?? 0

    return next
  }

  public func close() async throws {
    iterator = nil
  }

  private final class DataTaskDelegate: NSObject, URLSessionDataDelegate {

    let continuation: Stream.Continuation

    init(continuation: Stream.Continuation) {
      self.continuation = continuation
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
      continuation.finish(throwing: error.map { IOError.causedBy($0) })
    }

    public func urlSession(
      _ session: URLSession,
      dataTask: URLSessionDataTask,
      didReceive response: URLResponse,
      completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {

      guard let httpResponse = response as? HTTPURLResponse else {
        continuation.finish(throwing: IOError.causedBy(HTTPError.invalidResponse))
        completionHandler(.cancel)
        return
      }

      if 400 ..< 600 ~= httpResponse.statusCode {
        continuation.finish(throwing: IOError.causedBy(HTTPError.invalidStatus))
        completionHandler(.cancel)
        return
      }

      completionHandler(.allow)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
      continuation.yield(data)
    }

  }

}


extension URL {

  @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
  func source(session: URLSession = .shared) -> URLSessionSource {
    return URLSessionSource(url: self, session: session)
  }

}


extension URLRequest {

  @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
  func source(session: URLSession = .shared) -> URLSessionSource {
    return URLSessionSource(request: self, session: session)
  }

}
