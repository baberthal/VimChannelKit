//
//  ChannelDelegate.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/11/16.
//
//


/// The protocol defines the delegate interface for the Channel and ChannelServer.
///
/// The delegate's handle function is invoked when new requests arrive at the
/// server for processing.
public protocol ChannelDelegate: class {
  /// Handle a new incoming request to the server
  ///
  /// - parameter incoming: The IncomingMessage class instance for this request
  /// - parameter outgoing: The OutgoingMessage class instance for this request
  func handle(incoming: ChannelRequest, outgoing: ChannelResponse)
}
