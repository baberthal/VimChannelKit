//
//  main.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/5/16.
//
//

import Foundation
import SocketServer
import LoggerAPI
import Yajl

class Handler: ChannelDelegate {
  func handle(incoming: ChannelRequest, outgoing: ChannelResponse) {
    let incomingBody: JSON

    do {
      incomingBody = try incoming.readJSON()
    } catch let error {
      Log.error("Invalid JSON Object. -- \(error)")
      return
    }
    
    Log.verbose("Got incoming message: \(incomingBody)")

    if incomingBody.stringValue == "hello!" {
      Log.verbose("Writing outgoing message: \"got it!\"")
      do {
        try outgoing.write(from: "got it!")
        try outgoing.end()
      } catch let error {
        Log.error("error writing to socket: \(error)")
      }
    }
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
