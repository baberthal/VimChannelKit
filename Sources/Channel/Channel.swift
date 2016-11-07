//
//  Channel.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/11/16.
//
//

import Dispatch
import SwiftyJSON
import struct Foundation.Data
import LoggerAPI

// MARK: - Channel

/// Represents a VimChannel, used to communicate with a running Vim instance, 
/// either via `stdio` streams, or a socket connection.
public class Channel {
  // MARK: - Public Properties

  /// The backend for our channel
  let backend: ChannelBackend

  /// This channel's delegate
  public weak var delegate: ChannelDelegate?

  // MARK: - Initializers

  /// Initialize a channel, using a socket backend, which will listen on a given port
  ///
  /// - parameter port: The port for this channel's server to listen on
  init(backend: ChannelBackend, delegate: ChannelDelegate? = nil) {
    self.backend = backend
    self.delegate = delegate
  }

  /// Start the channel
  public func start() {
    self.backend.start()
  }

  /// Stop the channel
  public func stop() {
    self.backend.stop()
  }

  /// Run the channel indefinitely. This function never returns,
  /// so make sure everything is set up before calling it.
  ///
  /// - precondition: If the channel is type `.socket`, the port must have been set.
  public func run() -> Never {
    start()
    dispatchMain()
  }

  /// Send a response to a message
  ///
  /// - parameter message: the message the `Channel` should respond to
  /// - parameter body: The body of the response message
  ///
  /// - seealso: `respondTo(message:withMessage:)`
  public func respondTo(message: Message, with body: JSON) {
    let response = Message(id: message.id, body: body)
    respondTo(message: message, withMessage: response)
  }

  /// Send a response to a message
  ///
  /// - parameter message: the message the `Channel` should respond to
  /// - parameter body: The body of the response message
  ///
  /// - precondition: `withMessage.id == message.id`
  ///
  /// - seealso: `respondTo(message:with:)`
  public func respondTo(message: Message, withMessage response: Message) {
    do {
      let data = try response.rawData()
      self.backend.write(from: data)
    } catch let error {
      Log.error("Error sending message with id \(message.id): \(error)")
    }
  }

  /// Send a command over the channel.
  /// 
  /// - parameter command: The command to send.
  ///
  /// - seealso: `VimCommand`
  public func send(command: VimCommand) {
  }
}
