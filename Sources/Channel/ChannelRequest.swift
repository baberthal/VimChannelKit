//
//  ChannelRequest.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/11/16.
//
//

import Foundation
import Socket
import LoggerAPI
import SwiftyJSON

/// This class is responsible for parsing incoming messages and encoding outgoing messages
///
public class ChannelRequest: ChannelReceivable {
  // MARK: - Static

  /// Default buffer size used for creating a BufferList.
  static let bufferSize = 2048

  // MARK: - Public 

  /// The `id` of the incoming or outgoing message
  public internal(set) var id: Int = 0

  /// The IP address of our remote host
  public var remoteAddress: String {
    return clientSocket.prettyHost
  }

  // MARK: - Private

  /// Client socket
  private var clientSocket: Socket

  /// Incoming message handling status
  private var status = MessageParserStatus()

  /// Chunk of message read in from the socket
  fileprivate var bodyChunk = BufferList()

  /// Buffer for parsing
  private var buffer = Data(capacity: ChannelRequest.bufferSize)

  /// helper for YajlParserDelegate
  fileprivate var hasSeenArray = false

  // MARK: - Initializers
  
  /// Default initializer.
  ///
  /// - parameter type: The type (`MessageType`) of message we are handling.
  public init(socket: Socket) {
    self.clientSocket = socket
  }

  // MARK: - Internal Functions

  /// Read data from the message into our abstraction
  ///
  /// - throws: Socket.Error if an error occured while reading the socket
  /// - returns: True if everything was successful
  @discardableResult
  func parse(_ buffer: NSData) -> MessageParserStatus {
    let length = buffer.length

    guard length > 0 else {
      status.error = .unexpectedEOF
      return status
    }

    if status.state == .reset {
      reset()
    }

    return status
  }

  func prepareReset() {
    status.state = .reset
  }

  func release() {
  }

  // MARK: - Public Functions

  /// Read a chunk of the body of the message.
  ///
  /// - parameter into: An NSMutableData to hold the data in the message.
  /// - throws: if an error occurs while reading the body.
  /// - returns: the number of bytes read.
  public func read(into data: inout Data) throws -> Int {
    let count = bodyChunk.fill(data: &data)
    return count
  }

  /// Read the whole body of the message.
  ///
  /// - parameter into: An NSMutableData to hold the data in the message.
  /// - throws: if an error occurs while reading the data.
  /// - returns: the number of bytes read.
  @discardableResult
  public func readAllData(into data: inout Data) throws -> Int {
    var length = try read(into: &data)
    var bytesRead = length

    while length > 0 {
      length = try read(into: &data)
      bytesRead += length
    }

    return bytesRead
  }

  /// Read a chunk of the body and return it as a string.
  ///
  /// - throws: if an error occurs while reading data.
  /// - returns: an optional string of the body
  public func readString() throws -> String? {
    buffer.count = 0
    let length = try read(into: &buffer)

    if length > 0 {
      return String(data: buffer, encoding: .utf8)
    }

    return nil
  }

  /// Read a chunk of the body and return it as JSON.
  ///
  /// - throws: if an error occurs while reading data.
  /// - returns: the json object of the body
  public func readJSON() throws -> JSON {
    buffer.count = 0

    let len = try read(into: &buffer)

    if len > 0 {
      let json = JSON(data: buffer)
      return json
    }

    return nil
  }

  // MARK: - Private Functions

  private func reset() {
    bodyChunk.reset()
    status.reset()
  }
}
