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
  private var connections = [Int32: Connection]()

  /// Add a connection on an incoming socket
  ///
  /// - parameter channel: The `Channel` associated with the connection
  /// - parameter socket: the incoming socket to add the connection on
  /// - parameter using: the ChannelDelegate to handle the connection 
  func addConnection(
    forChannel channel: Channel, on socket: Socket, using delegate: ChannelDelegate
    ) {
    do {
      try socket.setBlocking(mode: false)

      let processor  = MessageProcessor(channel: channel, using: delegate)
      
      let connection = Connection(socket: socket, using: processor, managedBy: self)

      connections[socket.socketfd] = connection
    } catch {
      Log.error("Failed to make incoming socket (fd=\(socket.socketfd)) non-blocking.\n" +
                "Error code=\(errno), reason=\(errorExplanation())")
    }
  }
}


fileprivate func errorExplanation() -> String {
  return String(validatingUTF8: strerror(errno)) ?? "Error: (\(errno))"
}
