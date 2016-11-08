// Server.swift - A channel server
//
// This source file is part of the VimChannelKit open source project
//
// Copyright (c) 2014 - 2016 
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// -----------------------------------------------------------------------------
///
/// This file contains the basic channel server, which uses the TCP protocol.
///
// -----------------------------------------------------------------------------

import Dispatch

import Socket
import LoggerAPI

// MARK: Server

/// The `Server` class is a basic TCP Socket Server implementation that can be used to
/// create channels to Vim.
public class Server {
  // MARK: - Properties

  /// The port the server will listen on.
  public let port: Int

  /// The state of this `Server`
  public internal(set) var state: State = .unknown

  /// This server's delegate.
  public weak var delegate: ChannelDelegate? = nil

  /// The socket this server is listening on.
  private var listeningSocket: Socket? = nil

  /// The manager that will manage incoming connections for this server.
  private let connectionManager = ConnectionManager()

  /// The lifecycle manager that will invoke callbacks based on this server's lifecycle.
  private let lifecycleManager = ServerLifecycleManager()

  /// The maximum number of connections to allow in the backlog.
  private let maxPendingConnections = 100

  // MARK: - Initializers

  /// Create a server.
  ///
  /// - parameter port: The port for the server to listen on.
  init(port: Int, delegate: ChannelDelegate? = nil) {
    self.port = port
    self.delegate = delegate
  }

  // MARK: - Methods

  /// Listen for connections on a socket.
  ///
  /// - parameter errorHandler: The callback to invoke if an error occurs while
  ///   creating the socket.
  @discardableResult
  public func listen(errorHandler: ((Swift.Error) -> Void)? = nil) -> Self {
    do {
      self.listeningSocket = try Socket.create(family: .inet, type: .stream, proto: .tcp)
    } catch let error as Socket.Error {
      Log.error("Error creating socket: \(error)")
      _socketFailure(error: error)
    } catch {
      Log.error("Unknown error: \(error)")
      _socketFailure(error: error)
    }

    // Make sure we have a socket.  The error should be handled by `errorHandler`
    // or the `lifecycleManager`.
    guard let socket = self.listeningSocket else { return self }

    let queuedBlock = DispatchWorkItem(block: {
      do {
        try self.listen(socket: socket)
      } catch {
        errorHandler?(error)
        self.state = .failed
        self.lifecycleManager.invokeFailureCallbacks(withError: error)
      }
    })

    ListenerGroup.enqueueAsync(on: DispatchQueue.global(), block: queuedBlock)

    return self
  }

  /// Stop listening for new connections.
  public func stop() {
    defer { self.delegate = nil }

    if let listeningSocket = self.listeningSocket {
      self.state = .stopped
      listeningSocket.close()
    }
  }

  /// Add a callback to be invoked when the server is started
  ///
  /// - parameter callback: callback that will be invoked upon successful startup by the receiver
  /// - returns: the receiver of this call
  @discardableResult
  public func onStartup(_ callback: @escaping () -> Void) -> Self {
    self.lifecycleManager.addStartupCallback(invokeNow: self.state == .stopped, callback)
    return self
  }

  /// Add a callback to be invoked when the server is stopped
  ///
  /// - parameter callback: callback that will be invoked upon stoppage by the receiver
  /// - returns: the receiver of this call
  @discardableResult
  public func onShutdown(_ callback: @escaping () -> Void) -> Self {
    self.lifecycleManager.addShutdownCallback(invokeNow: self.state == .stopped, callback)
    return self
  }

  /// Add a callback to be invoked when the server encounters an error
  ///
  /// - parameter callback: callback that will be invoked when the receiver encounters an error
  /// - returns: the receiver of this call
  @discardableResult
  public func onFailure(_ callback: @escaping (Swift.Error) -> Void) -> Self {
    self.lifecycleManager.addFailureCallback(callback)
    return self
  }

  /// Add a callback to be invoked when the server has received a specific Unix signal.
  ///
  /// - parameter signal: The signal to listen for.
  /// - parameter callback: callback that will be invoked when the receiver encounters `signal`
  /// - returns: the receiver of this call
  @discardableResult
  public func onSignal(_ signal: Signal, _ callback: @escaping () -> Void) -> Self {
    self.lifecycleManager.addDispatchSignalHandler(forSignal: signal, callback)
    return self
  }

  // MARK: - Private

  /// Listen
  private func listen(socket: Socket) throws {
    do {
      try socket.listen(on: self.port, maxBacklogSize: self.maxPendingConnections)

      self.state = .started
      self.lifecycleManager.invokeStartupCallbacks()

      Log.info("Server is listening on port \(self.port)")

      repeat {
        let clientSocket = try socket.acceptClientConnection()
        Log.info("Accepted connection from: \(clientSocket.prettyHost)")
        self.openChannel(on: clientSocket)
      } while true

    } catch let error as Socket.Error {
      if self.state == .stopped && error.errorCode == Int32(Socket.SOCKET_ERR_ACCEPT_FAILED) {
        self.lifecycleManager.invokeShutdownCallbacks()
        Log.info("Server has stopped listening.")
      } else {
        throw error
      }
    }
  }
  
  /// Handler for a failure creating the socket.
  private func _socketFailure(error: Swift.Error) {
    self.state = .failed
    self.lifecycleManager.invokeFailureCallbacks(withError: error)
  }

  /// Open a new channel on a given socket.
  private func openChannel(on socket: Socket) {
    guard let delegate = self.delegate else { return }
    self.connectionManager.openChannel(over: socket, using: delegate)
  }
}

// MARK: - Server State

extension Server {
  /// Represents the state of a `Server`.
  public enum State {
    /// No state information is available.
    case unknown

    /// The server has started successfully.
    case started

    /// The server has stopped successfully.
    case stopped

    /// The server failed somehow.
    case failed
  }
}
