# 🚰 IOStreams

[![CI](https://github.com/outfoxx/IOStreams/actions/workflows/ci.yaml/badge.svg)](https://github.com/outfoxx/IOStreams/actions/workflows/ci.yaml)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/outfoxx/IOStreams)

## An asynchronous Swift I/O library

IOStreams is an asynchronous I/O library designed to make it easy to read & write your data taking full advantage of
Swift's powerful concurrency features. It uses a simple `Source` and `Sink` model that makes it easy to implement for
almost any data source or destination.

IOStreams comes with a number of standard sources and sinks, like files and memory, that fully support the async/await
concurrency model of Swift. Additionaly, IOStreams has been integrated with many Apple frameworks to provide buffering,
compression, encryption, hashing, etc.

## Getting Started

Using IOStreams is easy and allows you to consume high performance frameworks, like `DispatchIO`, using Swift
concurrency.

For example, to process large files using `DispatchIO` you only need to create a `FileSource` and `FileSource` and
asynchronously iterate buffers of file data.

```swift
func processFile(from sourceURL: URL, to sinkURL: URL) async {
  let sink = FileSink(url: sinkURL)
  let source = FileSource(url: sourceURL)
  
  for try await data in source.buffers() {
      
      let processedData = // process data
      
      try await sink.write(data: processedData);
  }
  
  try await source.close()
  try await sink.close()
```

If you are reading or writing small amounts of data at a time, buffering the streams can provide a big performance
boost, and with IOSStreams it's easy.

```swift
  let source = FileSource(url: sourceURL).buffered()
```

Additionally, IOStreams is integrated with a number of Apple frameworks to provide transparent data processing like
compression.

To compress the file from the previous example you only need to change one line

```swift
  let sink = FileSink(url: sinkURL).compress(algorithm: .lz4)
```

IOStreams provides integration for compression, encryption, and hashing out of the box.  

## Extending IOStreams

### `Source` and `Sink`

The library is built around primitive stream protocols, `Source` for input  and `Sink` for output. While the protocols 
are easy to implement, their methods are marked as `async` to allow implementors to use Swift concurrency in their
implmentations.

`Source` and `Sink` have been implemented for the two most common data sources, files and memory. 
`FileSource`/`FileSink` and `DataSource`/`DataSink` will handle most of your needs. If they don't, implementing them
is usually very easy. 

### `FilterSource` and `FilterSink`

Transforming data as it is read or written makes IOStreams a powerful data processing library. All of IOStreams' data
transformation capabilities are implemented via `FilterSource` and `FilterSink`; this includes the built-in compression
& encryption integrations.

#### `Filter`

Building your own data transformations are easy and do not require implementing your own `Source` and `Sink`.
Implementing the `Filter` interface and initializing instances of `FilterSource` and/or `FilterSink` is usually all you
will need to do.
  
License
--------

    Copyright 2022 Outfox, Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

