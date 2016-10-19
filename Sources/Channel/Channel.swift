//
//  Channel.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/11/16.
//
//

import Dispatch

// MARK: - Channel 

public class Channel {
  // MARK: - Public Properties
  
  /// The backend for our channel
  public internal(set) var backend: ChannelBackend!

  /// This channel's delegate 
  public weak var delegate: ChannelDelegate?

  /// The type of channel. (`.socket` or `.stream`)
  public let type: ChannelType

  /// An optional port, iff `type` is `.socket`. Otherwise, this is `nil`.
  public var port: Int? {
    get {
      guard self.type == .socket else { return nil }
      return self.server?.port
    }

    set {
      guard self.type == .socket else { return }
      guard let server = self.server else { return }
      server.port = newValue
    }
  }

  // MARK: - Private Properties 

  /// The server, if we are `.socket`.
  private var server: ChannelServer? {
    guard self.type == .socket else { return nil }
    return self.backend as? ChannelServer
  }

  /// The stream, if we are `.stream`.
  private var stream: ChannelStream? {
    guard self.type == .stream else { return nil }
    return self.backend as? ChannelStream
  }

  /// Initialize a channel, using a socket backend, which will listen on a given port
  ///
  /// - parameter port: The port for this channel's server to listen on
  public init(type: ChannelType, delegate: ChannelDelegate? = nil) {
    self.type = type
    self.delegate = delegate

    switch type {
    case .socket: self.backend = ChannelServer(serving: self)
    case .stream: self.backend = ChannelStream(serving: self)
    }
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
}

// MARK: - ChannelError

/// Represents an error that occurs during channel usage
public enum ChannelError: Swift.Error {
  /// The channel does not have a port
  case portNotSet
}

/// Describes the type of channel.
///
/// Channels can be created to use either a Socket or a Stream.
/// Stream channels operate over stdin/stdout, while Socket channels
/// operate over a Unix socket.
public enum ChannelType {
  /// A channel that communicates via a unix socket
  case socket
  /// A channel that communicates via stdin/stdout
  case stream
}

extension ChannelError: CustomStringConvertible {
  public var description: String {
    switch self {
    case .portNotSet:
      return "This channel has no port!  Please set the port before continuing."
    }
  }
}


// MARK: - Channel Static Functions

extension Channel {
  /// Create a new ChannelServer
  ///
  /// - returns: a new ChannelServer
  /// - postcondition: The new server does not have a port set
  public static func createServer() -> ChannelServer {
    return ChannelServer()
  }

  /// Create a socket channel, with a given `port` and `delegate`.
  ///
  /// - parameter port: the port to listen on
  /// - parameter delegate: the channel's delegate
  /// - returns: The newly created channel
  public static func socketChannel(port: Int, delegate: ChannelDelegate? = nil) -> Channel {
    let channel = Channel(type: .socket, delegate: delegate)
    channel.port = port
    return channel
  }

  public static func stdStreamChannel(delegate: ChannelDelegate? = nil) -> Channel {
    return Channel(type: .stream, delegate: delegate)
  }
}

// MARK: - ChannelBackend Protocol

/// The `ChannelBackend` protocol defines an interface such that the `Channel` class can 
/// perform channel operations in an agnostic way.
public protocol ChannelBackend: class {
  /// A reference to the `Channel` this `ChannelBackend` belongs to
  weak var channel: Channel! { get }

  /// A reference to the `ChannelDelegate` this `ChannelBackend` serves
  weak var delegate: ChannelDelegate? { get }

  /// Start the backend
  func start()

  /// Stop the backend
  func stop()
}
