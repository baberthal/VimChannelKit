//
//  SocketServer.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/5/16.
//
//

import Foundation
import Socket
import Dispatch
import LoggerAPI
import Yajl

/// A simple UNIX Socket Server
public class SocketServer {
  /// Quit the server when this is read from the input stream
  public static let quitCommand: String = "QUIT"
  /// Shutdown the server when this is read from the input stream
  public static let shutdownCommand: String = "SHUTDOWN"
  /// The size of the buffer
  public static let bufferSize = 4096
  
  /// Port the server listens on
  public let port: Int
  /// The socket we are listening on
  public var listenSocket: Socket? = nil
  /// True if we should continue running
  public var continueRunning = true
  /// A dictionary of connected sockets, by file descriptor
  var connectedSockets: [Int32: Socket] = [:]
  /// A lock queue for our sockets
  let socketLockQueue = DispatchQueue(label: "org.jmorgan.swiftSocketServer.socketLockQueue")
  
  /// Initialize a SocketServer, listening on a given port
  /// - parameter port: The port to listen on
  public init(port: Int) {
    self.port = port
  }
  
  /// Close all open sockets upon deinitialization
  deinit {
    // Close all our open sockets
    for socket in connectedSockets.values {
      socket.close()
    }
    
    self.listenSocket?.close()
  }
  
  /// The main loop for our socket server.
  /// - note: This function does not return, as it calls `dispatchMain()`
  public func run() {
    let queue = DispatchQueue.global(qos: .userInteractive)
    queue.async { [unowned self] in
      do {
        try self.listenSocket = Socket.create(family: .inet)
        
        guard let socket = self.listenSocket else {
          Log.error("Unable to unwrap socket...")
          return
        }
        
        try socket.listen(on: self.port)
        
        Log.info("Listening on port: \(socket.listeningPort)")
        
        repeat {
          let newSock = try socket.acceptClientConnection()
          Log.info("=== SOCKET OPENED ===")
          Log.info("Accepted connection from: \(newSock.prettyHost)")
          
          self.addConnection(socket: newSock)
          
        } while self.continueRunning
        
      } catch let error {
        guard let socketError = error as? Socket.Error else {
          Log.error("Unexpected error...")
          return
        }
        
        if self.continueRunning {
          Log.error("Error encountered:\n \(socketError.description)")
        }
      }
    }
    
    dispatchMain()
  }
  
  /// Add a connection to this server.
  /// - parameter socket: The socket on which the new connection is connected
  internal func addConnection(socket: Socket) {
    socketLockQueue.sync { [unowned self, socket] in
      self.connectedSockets[socket.socketfd] = socket
    }
    
    let queue = DispatchQueue.global(qos: .default)
    
    queue.async { [unowned self, socket] in
      var shouldKeepRunning = true
      var readData = Data(capacity: SocketServer.bufferSize)
      
      do {
        repeat {
          let bytesRead = try socket.read(into: &readData)
          if bytesRead > 0 {
            
            guard let message = VimMessage(data: readData) else {
              Log.error("Error decoding JSON response...")
              readData.count = 0
              break
            }
            
            debugPrint(message)
            
            if let bodyString = message.bodyString, bodyString.hasPrefix("hello") {
              let reply = VimMessage(message.id, body: .string("got it!"))
              let replyData = try reply.rawData()
              Log.info("Replying with: \(reply.toJSON())")
              try socket.write(from: replyData)
            }
            
            guard let response = String(data: readData, encoding: .utf8) else {
              Log.error("Error decoding response...")
              readData.count = 0
              break
            }
            
            if response.hasPrefix(SocketServer.shutdownCommand) {
              Log.warning("Shutdown requested by connection at \(socket.prettyHost)")
              self.shutdownServer()
              return
            }
            
            Log.info("Server received connection at \(socket.prettyHost) : \(response)")
            let reply = "Server Response: \n\(response)\n"
            try socket.write(from: reply)
            
            if (response.uppercased().hasPrefix(SocketServer.quitCommand) ||
              response.uppercased().hasPrefix(SocketServer.shutdownCommand)) &&
              (!response.hasPrefix(SocketServer.quitCommand) &&
                !response.hasPrefix(SocketServer.shutdownCommand)) {
              
              try socket.write(from: "If you want to QUIT or SHUTDOWN, please type the name in all caps.\n")
            }
            
            if response.hasPrefix(SocketServer.quitCommand) || response.hasSuffix(SocketServer.quitCommand) {
              shouldKeepRunning = false
            }
          }
          
          if bytesRead == 0 {
            shouldKeepRunning = false
            break
          }
          
          readData.count = 0
        } while shouldKeepRunning
        
        Log.info("Socket: \(socket.prettyHost) closed...")
        socket.close()
        
        self.socketLockQueue.sync { [unowned self, socket] in
          self.connectedSockets[socket.socketfd] = nil
        }
      } catch let error {
        guard let socketError = error as? Socket.Error else {
          Log.error("Unexpected error: \(error)")
          return
        }
        
        if self.continueRunning {
          Log.error("Error encountered by connection at \(socket.prettyHost)")
          Log.error("\(socketError.description)")
        }
      }
    }
  }

  /// Shutdown the server
  public func shutdownServer() {
    Log.warning("Shutdown in progress...")
    continueRunning = false
    
    for socket in connectedSockets.values {
      socket.close()
    }
    
    listenSocket?.close()
    
    DispatchQueue.main.sync {
      exit(0)
    }
  }
}
