// ChannelBackend.swift - Backend protocol for a Channel
//
// This source file is part of the VimChannelKit open source project
//
// Copyright (c) 2014 - 2016 
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// -----------------------------------------------------------------------------
///
/// This file contains the protocol definition for a channel backend
///
// -----------------------------------------------------------------------------

import struct Foundation.Data

/// The ChannelBackend protocol defines an interface for a channel to communicate.
protocol ChannelBackend: class {
  /// A reference to the `Channel` this `ChannelBackend` belongs to
  weak var channel: Channel? { get set }

  /// A reference to the `ChannelDelegate` this `ChannelBackend` serves
  weak var delegate: ChannelDelegate? { get }

  /// Start the backend
  func start()

  /// Stop the backend
  func stop()

  /// Write a sequence of bytes to the channel
  ///
  /// The default implementation simply forwards to `write(from:)`
  ///
  /// - parameter from: An UnsafePointer<UInt8> that contains the bytes to be written
  /// - parameter count: The number of bytes to write
  func write(from bytes: UnsafePointer<UInt8>, count: Int)

  /// Write a sequence of bytes in an UnsafeBufferPointer to the channel
  ///
  /// - parameter from: An UnsafeBufferPointer to the sequence of bytes to be written
  /// - parameter count: The number of bytes to write
  func write(from buffer: UnsafeBufferPointer<UInt8>)

  /// Write as much data to the socket as possible, buffering the rest
  ///
  /// The default implementation simply forwards to `write(from:)`
  ///
  /// - parameter data: The Data struct containing the bytes to write
  func write(from data: Data)

  /// Prepare to close the channel on the next cycle.
  func prepareToClose()
}
