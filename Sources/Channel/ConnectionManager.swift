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
  /// - parameter socket: the incoming socket to add the connection on
  /// - parameter using: the ChannelDelegate to handle the connection 
}
