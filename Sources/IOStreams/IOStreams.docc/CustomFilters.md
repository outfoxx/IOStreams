# Custom Filters

IOStreams can be easily extended to add your own data processing features by creating a custom ``Filter``. 

## Overview

Transforming data as it is read or written makes IOStreams a powerful data processing library. Although data processing
features can be added by creating custom sources or sinks, it's usually a lot easier than that. All of 
IOStreams' data transformations are implemented via ``FilterSource`` and ``FilterSink``, including advaned features 
like the built-in compression & encryption, using a custom ``Filter``. Once implemented, you only need to instantiate
a ``FilterSource`` or ``FilterSink`` with your have a custom filter to have complete integration.  

### Filters

Building your own data transformations via ``Filter`` is usually pretty simple, given the simplicity of the protocol
itself.

```swift
public protocol Filter {

  func process(data: Data) async throws -> Data

  func finish() async throws -> Data?
}
```

Filters are created in a starting state, after which ``Filter/process(data:)`` is called repeatedly for every read from
a source or write to a sink, and finally the ``Filter/finish()`` function is called.

For each call of ``Filter/process(data:)`` the method _may_ return some output data, if available and needed, After
stream data is exhausted, when ``Source/read(max:)`` return `nil` for sources or on ``Stream/close()`` for sinks,
then the filter's ``Filter/finish()`` method is called.

> Important: Filters are always one-time-use. They are created for a specific stream and used until it closed, at
which point they are discarded.
