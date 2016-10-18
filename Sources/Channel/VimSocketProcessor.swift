//
//  VimSocketProcessor.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/6/16.
//
//

import Foundation
import Dispatch
import LoggerAPI
import Socket

public class VimSocketProcessor: IncomingDataProcessor {
  /// A back reference to the `IncomingSocketHandler` processing the socket that
  /// this `IncomingDataProcessor` is processing.
  public weak var handler: SocketHandler?

  /// The server delegate
  private weak var delegate: ChannelDelegate?

  /// The request we are handling
  private let request: ChannelRequest

  /// The `ServerResponse` object used to enable the `ServerDelegate` to
  /// respond to the incoming request
  /// - note: This var is optional to enable it to be constructed in the init function
  private var response: ChannelResponse!

  /// A flag that indicates that there is a request in progress
  public var inProgress = true

  /// The number of remaining requests that will be allowed on the socket 
  /// being handled by this handler
  private(set) var numberOfRequests = 100

  /// An enum for internal state
  enum State {
    case reset, initial, messageRead
  }

  /// The state of the Processor
  private(set) var state: State = .initial

  /// Create a new socket processor
  public init(socket: Socket, using delegate: ChannelDelegate) {
    self.delegate = delegate
    self.request = ChannelRequest(socket: socket)
    self.response = ChannelResponse(processor: self)
  }

  /// Process data read from the socket.
  ///
  /// - Parameter buffer: An NSData object containing the data that was read in
  ///                    and needs to be processed.
  ///
  /// - Returns: true if the data was processed, false if it needs to be processed later.
  public func process(_ buffer: Data) -> Bool {
    let result: Bool

    switch self.state {
    case .reset:
      request.prepareReset()
      state = .initial
      fallthrough

    case .initial:
      inProgress = true
      parse(buffer)
      result = true

    case .messageRead:
      result = false
    }

    return result
  }

  /// Write data to the socket
  ///
  /// - parameter from: An NSData object containing the bytes to be written to the socket.
  public func write(from data: NSData) {
    handler?.write(from: data)
  }

  /// Write a sequence of bytes in an array to the socket
  ///
  /// - parameter from: An UnsafeRawPointer to the sequence of bytes to be written to the socket.
  /// - parameter length: The number of bytes to write to the socket.
  public func write(from bytes: UnsafeRawPointer, length: Int) {
    handler?.write(from: bytes, length: length)
  }

  /// Close the socket and mark this handler as no longer in progress.
  public func close() {
    handler?.prepareToClose()
  }

  /// Parses the data from the incoming request
  private func parse(_ data: Data) {
    let parseStatus = self.request.parse(data as NSData)

    // Log and bail if we got an error. No use throwing here.
    guard parseStatus.error == nil else {
      Log.error("Failed to parse the incoming message. \(parseStatus.error!)")
      return
    }

    switch parseStatus.state {
    case .initial: break
    case .messageComplete: parseComplete()
    case .reset: break
    }
  }

  private func parseComplete() {
    self.state = .messageRead
    response.reset()
    response.id = request.id
    DispatchQueue.global().async { [unowned self] in
      self.delegate?.handle(incoming: self.request, outgoing: self.response)
    }
  }
}
