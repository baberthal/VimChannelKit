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
import LoggerAPI

// MARK: - TCPServer

open class TCPServer: Server {
  /// The `ServerType` returned by `TCPServer.listen()`
  public typealias ServerType = TCPServer

  /// This server uses the `inet` protocol
  public static let protocolFamily: Socket.ProtocolFamily = .inet

  /// This server uses the `stream` socket type
  public static let socketType: Socket.SocketType = .stream

  /// The maximum number of pending connections in the backlog
  public static let maximumPendingConnections = 100

  // MARK: - Public Properties

  /// The port this server will listen on
  public var port: Int

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

  /// Connection manager for this server
  let connectionManager = ConnectionManager()

  // MARK: - Private Properties

  /// Helper to determine if we should invoke added callbacks immediately.
  /// This returns `true` if `self.state == .stopped`
  private var shouldInvokeNow: Bool {
    return self.state == .stopped
  }

  /// An `Event` to signal that the server should shut down
  private var _isShutDown = Event()

  /// This is set to `true` once a shutdown has been requested
  private var _shutdownRequested = false

  // MARK: - Initializers & Factory Methods

  /// Create a new `TCPServer`, which will listen on `port`
  ///
  /// - parameter hostname: Reserved for future use.
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
    server.listen(errorHandler: errorHandler)
    return server
  }

  // MARK: - Public Methods

  /// Listen for connections on a socket.
  ///
  /// - parameter port: port number for new connections.
  /// - parameter errorHandler: optional callback to invoke when the `Server` encounters an error
  public func listen(errorHandler: ServerErrorHandler? = nil) {
    do {
      self.listenSocket = try Socket.create(family: TCPServer.protocolFamily,
                                            type: TCPServer.socketType,
                                            proto: .tcp)
    } catch let error as Socket.Error {
      Log.error("Error creating socket: \(error.description)")
      _socketFailure(error: error)
    } catch {
      Log.error("Unexpected error: \(error)")
      _socketFailure(error: error)
    }

    // just return here, because any failure will be handled by `errorHandler` below
    guard let socket = self.listenSocket else { return }

    let queuedBlock = DispatchWorkItem(block: {
      do {
        try self.listen(socket: socket, port: self.port)
      } catch {
        if let cb = errorHandler {
          cb(error)
        } else {
          Log.error("Error listening on socket: \(socket)")
        }

        // does this belong here? should we just override the setter for `state` to
        // invoke the failure callbacks when `newValue == .failed`?
        self.state = .failed
        self.lifecycleManager.doFailureCallbacks(with: error)
      }
    })

    ListenerGroup.enqueueAsynchronously(on: DispatchQueue.global(), block: queuedBlock)
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

  /// Extracted common failure code
  private func _socketFailure(error: Swift.Error) {
    self.state = .failed
    self.lifecycleManager.doFailureCallbacks(with: error)
  }

  /// Handle instructions for listening on a socket
  ///
  /// - parameter socket: socket to use for connection
  /// - parameter port: port number to listen on
  private func listen(socket: Socket, port: Int) throws {
    do {
      try socket.listen(on: port, maxBacklogSize: TCPServer.maximumPendingConnections)

      self.state = .started
      self.lifecycleManager.doStartupCallbacks()

      Log.info("Listening on port \(port)")

      repeat {
        let clientSocket = try socket.acceptClientConnection()
        Log.info("Accepted connection from: " +
                 "\(clientSocket.remoteHostname):\(clientSocket.remotePort)")
        self.addClientConnection(over: clientSocket)
      } while true

    } catch let error as Socket.Error {
      if self.state == .stopped && error.errorCode == Int32(Socket.SOCKET_ERR_ACCEPT_FAILED) {
        self.lifecycleManager.doShutdownCallbacks()
        Log.info("Server has stopped listening")
      } else {
        throw error
      }
    }
  }

  /// Add a new connection over a socket
  ///
  /// - parameter socket: The socket over which the connection will take place
  private func addClientConnection(over socket: Socket) {
    guard let delegate = self.delegate else { return }
    self.connectionManager.addConnection(over: socket, using: delegate)
  }
}
