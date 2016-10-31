//
//  ConnectionManager.swift
//  VimChannelKit
//
//  Created by Morgan Lieberthal on 10/31/16.
//
//

import Dispatch
import Socket
import LoggerAPI

/// The `ConnectionManager` class is responsible for adding and removing 
/// connections to a server over a socket.
class ConnectionManager {
  /// A mapping of socket file descriptors to their associated `Connection`s
  private var connections = [Int32: Connection]()

  /// A Lock queue to guard access to the connection across threads
  private let lockQueue = DispatchQueue(label: "vim-channel.connection-manager.lock-queue")

  /// Add a connection, over a given socket
  ///
  /// - parameter socket: The socket over which the connection takes place
  func addConnection(over socket: Socket, using delegate: ServerDelegate? = nil) {
    do {
      try socket.setBlocking(mode: false)
      lockQueue.sync { [unowned self, socket] in
        let connection = Connection(socket: socket, using: delegate)
        self.connections[socket.socketfd] = connection
      }
    } catch {
      Log.error("Failed to make incoming socket (fd=\(socket.socketfd)) non-blocking.\n" +
                "Error code=\(errno), reason=\(strerror(errno)))")
    }
  }

  /// Close a connection and remove it from the manager
  ///
  /// - parameter connection: The connection to close and remove
  func removeConnection(connection: Connection) {
    removeConnection(fileDescriptor: connection.socketfd)
  }

  /// Close a connection for a given file descriptor, and remove it from the manager
  ///
  /// - parameter fileDescriptor: The file descriptor for the connection
  func removeConnection(fileDescriptor: Int32) {
    self.lockQueue.sync { [unowned self, fileDescriptor] in
      guard let cnx = self.connections[fileDescriptor] else { return }
      cnx.prepareToClose()
      self.connections.removeValue(forKey: fileDescriptor)
    }
  }
}

/// 'Swifty' wrapper around the C standard library function `strerror`
internal func strerror(_ errno: Int32 = errno) -> String {
  return String(validatingUTF8: strerror(errno)) ?? "Error: (\(errno))"
}
