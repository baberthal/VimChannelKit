//
//  TCPServer.swift
//  VimChannelKit
//
//  Created by Morgan Lieberthal on 10/31/16.
//
//

import Socket
import Foundation
import Dispatch

// MARK: - TCPServer

open class TCPServer: Server {
  /// The `ServerType` returned by `TCPServer.listen()`
  public typealias ServerType = TCPServer

  // MARK: - Public Properties

  /// The port this server will listen on
  public var port: Int?

  /// Our delegate
  public var delegate: ServerDelegate?

  /// The state of this server
  public var state: ServerState = .unknown

  /// The hostname this server will listen on.
  public internal(set) var hostname: String

  // MARK: - Internal Properties

  /// The socket this server is listening on
  var listenSocket: Socket? = nil

  /// Lifecycle hook manager for this server
  let lifecycleManager = LifecycleManager()

  /// Maximum number of connections pending in backlog
  open let maximumConnectionBacklog = 100

  // MARK: - Private Properties

  /// Helper to determine if we should invoke added callbacks immediately.
  /// This returns `true` if `self.state == .stopped`
  private var shouldInvokeNow: Bool {
    return self.state == .stopped
  }

  // MARK: - Initializers & Factory Methods

  /// Create a new `TCPServer`, which will listen on `port`
  ///
  /// - parameter hostname: An optional hostname to bind the socket to. Defaults to "127.0.0.1".
  /// - parameter port: The port on which the `TCPServer` will listen.
  /// - returns:  A new `TCPServer` instance, optionally bound to `hostname`,
  ///             configured to listen on `port`.
  init(hostname: String = "127.0.0.1", port: Int, delegate: ServerDelegate? = nil) {
    self.hostname = hostname
    self.port     = port
    self.delegate = delegate
  }

  /// Creates a new instance of `TCPServer` and calls `listen(port:errorHandler:)` on
  /// the new instance.
  ///
  /// - parameter port: port number for new connections.
  /// - parameter errorHandler: optional callback to invoke when the server encounters an error
  /// - returns: A new instance of `TCPServer`, that is listening on `port`
  public static func listen(
    port: Int, delegate: ServerDelegate, errorHandler: ServerErrorHandler?
  ) -> TCPServer {
    let server = TCPServer(port: port, delegate: delegate)
    server.listen(port: port, errorHandler: errorHandler)
    return server
  }

  // MARK: - Public Methods

  /// Listen for connections on a socket.
  ///
  /// - parameter port: port number for new connections.
  /// - parameter errorHandler: optional callback to invoke when the `Server` encounters an error
  public func listen(port: Int = 0, errorHandler: ServerErrorHandler? = nil) {
    self.port = (port == 0) ? self.port! : port
  }

  /// Stop listening for new connections
  public func stop() {
    // remove the reference to `delegate`, because it is not a `weak` reference
    defer { self.delegate = nil }

    // make sure we actually have a listening socket
    guard let sock = self.listenSocket else { return }

    self.state = .stopped
    sock.close()
  }

  /// Add a callback to be invoked when the server is started
  ///
  /// - parameter callback: callback that will be invoked upon successful startup by the receiver
  /// - returns: the receiver of this call
  @discardableResult
  public func started(callback: @escaping () -> Void) -> Self {
    self.lifecycleManager.addStartupCallback(invokeNow: self.shouldInvokeNow, callback)
    return self
  }

  /// Add a callback to be invoked when the server is stopped
  ///
  /// - parameter callback: callback that will be invoked upon stoppage by the receiver
  /// - returns: the receiver of this call
  @discardableResult
  public func stopped(callback: @escaping () -> Void) -> Self {
    self.lifecycleManager.addShutdownCallback(invokeNow: self.shouldInvokeNow, callback)
    return self
  }

  /// Add a callback to be invoked when the server encounters an error
  ///
  /// - parameter callback: callback that will be invoked when the receiver encounters an error
  /// - returns: the receiver of this call
  @discardableResult
  public func failed(callback: @escaping ServerErrorHandler) -> Self {
    self.lifecycleManager.addFailureCallback(callback)
    return self
  }

  // MARK: - Private Methods 
}

// MARK: - Static Methods

extension TCPServer {

}
