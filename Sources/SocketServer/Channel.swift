//
//  Channel.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/11/16.
//
//

// MARK: - Channel 

public final class Channel {
  /// The server for our channel
  public let server: ChannelServer

  /// The port this channel will listen on
  public let port: Int

  /// This channel's delegate 
  public weak var delegate: ChannelDelegate?

  /// Initialize a channel, which will listen on a given port
  ///
  /// - parameter port: The port for this channel's server to listen on
  public init(port: Int) {
    self.port = port
    self.server = ChannelServer(port: port)
  }
}

// MARK: - ChannelError

/// Represents an error that occurs during channel usage
public enum ChannelError: Swift.Error {
  /// The channel does not have a port
  case portNotSet
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
}
