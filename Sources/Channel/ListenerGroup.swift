// ListenerGroup.swift - Listens for socket events
//
// This source file is part of the VimChannelKit open source project
//
// Copyright (c) 2014 - 2016 
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// -----------------------------------------------------------------------------
///
/// The `ListenerGroup` enqueues blocks for listening on sockets.
///
// -----------------------------------------------------------------------------

import Dispatch

extension Server {
  final class ListenerGroup {
    /// This is really just a namespace, so no initializer.
    private init() {}

    /// Dispatch group for all listeners.
    private static let group = DispatchGroup()

    /// Wait for all listeners in this group.
    public static func waitForListeners() {
      _ = group.wait(timeout: .distantFuture)
    }

    /// Enqueue a block of code on a given queue, assigning it to the listener group
    /// in the process (so it can be waited on later).
    ///
    /// - parameter on: The queue on which `block` will be enqueued for async execution.
    /// - parameter block: The block of code to enqueue.
    public static func enqueueAsync(on queue: DispatchQueue, block: DispatchWorkItem) {
      queue.async(group: self.group, execute: block)
    }
  }
}
