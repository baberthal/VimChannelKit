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

/// The `MessageProcessor` class is responsible for processing data that is available
/// on a `ChannelBackend` and passing the processed data to the appropriate delegate for
/// handling.
public class MessageProcessor: DataProcessor {
  /// Default buffer size used for creating data buffers
  static let bufferSize = 2048

  // MARK: - Public Properties

  /// A back reference to the channel
  weak var channel: Channel!

  /// The channel's delegate
  weak var delegate: ChannelDelegate?

  /// A flag that indicates that there is a request in progress
  public var inProgress = true

  // MARK: - Private Properties
  
  /// The `ChannelBackend` that the request came in on
  weak var backend: ChannelBackend!

  /// The incoming request we are working with
  private var request = Message()

  /// An internal enum for state
  enum State {
    /// Reset to the initial state on the next pass
    case reset,
    /// The initial state
    initial,
    /// The message has been parsed successfully
    complete
  }

  /// The state of our processor
  private(set) var state: State = .initial

  /// Create a new `MessageProcessor`, communicating on `socket`, using `delegate`
  /// to handle the message.
  ///
  /// - parameter channel: The channel the connection is taking place on
  /// - parameter using: The delegate to handle messages after processing
  init(backend: ChannelBackend, using delegate: ChannelDelegate!) {
    self.delegate = delegate
    self.backend = backend
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
    backend.write(from: data)
  }

  /// Write a sequence of bytes in an array to the socket
  ///
  /// - parameter from: An UnsafeRawPointer to the sequence of bytes to be written to the socket.
  /// - parameter length: The number of bytes to write to the socket.
  public func write(from bytes: UnsafeRawPointer, length: Int) {
    backend.write(from: bytes.assumingMemoryBound(to: UInt8.self), count: length)
  }

  /// Write a sequence of bytes, from an unsafe buffer pointer to the socket
  public func write(from buffer: UnsafeBufferPointer<UInt8>) {
    backend.write(from: buffer)
  }
  
  /// Close the socket and MARK this handler as no longer in progress.
  public func close() {
    backend.prepareToClose()
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
      defer { self.state = .reset }

      if self.request.id > 0 {
        self.channel.delegate?.channel(self.channel, didReceiveMessage: self.request)
      } else if self.request.id < 0 {
        guard let command = self.channel.sentCommands.removeValue(forKey: self.request.id) else {
          Log.debug("Received message with id \(self.request.id), but did not send a command")
          return
        }

        self.channel.delegate?.channel(self.channel, receivedResponse: self.request, to: command)
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
