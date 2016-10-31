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

let logger = TTYLogger(.verbose)
Log.logger = logger

let handler = Handler()

var usingSocket = false

if CommandLine.arguments.count > 1 {
  if let theArg = CommandLine.arguments.last, theArg == "--socket" {
    usingSocket = true
  }
}

Log.verbose("Swift Vim Channel Example -- " + (usingSocket ? "socket" : "stdio"))

let channel: Channel

if usingSocket {
  let port = 1337
  Log.verbose("Listening on port \(port)")
  channel = Channel.socketChannel(port: port, delegate: handler)
} else {
  channel = Channel.stdioChannel(delegate: handler)
}

Log.verbose("Swift Vim Channel Example -- stdio")

channel.run()
