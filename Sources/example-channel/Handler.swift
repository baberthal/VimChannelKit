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
    } else if bodyString == "move" {
      channel.send(command: .normal(command: "w"))
    } else if bodyString == "evalexpr" {
      let command = VimCommand.expr("line('$')", id: -1)
      channel.send(command: command)
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
  
  /// The channel received a response to a command.
  ///
  /// - parameter channel: The channel that received the response.
  /// - parameter response: The response that the channel received.
  /// - parameter command: The command the response responded to.
  public func channel(_ channel: Channel, receivedResponse response: Message, to command: VimCommand) {
    Log.info("Received response: \(response) to command: \(command)")
  }
}
