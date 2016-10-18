//
//  ChannelResponse.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/11/16.
//
//

import Foundation
import SwiftyJSON

/// This class implements the `ChannelSendable` protocol for outgoing responses
/// to a `ChannelRequest`.
public class ChannelResponse: ChannelSendable {
  // MARK: - Properties

  /// Default buffer size used for creating a BufferList
  private static let bufferSize = 4096

  /// Buffer for the response
  private var buffer: NSMutableData

  /// Corresponding socket processor
  private weak var processor: VimSocketProcessor?

  /// ID of the message we are responding to
  public var id: Int!

  // MARK: - Initializers

  /// Initialize with a VimSocketProcessor, in response to a message
  ///
  /// - parameter processor: The corresponding VimSocketProcessor
  /// - parameter respondingTo: The request we are responding to
  init(processor: VimSocketProcessor) {
    self.processor = processor
    self.buffer = NSMutableData(capacity: ChannelResponse.bufferSize) ?? NSMutableData()
  }

  // MARK: - Public Methods 
  
  /// Add a string to the body of the HTTP response.
  ///
  /// - parameter string: The String data to be added.
  /// - throws: Socket.error if an error occurred while writing to the socket
  public func write(from string: String) throws {
    try writeToSocketViaBuffer(text: string)
  }

  /// Add bytes to the body of the HTTP response.
  ///
  /// - parameter data: The Data struct that contains the bytes to be added.
  /// - throws: Socket.error if an error occurred while writing to the socket
  public func write(from data: Data) throws {
    guard let processor = self.processor else { return }

    if buffer.length + data.count > ChannelResponse.bufferSize && buffer.length != 0 {
      processor.write(from: buffer)
      buffer.length = 0
    }

    if data.count > ChannelResponse.bufferSize {
      let dataToWrite = NSData(data: data)
      processor.write(from: dataToWrite)
    } else {
      buffer.append(data)
    }
  }

  /// Add JSON to the body of the HTTP response.
  ///
  /// - parameter json: The JSON struct that contains the data to be added.
  /// - throws: Socket.error if an error occurred while writing to the socket
  public func write(from json: JSON) throws {
    let message: JSON = [self.id, json]
    
    let jsonData = try message.rawData()
    try write(from: jsonData)
  }

  /// Complete sending the HTTP response
  ///
  /// - throws: Socket.error if an error occurred while writing to a socket
  public func end() throws {
    guard let processor = self.processor else { return }

    if buffer.length > 0 {
      processor.write(from: buffer)
    }
  }

  /// Reset this response object back to it's initial state
  public func reset() {
    self.buffer.length = 0
  }

  // MARK: - Private Methods
  
  private func writeToSocketViaBuffer(text: String) throws {
    guard let processor = self.processor else { return }

    // get the number of bytes and bytes, using utf8
    let utf8len = text.lengthOfBytes(using: .utf8)
    var utf8 = [Int8](repeating: 0, count: utf8len + 10) // some padding

    // make sure we can getCString
    guard text.getCString(&utf8, maxLength: utf8len + 10, encoding: .utf8) else {
      return
    }

    if buffer.length + utf8.count > ChannelResponse.bufferSize && buffer.length != 0 {
        processor.write(from: buffer)
        buffer.length = 0
    }

    if utf8.count > ChannelResponse.bufferSize {
      processor.write(from: utf8, length: utf8len)
    } else {
      buffer.append(UnsafePointer(utf8), length: utf8len)
    }
  }
}
