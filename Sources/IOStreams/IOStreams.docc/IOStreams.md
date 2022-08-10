# ``IOStreams``

Asynchronous I/O library built around Swift concurrency.

## Overview

IOStreams is an asynchronous I/O library designed to make it easy to read & write data taking full advantage of
Swift's powerful concurrency features. It uses a simple ``Source`` and ``Sink`` model that makes it easy to implement
for almost any data source or destination.

IOStreams comes with a number of standard sources and sinks, like files and memory, that fully support the async/await
concurrency model of Swift. Additionaly, IOStreams has been integrated with many Apple frameworks to provide buffering,
compression, encryption, hashing, etc.
