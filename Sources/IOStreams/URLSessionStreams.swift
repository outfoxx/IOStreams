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

import Atomics
import Foundation

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public class URLSessionSource: Source {

  public enum HTTPError: Error, LocalizedError {
    case invalidResponse
    case invalidStatus

    public var errorDescription: String? {
      switch self {
      case .invalidResponse: return "Invalid Response"
      case .invalidStatus: return "Invalid Status"
      }
    }
  }

  public typealias Stream = AsyncThrowingStream<Data, Error>

  public private(set) var bytesRead = 0

  private var iterator: Stream.AsyncIterator?
  private var availableData: Data? = Data()

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

    guard let availableData = availableData else {

      // iterator done, we're done

      return nil
    }

    // Honor cancellation before any work
    try Task.checkCancellation()

    guard !availableData.isEmpty else {

      // no data to return, grab some more and try again

      self.availableData = try await iterator?.next()

      return try await read(max: max)
    }

    // Since we cannot control how much data the URL session task provides
    // in a single callback, we ensure this function honors the `max` parameter.

    let next = availableData.prefix(max)
    self.availableData = availableData.dropFirst(next.count)

    bytesRead += next.count

    return next
  }

  public func close() async throws {
    iterator = nil
  }

  private final class DataTaskDelegate: NSObject, URLSessionDataDelegate {

    var continuation: Stream.Continuation?

    init(continuation: Stream.Continuation) {
      self.continuation = continuation
    }

    func finish(throwing error: Error? = nil) {
      self.continuation?.finish(throwing: error)
      self.continuation = nil
    }

    func checkCancel(task: URLSessionTask) -> Bool {
      if task.state == .canceling {
        finish(throwing: CancellationError())
        return false
      }
      return true
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
      var error = error

      // URLSessionTask is hidden so canceellation comes
      // from Task cancellation so we normalize errors.
      if let urlError = error as? URLError, urlError.code == .cancelled {
        error = CancellationError()
      }

      finish(throwing: error)
    }

    public func urlSession(
      _ session: URLSession,
      dataTask: URLSessionDataTask,
      didReceive response: URLResponse,
      completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
      guard checkCancel(task: dataTask) else {
        completionHandler(.cancel)
        return
      }

      if let httpResponse = response as? HTTPURLResponse, 400 ..< 600 ~= httpResponse.statusCode {
        finish(throwing: HTTPError.invalidStatus)
        completionHandler(.cancel)
        return
      }

      completionHandler(.allow)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
      guard checkCancel(task: dataTask), let continuation = continuation else {
        return
      }

      // BUG: Must manually copy data or suffer random crash working with data later
      continuation.yield(Data(data))
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
