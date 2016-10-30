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

  /// A back reference to the `Connection` processing the socket that
  /// this `DataProcessor` is processing.
  public weak var connection: Connection?

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
    case initial, complete
  }

  /// The state of our processor
  private(set) var state: State = .initial

  /// Create a new `MessageProcessor`, communicating on `socket`, using `delegate`
  /// to handle the message.
  ///
  /// - parameter channel: The channel the connection is taking place on
  /// - parameter using: The delegate to handle messages after processing
  public init(channel: Channel, using delegate: ChannelDelegate) {
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
    case .initial:
      inProgress = true
      parse(buffer)
      result = true

    case .complete:
      result = false
    }

    return result
  }

  public func write(from data: Data) {
    connection?.write(from: data)
  }

  public func write(from buffer: UnsafeBufferPointer<UInt8>) {
    connection?.write(buffer: buffer)
  }

  public func write(from bytes: UnsafeRawPointer, length: Int) {
    connection?.write(from: bytes, length: length)
  }

  public func close() {
    connection?.close()
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
      self.delegate?.channel(self.channel, didReceiveMessage: self.request)
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
