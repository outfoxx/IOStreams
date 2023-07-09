// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "IOStreams",
  platforms: [.macOS(.v10_15), .iOS(.v13), .watchOS(.v6), .tvOS(.v13)],
  products: [
    .library(
      name: "IOStreams",
      targets: ["IOStreams"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-atomics.git", .upToNextMinor(from: "1.1.0"))
  ],
  targets: [
    .target(
      name: "IOStreams",
      dependencies: [
        .product(name: "Atomics", package: "swift-atomics")
      ]),
    .testTarget(
      name: "IOStreamsTests",
      dependencies: ["IOStreams"]),
  ]
)

#if swift(>=5.6)
  // Add the documentation compiler plugin if possible
  package.dependencies.append(
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
  )
#endif
