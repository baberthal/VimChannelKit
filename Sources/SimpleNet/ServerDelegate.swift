//
//  ServerDelegate.swift
//  VimChannelKit
//
//  Created by Morgan Lieberthal on 10/31/16.
//
//

/// The `ServerDelegate` protocol defines an interface for request handlers that interact with
/// a given `Server` protocol conformer.
///
/// The main method is `handle(request:response:)`, which allows the delegate to process incoming
/// requests, and build the response as needed by the application.
///
/// ## Conforming to the `ServerDelegate` protocol
/// To add `ServerDelegate` conformance to your custom class, you must declare _at least_ the 
/// `handle(request:response:)` method.
///
/// Optionally, you may also override the default (empty) implementations of:
///
///   * `setup()` - called before the `handle(request:response:)` method to perform any 
///                 initialization actions that are required.
///
///   * `finish()` - called after the `handle(request:response:)` method to perform any
///                  cleanup actions that are requered.
///
/// - note: If the `setup()` method throws an error, the `finish()` method will not be called.
public protocol ServerDelegate: class {
  /// Handle an incoming request from the server
  ///
  /// - parameter request: The `Request` instance that was received.
  /// - parameter response: The `Response` instance that will be sent to the client.
  ///
  /// - seealso: `Request`
  /// - seealso: `Response`
  func handle(request: Request, response: Response)

  /// Perform any initialization and setup actions that are necessary for the
  /// `handle(request:response:)` method to complete successfully.  
  ///
  /// - throws: Nothing by default, but conformers may throw an exception.  If this method does
  ///           indeed throw an exception, the `finish()` method __will not be called__.
  func setup() throws
  
  /// Perform any cleanup actions after the `handle(request:response:)` method has completed.
  ///
  /// - note: If the `setup()` method throws an exception, this method __will not be called__.
  func finish()
}

/// Empty default implementations of optional protocol methods
extension ServerDelegate {
  /// Empty default implementation. Override this method to perform any setup actions.
  func setup() throws {}

  /// Empty default implementation. Override this method to perform any cleanup actions.
  func finish() {}
}
