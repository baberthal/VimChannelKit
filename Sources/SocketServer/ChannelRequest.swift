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
import Yajl

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

  /// The Yajl parser swift wrapper
  private var yajlParser: YajlParser?

  /// Client socket
  private var clientSocket: Socket

  /// Incoming message handling status
  private var status = MessageParserStatus()

  /// Chunk of message read in from the socket
  private var bodyChunk = BufferList()

  /// Buffer for parsing
  private var buffer = Data(capacity: ChannelRequest.bufferSize)

  // MARK: - Initializers
  
  /// Default initializer.
  ///
  /// - parameter type: The type (`MessageType`) of message we are handling.
  public init(socket: Socket) {
    self.clientSocket = socket
  }

  // MARK: - Functions

  /// Read data from the message into our abstraction
  ///
  /// - throws: Socket.Error if an error occured while reading the socket
  /// - returns: True if everything was successful
  @discardableResult
  func parse(_ buffer: NSData) -> MessageParserStatus {
    var length = buffer.length

    guard length > 0 else {
      status.error = .unexpectedEOF
      return status
    }

    if status.state == .reset {
      reset()
    }

    while status.state != .messageComplete && status.error == nil {
      let bytes = Data(referencing: buffer)

      let (id, bytesParsed) = self.execute(bytes)

      if id == 0 {
        status.error = .invalidJSON
        return status
      }

      self.id = id

      if bytesParsed != length {
        if self.status.state == .reset {
          self.reset()
        } else {
          self.status.error = .parsedTooFew
        }
      } else {
        self.status.state = .messageComplete
      }

      length -= bytesParsed
    }

    return status
  }

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
  public func readJSON() throws -> JSONRepresentable {
    buffer.count = 0

    let len = try read(into: &buffer)

    if len > 0 {
      return JSONRepresentable(data: buffer)!
    }

    return nil
  }

  func prepareReset() {
    status.state = .reset
  }

  // MARK: - Private Functions

  /// - returns: (ID, Number of Body Bytes)
  private func execute(_ data: Data) -> (Int, Int) {
    var result = (0, 0)

    do {
      let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)

      if let id = json[0].int {
        result.0 = id
      } else {
        self.status.error = .invalidJSON

        if let error = json.error {
          Log.error("Invalid JSON -- (\(error.localizedDescription): \(error.localizedFailureReason)")
        } else {
          Log.error("Invalid JSON")
        }
        return result
      }

      let bodyData = getRawData(json)

      result.1 = bodyData.count + 1 // to account for NULL terminator in the original string

      self.bodyChunk.append(data: bodyData)

    } catch let error as NSError {
      self.status.error = .invalidJSON
      Log.error("Invalid JSON Object. -- (\(error.code)): \(error.localizedDescription)")
    }
      
    return result
  }

  private func reset() {
    bodyChunk.reset()
    status.reset()
  }
}

extension ChannelRequest: YajlParserDelegate {

}
