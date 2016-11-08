// Channel.swift - A Vim Channel
//
// This source file is part of the VimChannelKit open source project
//
// Copyright (c) 2014 - 2016 
// Licensed under Apache License v2.0 with Runtime Library Exception
//

import Dispatch
import SwiftyJSON
import struct Foundation.Data
import LoggerAPI

// MARK: - Channel

/// Represents a VimChannel, used to communicate with a running Vim instance, 
/// either via `stdio` streams, or a socket connection.
public class Channel {
  // MARK: - Properties

  /// This channel's delegate
  public weak var delegate: ChannelDelegate?
  
  /// The backend for our channel
  let backend: ChannelBackend

  /// Keeps track of registered servers, but does not hold a reference to them.
  fileprivate static var registeredServers = [(server: Unmanaged<Server>, port: Int)]()

  /// Keeps track of stdio channels, but does not hold a reference to them.
  fileprivate static var registeredStdioChannels = [Unmanaged<Channel>]()

  // MARK: - Initializers

  /// Initialize a channel, using a socket backend, which will listen on a given port
  ///
  /// - parameter port: The port for this channel's server to listen on
  init(backend: ChannelBackend, delegate: ChannelDelegate? = nil) {
    self.backend = backend
    self.delegate = delegate
    self.backend.channel = self
  }

  /// Start the channel
  public func start() {
    self.backend.start()
  }

  /// Stop the channel
  public func stop() {
    self.backend.stop()
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
    do {
      let data = try command.rawData()
      self.backend.write(from: data)
    } catch let error {
      Log.error("Error sending command: \(command) -- \(error.localizedDescription)")
    }
  }
}

// MARK: - Static Methods

extension Channel {
  /// Creates a Channel Server, which will serve over `port`.
  ///
  /// - parameter port: The port for the server to listen on.
  /// - parameter delegate: The delegate to use for any subsequently opened channels.
  ///
  /// - returns: A new `Server` which is configured to listen on `port`.
  public static func createServer(port: Int, with delegate: ChannelDelegate) -> Server {
    let server = Server(port: port, delegate: delegate)
    self.registeredServers.append((server: Unmanaged.passUnretained(server), port: port))
    return server
  }

  /// Creates a Channel that works over `stdio` streams.
  ///
  /// - parameter delegate: The delegate to use for the returned channel.
  ///
  /// - returns: A new `Channel` instance, suitable for communicating via `stdin` and `stdout`.
  public static func createStdioChannel(using delegate: ChannelDelegate) -> Channel {
    let backend = ChannelStream(delegate: delegate)
    let channel = Channel(backend: backend, delegate: delegate)
    self.registeredStdioChannels.append(Unmanaged.passUnretained(channel))
    return channel
  }

  /// Start all registered channels, and continue running indefinitely.
  ///
  /// This method never returns, so make sure it is the last line in your `main.swift` file.
  public static func run() -> Never {
    start()
    Server.ListenerGroup.waitForListeners()
    dispatchMain()
  }

  /// Start all registered channels and return.
  ///
  /// All registered servers will now listen on their specified `port`, and
  /// `stdio` channels will begin polling for data.
  public static func start() {
    for (server, port) in registeredServers {
      Log.verbose("Channel Server is listening on port: \(port)")
      server.takeUnretainedValue().listen()
    }

    for stream in registeredStdioChannels {
      stream.takeUnretainedValue().start()
    }
  }

  /// Stop all registered servers and channels and return.
  ///
  /// Servers will no longer listen for connections, and stream channels will stop.
  public static func stop() {
    for (server, port) in registeredServers {
      Log.verbose("Channel Server is listening on port: \(port)")
      server.takeUnretainedValue().stop()
    }

    for stream in registeredStdioChannels {
      stream.takeUnretainedValue().stop()
    }
  }
}
