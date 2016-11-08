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
logger.colored = true
Log.logger = logger

let handler = Handler()

Log.verbose("Swift Vim Channel Example")

let port = 1337
Log.verbose("Listening on port \(port)")

let server = Channel.createServer(port: port, with: handler)

server.listen(errorHandler: { error in
  Log.error("An error occured opening the socket: \(error)")
})

Channel.run()
