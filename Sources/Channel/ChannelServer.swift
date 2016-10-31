//
//  ChannelServer.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/5/16.
//
//

import Foundation
import Socket
import Dispatch
import LoggerAPI
import SimpleNet

/// A channel server for Vim
public class ChannelServer: ChannelBackend, Server {
  /// ServerDelegate that will handle the request-response cycle
  public weak var delegate: ChannelDelegate?

  /// The channel we are serving
  public internal(set) weak var channel: Channel!

  /// Port the server listens on
  public internal(set) var port: Int?

  public private(set) var state: ServerState = .unknown

  /// The socket we are listening on
  private var listenSocket: Socket? = nil

  /// Incoming socket handler
  private let connectionManager = ConnectionManager()

  /// Lifecycle manager for this server
  fileprivate let lifecycleManager = LifecycleManager()

  /// Maximum number of pending connections
  private let maxPendingConnections = 100

  /// Create a channel server
  ///
  /// - parameter port: The port for the server to listen on
  public convenience init(port: Int, serving channel: Channel) {
    self.init(serving: channel)
    self.port = port
  }

  init(serving channel: Channel) {
    self.channel = channel
    self.delegate = channel.delegate
  }

  /// Default initializer
  public init() {}

  /// Start the server
  public func start() {
    guard let port = self.port else { return }

    self.listen(port: port, errorHandler: { error in
      Log.error("An error occured: \(error)")
    })
  }

  /// Write a sequence of bytes in an UnsafeBufferPointer to the channel
  ///
  /// - parameter from: An UnsafeBufferPointer to the sequence of bytes to be written
  /// - parameter count: The number of bytes to write
  public func write(from buffer: UnsafeBufferPointer<UInt8>) {
  }

  /// Listen for connections on a socket.
  ///
  /// - parameter port: port number for new connections (eg. 8090)
  /// - parameter errorHandler: optional callback for error handling
  public func listen(port: Int, errorHandler: ((Swift.Error) -> ())? = nil) {
    self.port = port

    do {
      self.listenSocket = try Socket.create(family: .inet, type: .stream, proto: .tcp)
    } catch let error as Socket.Error {
      Log.error("Error creating socket reported: \(error.description)")
      _socketFailed(error: error)
    } catch {
      Log.error("Error creating socket: \(error)")
      _socketFailed(error: error)
    }

    guard let socket = self.listenSocket else { return }

    let queued = DispatchWorkItem(block: {
      do {
        try self.listen(socket: socket, port: port)
      } catch {
        if let callback = errorHandler {
          callback(error)
        } else {
          Log.error("Error listening on socket: \(error)")
        }

        self.state = .failed
        self.lifecycleManager.doFailureCallbacks(with: error)
      }
    })

    Vim.enqueueAsync(on: DispatchQueue.global(), block: queued)
  }

  /// Creates a new instance of `ChannelServer` and calls `listen(port:errorHandler:)` on
  /// the new instance.
  ///
  /// - parameter port: port number for new connections.
  /// - parameter errorHandler: optional callback to invoke when the server encounters an error
  /// - returns: A new instance of `ChannelServer`, that is listening on `port`
  public static func listen(port: Int,
                            delegate: ChannelDelegate,
                            errorHandler: ServerErrorHandler?) -> ChannelServer {
    let server = ChannelServer()
    server.delegate = delegate
    server.listen(port: port, errorHandler: errorHandler)
    return server
  }

  /// Handles a request coming from the client
  ///
  /// - parameter socket: The socket on which the request was made
  func handleClientRequest(socket clientSocket: Socket) {
    guard let delegate = self.delegate else { return }
    connectionManager.addConnection(forChannel: self.channel, on: clientSocket, using: delegate)
  }

  /// Send a vim command to the vim instance
  ///
  /// - parameter cmd: The command to send
  public func sendCommand(_ cmd: VimCommand) throws {
    // TODO: Implement
  }

  /// Stop listening for new connections
  public func stop() {
    defer { self.delegate = nil }

    guard let sock = self.listenSocket else { return }

    self.state = .stopped
    sock.close()
  }

  // MARK: Server Callback Management

  /// Add a callback to be invoked when the server is started
  ///
  /// - parameter callback: callback that will be invoked upon successful startup by the receiver
  /// - returns: the receiver of this call
  @discardableResult
  public func started(callback: @escaping () -> Void) -> Self {
    self.lifecycleManager.addStartupCallback(invokeNow: self.state == .stopped, callback)
    return self
  }

  /// Add a callback to be invoked when the server is stopped
  ///
  /// - parameter callback: callback that will be invoked upon stoppage by the receiver
  /// - returns: the receiver of this call
  @discardableResult
  public func stopped(callback: @escaping () -> Void) -> Self {
    self.lifecycleManager.addShutdownCallback(invokeNow: self.state == .stopped, callback)
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

  /// Handle instructions for listening on a socket
  ///
  /// - parameter socket: socket to use for connection
  /// - parameter port: port number to listen on
  private func listen(socket: Socket, port: Int) throws {
    do {
      try socket.listen(on: port, maxBacklogSize: maxPendingConnections)

      self.state = .started
      self.lifecycleManager.doStartupCallbacks()

      Log.info("Listening on port `\(port)`")

      repeat {
        let clientSock = try socket.acceptClientConnection()
        Log.info("Accepted connection from: \(clientSock.prettyHost)")
        addClientConnection(socket: clientSock)
      } while true

    } catch let error as Socket.Error {
      if self.state == .stopped && error.errorCode == Int32(Socket.SOCKET_ERR_ACCEPT_FAILED) {
        self.lifecycleManager.doShutdownCallbacks()
        Log.info("Server has stopped listening.")
      } else {
        throw error
      }
    }
  }
  
  /// Add a new connection
  private func addClientConnection(socket clientSocket: Socket) {
    // fail silently if we don't have a delegate
    guard let delegate = self.delegate else { return }
    connectionManager.addConnection(forChannel: self.channel, on: clientSocket, using: delegate)
  }

  /// Handler for failures
  private func _socketFailed(error: Swift.Error) {
    self.state = .failed
    self.lifecycleManager.doFailureCallbacks(with: error)
  }
}
