//
//  Server.swift
//  VimChannelKit
//
//  Created by Morgan Lieberthal on 10/30/16.
//
//

import Socket

/// An optional callback to invoke when the `Server` encounters an error
public typealias ServerErrorHandler = (Swift.Error) -> Void

/// A common protocol for Servers
public protocol Server: class {
  /// The type that will be returned from `listen(port:errorHandler:)`
  associatedtype ServerType

  /// The address family used by the Server
  static var protocolFamily: Socket.ProtocolFamily { get }

  /// The socket type used by the Server
  static var socketType: Socket.SocketType { get }

  /// Port number that the `Server` will listen on
  var port: Int { get }

  /// State of this `Server`
  var state: ServerState { get }

  /// This server's delegate
  var delegate: ServerDelegate? { get set }

  /// Listen for connections on a socket.
  ///
  /// - parameter port: port number for new connections.
  /// - parameter errorHandler: optional callback to invoke when the `Server` encounters an error
  func listen(errorHandler: ServerErrorHandler?)

  /// Creates a new instance of the most derived class and calls `listen(port:errorHandler:)` on 
  /// the new instance.
  ///
  /// - parameter port: port number for new connections.
  /// - parameter errorHandler: optional callback to invoke when the server encounters an error
  /// - returns: A new instance of the most derived class, that is listening on `port`
  static func listen(
    port: Int, delegate: ServerDelegate, errorHandler: ServerErrorHandler?
  ) -> ServerType

  /// Stop listening for new connections
  func stop()

  /// Add a callback to be invoked when the server is started
  ///
  /// - parameter callback: callback that will be invoked upon successful startup by the receiver
  /// - returns: the receiver of this call
  @discardableResult
  func started(callback: @escaping () -> Void) -> Self

  /// Add a callback to be invoked when the server is stopped
  ///
  /// - parameter callback: callback that will be invoked upon stoppage by the receiver
  /// - returns: the receiver of this call
  @discardableResult
  func stopped(callback: @escaping () -> Void) -> Self

  /// Add a callback to be invoked when the server encounters an error
  ///
  /// - parameter callback: callback that will be invoked when the receiver encounters an error
  /// - returns: the receiver of this call
  @discardableResult
  func failed(callback: @escaping ServerErrorHandler) -> Self
}
