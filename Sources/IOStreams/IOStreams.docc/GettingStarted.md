# Getting Started

Using IOStreams allows easy data processing, reading data from a ``Source`` and writing the data to a ``Sink``
optionally transforming the data along the way.

``Source``s represent anything that can produce data to be processed, while ``Sink``s represent anything that can
consume data. IOStreams provides many standard sources like ``FileSource`` and ``DataSource`` and their corresponding
sinks ``FileSink`` and ``DataSink``.

For example, to copy large files you only need to create a ``FileSource`` and ``FileSink`` and then asynchronously
iterate buffers of file data.

```swift
func processFile(from sourceURL: URL, to sinkURL: URL) async {
  let sink = FileSink(url: sinkURL)
  let source = FileSource(url: sourceURL)
  
  for try await data in source.buffers() {
      
      try await sink.write(data: processedData);
  }
  
  try await source.close()
  try await sink.close()
}
```

If you are reading or writing small amounts of data at a time, buffering the streams can provide a big performance
boost, and with IOSStreams it's as easy as calling ``Source/buffering(segmentSize:)``.

```swift
  let source = FileSource(url: sourceURL).buffered()
```

## Data Processing

IOStreams provides enhanced filtering capabilities that allow data to be processed as it is being read from a
``Source`` or even as it is being written to a ``Sink``. IOStreams integrates with a number of Apple frameworks to
provide advanced data processing features like compression and encryption.

For example, to compress the file from the previous example as it is being written to disk you only need to add a
call to ``Sink/compressing(algorithm:)``:
```swift
  let sink = FileSink(url: sinkURL).compress(algorithm: .lz4)
```

To decompress the file while reading it later you can call ``Source/decompressing(algorithm:)``;
```swift
  let source = FileSource(url: sourceURL).decompress(algorithm: .lz4)
```

IOStreams provides integration for compression, encryption, and hashing out of the box.

