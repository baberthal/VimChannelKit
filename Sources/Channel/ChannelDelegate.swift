//
//  ChannelDelegate.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/11/16.
//
//

import SwiftyJSON

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
  /// - returns: an optional response body to send back to the client
  ///
  /// - seealso: `Channel.respondTo(message:with:)`
  @discardableResult
  func channel(_ channel: Channel, didReceiveMessage message: Message) -> JSON?

  /// The channel was opened.
  ///
  /// - parameter channel: The channel that was opened.
  func channelDidOpen(_ channel: Channel)
}
