//
//  Handler.swift
//  VimChannelKit
//
//  Created by Morgan Lieberthal on 10/30/16.
//
//

import Channel
import LoggerAPI

class Handler: ChannelDelegate {
  /// The channel received a request.
  ///
  /// - parameter channel: The channel that received the reqest (sender).
  /// - parameter message: The message that was received by the channel.
  func channel(_ channel: Channel, didReceiveMessage message: Message) {
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

  func channel(
    _ channel: Channel, shouldRespondTo message: Message, with response: inout Message
    ) -> Bool {
    Log.info("Channel: \(channel) shouldRespondTo: \(message), with: \(message)")
    return false
  }
}
