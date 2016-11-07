//
//  Handler.swift
//  VimChannelKit
//
//  Created by Morgan Lieberthal on 10/30/16.
//
//

import Channel
import LoggerAPI
import SwiftyJSON

class Handler: ChannelDelegate {
  /// The handler's active channel.
  var activeChannel: Channel? = nil {
    didSet {
      Log.info("Added active channel: \(activeChannel)")
    }
  }

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
  public func channel(_ channel: Channel, didReceiveMessage message: Message) {
    Log.info("Channel: \(channel) didReceiveMessage: \(message)")
    
    guard let bodyString = message.body.string else {
      Log.error("Unable to get string from body of message")
      return
    }

    debugPrint("body string: ", bodyString)

    if bodyString == "hello!" {
      channel.respondTo(message: message, with: "got it!")
    }
  }
  
  /// The channel was opened.
  ///
  /// - parameter channel: The channel that was opened.
  public func channelDidOpen(_ channel: Channel) {
    guard self.activeChannel == nil else {
      Log.error("This handler already has an active channel!")
      return
    }

    self.activeChannel = channel
  }
}
