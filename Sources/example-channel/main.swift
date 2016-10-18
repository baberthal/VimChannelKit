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
  public func channel(_ channel: Channel, didReceiveMessage message: ChannelRequest) {
  }

  /// Handle a new incoming request to the server
  ///
  /// - parameter incoming: The IncomingMessage class instance for this request
  /// - parameter outgoing: The OutgoingMessage class instance for this request
  public func handle(incoming: ChannelRequest, outgoing: ChannelResponse) {
  }
}

let port = 1337

let logger = TTYLogger(.verbose)
logger.colored = true

Log.logger = logger

Log.verbose("Swift Echo Server Example")
let prettyPort = "\(port)".colorize(.magenta)
Log.verbose("Connect with a terminal window by entering `telnet 127.0.0.1 \(prettyPort)`")

let handler = Handler()

let server = ChannelServer.listen(port: port, delegate: handler, onError: {
  Log.error("Error: \($0)")
})

dispatchMain()
