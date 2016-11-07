//
//  ConnectionManager.swift
//  VimChannelKit
//
//  Created by Morgan Lieberthal on 10/17/16.
//
//

import Dispatch
import Foundation
import LoggerAPI
import Socket

/// The `ConnectionManager` class is responsible for managing all incoming sockets.
class ConnectionManager {
  /// A mapping of socket file descriptors to their associated `Connection`s
  private var connections = [Int32: Channel]()

  /// A Lock queue to guard access to the connection across threads
  private let lockQueue = DispatchQueue(label: "vim-channel.connection-manager.lock-queue")

  /// Open a channel over a given socket.
  ///
  /// - parameter socket: The socket over which the channel will communicate.
  /// - parameter delegate: The delegate for the new channel.
  func openChannel(over socket: Socket, using delegate: ChannelDelegate) {
    do {
      try socket.setBlocking(mode: false)

      let backend = Connection(socket: socket, using: delegate, managedBy: self)
      let newChannel = Channel(backend: backend, delegate: delegate)
      backend.channel = newChannel
      
      lockQueue.sync { [unowned self, socket, newChannel] in
        self.connections[socket.socketfd] = newChannel
      }
    } catch {
      Log.error("Failed to make incoming socket (fd=\(socket.socketfd)) non-blocking.\n" +
                "Error code=\(errno), reason=\(errorExplanation())")
    }
  }
}


fileprivate func errorExplanation() -> String {
  return String(validatingUTF8: strerror(errno)) ?? "Error: (\(errno))"
}
