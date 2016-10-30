//
//  main.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/5/16.
//
//

import Foundation
import Channel
import LoggerAPI
import SwiftyJSON

class Handler: ChannelDelegate {
  /// The channel received a request.
  ///
  /// - parameter channel: The channel that received the reqest (sender).
  /// - parameter message: The message that was received by the channel.
  func channel(_ channel: Channel, didReceiveMessage message: Message) {
    Log.info("Channel: \(channel) didReceiveMessage: \(message)")
  }

  func channel(
    _ channel: Channel, shouldRespondTo message: Message, with response: inout Message
    ) -> Bool {
    Log.info("Channel: \(channel) shouldRespondTo: \(message), with: \(message)")
    return false
  }
}


let logger = TTYLogger(.verbose)
logger.colored = true

Log.logger = logger

let handler = Handler()

let channel = Channel.stdStreamChannel(delegate: handler)

Log.verbose("Swift Vim Channel Example -- Std. Streams")

channel.run()

//
//let port = 1337
//
//
//let prettyPort = "\(port)".colorize(.magenta)
//Log.verbose("Connect with a terminal window by entering `telnet 127.0.0.1 \(prettyPort)`")
//
////let server = ChannelServer.listen(port: port, delegate: handler, onError: {
////  Log.error("Error: \($0)")
////})
////
////dispatchMain()
