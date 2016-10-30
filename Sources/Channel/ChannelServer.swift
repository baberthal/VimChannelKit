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

/// A channel server for Vim
public class ChannelServer: ChannelBackend {
  /// ServerDelegate that will handle the request-response cycle
  public weak var delegate: ChannelDelegate?

  /// The channel we are serving
  public internal(set) weak var channel: Channel!

  /// Port the server listens on
  public internal(set) var port: Int?

  /// The socket we are listening on
  private var listenSocket: Socket? = nil

  /// True if the Server is currently listening, false otherwise
  internal var listening = false

  /// Incoming socket handler
  private let connectionManager = ConnectionManager()

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
  public init() { }

  /// Start the server
  public func start() {
    guard let port = self.port else { return }

    self.listen(port: port, errorHandler: { error in
      Log.error("An error occured: \(error)")
    })
  }

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
    } catch {
      Log.error("Error creating socket: \(error)")
    }

    guard let socket = self.listenSocket else { return }

    let queuedBlock = DispatchWorkItem(block: {
      do {
        try self.listen(socket: socket, port: port)
      } catch {
        if let callback = errorHandler {
          callback(error)
        } else {
          Log.error("Error listening on socket: \(error)")
        }
      }
    })

    Vim.enqueueAsync(on: DispatchQueue.global(), block: queuedBlock)
  }

  /// Handle instructions for listening on a socket
  ///
  /// - parameter socket: socket to use for connection
  /// - parameter port: port number to listen on
  func listen(socket: Socket, port: Int) throws {
    do {
      try socket.listen(on: port, maxBacklogSize: maxPendingConnections)
      Log.info("Listening on port \(port)")

      repeat {
        let clientSock = try socket.acceptClientConnection()
        Log.info("Accepted connection from: \(clientSock.remoteHostname):\(clientSock.remotePort)")

        self.handleClientRequest(socket: clientSock)
      } while true

    } catch let error as Socket.Error {
      if !listening && error.errorCode == Int32(Socket.SOCKET_ERR_ACCEPT_FAILED) {
        Log.info("Server has stopped listening.")
      } else {
        throw error
      }
    }
  }

  /// Handles a request coming from the client
  ///
  /// - parameter socket: The socket on which the request was made
  func handleClientRequest(socket clientSocket: Socket) {
    guard let delegate = self.delegate else { return }
    connectionManager.addConnection(forChannel: self.channel,
                                    on: clientSocket,
                                    using: delegate)
  }

  /// Send a vim command to the vim instance
  ///
  /// - parameter cmd: The command to send
  public func sendCommand(_ cmd: VimCommand) throws {

  }

  /// Stop listening for new connections
  public func stop() {
    if let listenSocket = self.listenSocket {
      self.listening = false
      listenSocket.close()
    }
  }
}
