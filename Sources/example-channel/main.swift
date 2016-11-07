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

Log.verbose("Swift Vim Channel Example")

let port = 1337
Log.verbose("Listening on port \(port)")

let server = Server(port: port, delegate: handler)

server.listen(errorHandler: { error in
  Log.error("An error occured opening the socket: \(error)")
})

dispatchMain()
