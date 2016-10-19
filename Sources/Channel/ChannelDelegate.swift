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

  /// The channel received a request.
  ///
  /// - parameter channel: The channel that received the reqest (sender).
  /// - parameter message: The message that was received by the channel.
  func channel(_ channel: Channel, didReceiveMessage message: Message)

  /// The channel received a request. To respond to the request, return true from this
  /// function.
  ///
  /// - parameter channel: The channel on which the request was received
  /// - parameter message: The message that was received by the channel
  /// - parameter response: An optional response to the message. 
  ///             This will be ignored if this method returns `false`.
  /// - returns: `true` if the response should be sent, `false` otherwise.
  func channel(_ channel: Channel, shouldRespondTo message: Message,
               with response: inout Message) -> Bool
}
