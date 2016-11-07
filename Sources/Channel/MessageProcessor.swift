//
//  MessageProcessor.swift
//  VimChannelKit
//
//  Created by Morgan Lieberthal on 10/18/16.
//
//

import Foundation
import Dispatch
import LoggerAPI
import Socket
import SwiftyJSON

public class MessageProcessor: DataProcessor {
  /// Default buffer size used for creating data buffers
  static let bufferSize = 2048

  // MARK: - Public Properties

  /// The `ChannelDelegate` that will handle the message post-processing
  public weak var delegate: ChannelDelegate?

  /// The `Channel` that the request came in on
  public weak var channel: Channel!

  /// A flag that indicates that there is a request in progress
  public var inProgress = true

  // MARK: - Private Properties

  /// The incoming request we are working with
  private var request = Message()

  /// An internal enum for state
  enum State {
    case reset, initial, complete
  }

  /// The state of our processor
  private(set) var state: State = .initial

  /// Create a new `MessageProcessor`, communicating on `socket`, using `delegate`
  /// to handle the message.
  ///
  /// - parameter channel: The channel the connection is taking place on
  /// - parameter using: The delegate to handle messages after processing
  public init(channel: Channel, using delegate: ChannelDelegate!) {
    self.delegate = delegate
    self.channel = channel
  }

  // MARK: - DataProcessor methods

  /// Process data read from the socket.
  ///
  /// - parameter buffer: An NSData object containing the data that was read in
  ///             and needs to be processed.
  /// - returns: true if the data was processed,
  ///            false if it needs to be processed later.
  public func process(_ buffer: Data) -> Bool {
    let result: Bool

    switch self.state {
    case .reset:
      self.request = Message()
      state = .initial
      fallthrough

    case .initial:
      inProgress = true
      parse(buffer)
      result = true

    case .complete:
      result = false
    }

    return result
  }
  
  /// Write data to the socket
  ///
  /// - parameter from: An NSData object containing the bytes to be written to the socket.
  public func write(from data: Data) {
    channel.write(from: data)
  }

  /// Write a sequence of bytes in an array to the socket
  ///
  /// - parameter from: An UnsafeRawPointer to the sequence of bytes to be written to the socket.
  /// - parameter length: The number of bytes to write to the socket.
  public func write(from bytes: UnsafeRawPointer, length: Int) {
    channel.write(from: bytes, length: length)
  }

  /// Write a sequence of bytes, from an unsafe buffer pointer to the socket
  public func write(from buffer: UnsafeBufferPointer<UInt8>) {
    channel.write(buffer: buffer)
  }
  
  /// Close the socket and MARK this handler as no longer in progress.
  public func close() {
    channel.prepareShutdown()
  }

  // MARK: - Private Helper Methods

  private func parse(_ buffer: Data) {
    func parseInternal() throws -> JSON {
      let length = buffer.count

      guard length > 0 else {
        throw Error.unexpectedEOF
      }

      let errorPointer: NSErrorPointer = nil
      let json = JSON(data: buffer, options: [.allowFragments], error: errorPointer)

      guard errorPointer == nil else {
        throw Error.invalidJSON(errorPointer)
      }

      return json
    }

    do {
      let json = try parseInternal()
      self.request.update(from: json)
      parseComplete()
    } catch let error as Error {
      Log.error(error.description)
    } catch {
      Log.error("Unexpected error: \(error)")
    }
  }

  private func parseComplete() {
    self.state = .complete

    DispatchQueue.global().async { [unowned self] in
      if let res = self.delegate?.channel(self.channel, didReceiveMessage: self.request),
             res != JSON.null {
        let response = Message(id: self.request.id, body: res)

        defer { self.state = .reset }

        do {
          let data = try response.rawData()
          self.write(from: data)
        } catch let error {
          Log.error("Error: \(error)")
        }
      }
    }
  }
}


extension MessageProcessor {
  /// An error that occurs while processing the message
  public enum Error: Swift.Error {
    /// Unexpectedly got EOF
    case unexpectedEOF
    /// A JSON object was invalid
    case invalidJSON(NSErrorPointer)
    /// An internal error occured
    case `internal`
  }
}

extension MessageProcessor.Error: CustomStringConvertible {
  public var description: String {
    switch self {
    case .unexpectedEOF:
      return "Unexpectedly got EOF while reading the request."
    case .invalidJSON(let e):
      return "Invalid json object. -- \(e!.pointee!.description)"
    case .internal:
      return "An internal error occured."
    }
  }
}
