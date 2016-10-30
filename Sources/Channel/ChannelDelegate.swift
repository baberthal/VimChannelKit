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
  /// The channel received a request.
  ///
  /// To respond to a message, atopters of this protocol should do the following:
  ///
  /// ````
  /// func channel(_ channel: Channel, didReceiveMessage message: Message) {
  ///     // your logic here...
  ///     let response: JSON = ... // create the response
  ///     channel.respondTo(message: message, with: response)
  /// }
  ///
  /// ````
  ///
  /// - parameter channel: The channel that received the reqest (sender).
  /// - parameter message: The message that was received by the channel.
  ///
  /// - seealso: `Channel.respondTo(message:with:)`
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
