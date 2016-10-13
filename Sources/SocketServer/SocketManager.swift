//
//  SocketManager.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/10/16.
//
//

import Dispatch
import Foundation
import LoggerAPI
import Socket

/// The SocketManager class is in charge of managing all of the incoming sockets.
/// In particular, it is in charge of:
///   1. Creating and managing the IncomingSocketHandlers and IncomingHTTPDataProcessors
///      (one pair per incoming socket)
///   2. Cleaning up idle sockets, when new incoming sockets arrive.
class SocketManager {
  /// A mapping from socket file descriptor to IncomingSocketHandler
  private var socketHandlers = [Int32: SocketHandler]()

  /// Handle a new incoming socket
  ///
  /// - parameter socket: the incoming socket to handle
  /// - parameter using: The ServerDelegate to actually handle the socket
  func handle(socket: Socket, using delegate: ChannelDelegate) {
    do {
      try socket.setBlocking(mode: false)

      let processor = VimSocketProcessor(socket: socket, using: delegate)
      let handler   = SocketHandler(socket: socket, using: processor, managedBy: self)
      socketHandlers[socket.socketfd] = handler

    } catch {
      Log.error("Failed to make incoming socket (fd=\(socket.socketfd)) non-blocking.\n" +
                "Error code=\(errno), reason=\(errorExplanation())")
    }
  }

  /// Private method to return the last error based on the value of errno.
  ///
  /// - Returns: String containing relevant text about the error.
  private func errorExplanation() -> String {
    return String(validatingUTF8: strerror(errno)) ?? "Error: \(errno)"
  }
}
