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
  /// A back reference to the `Connection` processing the socket that
  /// this `DataProcessor` is processing.
  public weak var connection: Connection?

  /// The `ChannelDelegate` that will handle the message post-processing
  public weak var delegate: ChannelDelegate?

  /// The `Channel` that the request came in on
  public weak var channel: Channel!

  /// The incoming request we are working with
  private let request: ChannelRequest

  /// An optional response to the request
  private var response: ChannelResponse!

  /// A flag that indicates that there is a request in progress
  public var inProgress = true

  /// An internal enum for state
  enum State {
    case initial, complete
  }

  /// The state of our processor
  private(set) var state: State = .initial

  /// Create a new `MessageProcessor`, communicating on `socket`, using `delegate`
  /// to handle the message.
  ///
  /// - parameter socket: The socket on which communications will take place
  /// - parameter channel: The channel the connection is taking place on
  /// - parameter using: The delegate to handle messages after processing
  public init(socket: Socket, channel: Channel, using delegate: ChannelDelegate) {
    self.delegate = delegate
    self.channel = channel
    self.request = ChannelRequest(socket: socket)
    self.response = ChannelResponse(processor: self)
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
    let parseStatus = self.request.parse(buffer)

    guard parseStatus.error == nil else {
      Log.error("Failed to parse the incoming data: \(parseStatus.error!)")
      return
    }

    switch parseStatus.state {
    case .initial: break
    case .messageComplete: parseComplete()
    case .reset: break
    }
  }

  private func parseComplete() {
    self.state = .complete
    response.reset()
    response.shouldRespondTo(request: self.request)

    DispatchQueue.global().async { [unowned self] in
      self.delegate?.channel(self.channel, didReceiveMessage: self.request.message)

      var msg = Message()
      msg.id = self.request.id

      guard let shouldRespond = self.delegate?.channel(self.channel,
                                                       shouldRespondTo: self.request.message,
                                                       with: &msg) else { return }

      if shouldRespond {
        self.response.body = msg.body
      }
    }
  }
}
