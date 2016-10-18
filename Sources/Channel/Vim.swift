//
//  Vim.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/10/16.
//
//

import Dispatch
import SwiftyJSON

public final class Vim {
  /// This is really just a namespace...
  private init() {}

  /// Group for all of the listeners
  private static let group = DispatchGroup()

  /// Wait for all listeners to stop
  public static func waitForListeners() {
    _ = group.wait(timeout: DispatchTime.distantFuture)
  }

  /// Enqueue a block of code on a given queue, assigning it to the listener group
  /// in the process (so it can be waited on later).
  ///
  /// - parameter on: The queue on which `block` will be enqueued for async execution
  /// - parameter block: The block of code to enqueue
  public static func enqueueAsync(on queue: DispatchQueue, block: DispatchWorkItem) {
    queue.async(group: Vim.group, execute: block)
  }

  /// Create a new ChannelServer
  ///
  /// - parameter port: The port for the server to listen on
  /// - returns: a new ChannelServer
  public static func createChannel(port: Int? = nil) -> ChannelServer {
    if let port = port {
      return ChannelServer(port: port)
    }
    return ChannelServer()
  }
}
