//
//  ChannelStream.swift
//  VimChannelKit
//
//  Created by Morgan Lieberthal on 10/18/16.
//
//

import Dispatch
import Foundation
import LoggerAPI
import Socket

// MARK: - ChannelStream

/// A `ChannelBackend` implementation for channels that communicate via
/// `stdio` streams.
public class ChannelStream: ChannelBackend {
  /// The `low-water` mark for our input channel. All received messages should
  /// be a vaild JSON array, so we look for a string at least as long as `"[]"`.
  public static let ioLowWater = "[]".lengthOfBytes(using: .utf8)

  /// Dispatch queue for writing to our output stream
  static let writeQueue = DispatchQueue(label: "vim-channel.channel-stream-writer")

  /// Dispatch queues for reading from sockets
  static let readQueue = DispatchQueue(label: "vim-channel.channel-stream-reader")

  // MARK: - Properties

  /// The associated data processor
  public var processor: MessageProcessor!

  /// The owning Channel instance
  public weak var channel: Channel? {
    didSet {
      self.processor.channel = channel
    }
  }

  /// The input DispatchIO stream for communication
  private var inputStream: DispatchIO!

  /// The output DispatchIO stream for communication
  private var outputStream: DispatchIO!

  /// A buffer for input
  private var inputBuffer: DispatchData!

  // MARK: - Initializers

  /// Internal designated initializer
  init(delegate: ChannelDelegate) {
    self.processor = MessageProcessor(backend: self, using: delegate)
    self.inputStream  = createDispatchIO(for: STDIN_FILENO, cleanupHandler: self.cleanupHandler)
    self.outputStream = createDispatchIO(for: STDOUT_FILENO, cleanupHandler: self.cleanupHandler)
  }

  // MARK: - Public Methods

  public func start() {
    self.inputStream.read(offset: 0, length: Int.max, queue: DispatchQueue.global(), ioHandler: {
      [unowned self] (done, data, err) in
        self.ioReadHandler(done: done, data: data, errorCode: err)
    })
  }

  public func stop() {
    if let inputStream = self.inputStream {
      inputStream.close()
    }
  }

  func prepareToClose() {
    // Don't need to do anything special here
    stop()
  }

  /// Write a sequence of bytes in an UnsafeBufferPointer to the channel
  ///
  /// - parameter from: An UnsafeBufferPointer to the sequence of bytes to be written
  /// - parameter count: The number of bytes to write
  public func write(from buffer: UnsafeBufferPointer<UInt8>) {
    let data = DispatchData(bytes: buffer)
    self.write(data: data)
  }

  /// Write a sequence of bytes to the channel
  ///
  /// The default implementation simply forwards to `write(from:)`
  ///
  /// - parameter from: An UnsafePointer<UInt8> that contains the bytes to be written
  /// - parameter count: The number of bytes to write
  internal func write(from bytes: UnsafePointer<UInt8>, count: Int) {
    let buffer = UnsafeBufferPointer(start: bytes, count: count)
    self.write(from: buffer)
  }

  /// Write DispatchData to the channel.
  ///
  /// - parameter data: DispatchData to write to the channel.
  func write(data: DispatchData) {
    self.outputStream.write(offset: 0,
                            data: data,
                            queue: DispatchQueue.global(),
                            ioHandler: {_, _, _ in })
  }

  /// Write as much data to the socket as possible, buffering the rest
  ///
  /// The default implementation simply forwards to `write(from:)`
  ///
  /// - parameter data: The Data struct containing the bytes to write
  internal func write(from data: Data) {
    data.withUnsafeBytes { (bytePointer: UnsafePointer<UInt8>) in
      let buffer = UnsafeBufferPointer(start: bytePointer, count: data.count)
      self.write(from: buffer)
    }
  }

  // MARK: - Private Methods

  /// Handle io reads from stdin
  private func ioReadHandler(done: Bool, data: DispatchData?, errorCode: Int32) {
    guard let data = data, errorCode == 0 else {
      Log.error("Error occured: (\(errorCode))", if: errorCode != 0)
      prepareShutdown()
      return
    }

    if self.inputBuffer == nil {
      self.inputBuffer = data
    } else {
      self.inputBuffer.append(data)
    }

    if let last = data.last, last == 0x000A /* utf8 for `\n` */ {
      finish()
    }

    if done && data.count == 0 { /// we got EOF
      finish()
      prepareShutdown()
    }
  }

  /// Finish reading a request
  func finish() {
    guard self.inputBuffer.count > 0 else { return }

    let data: Data = self.inputBuffer.withUnsafeBytes(body: {
      (bytes: UnsafePointer<UInt8>) in
        return Data(bytes: bytes, count: self.inputBuffer.count)
    })

    let processed = self.processor.process(data)

    if processed {
      self.inputBuffer = nil
    } else {
      Log.error("Unable to process data.")
    }
  }

  /// Cleanup handler for our `inputChannel`
  private func cleanupHandler(_ errorCode: Int32) {
    // if the `errorNumber` is not 0, something went wrong.
    guard errorCode != 0 else { return }
    Log.error("An error occured with the `stdin` channel. (\(errorCode)) -- \(strerror(errorCode))")
  }

  /// Prepare to shut everything down on the next loop
  private func prepareShutdown() {
    Log.info("Shutting down the channel")
  }
}


/// Helper to create DispatchIO objects for a given fd
fileprivate func createDispatchIO(
  for fd: Int32, cleanupHandler: @escaping (Int32) -> ()) -> DispatchIO {
    let io =  DispatchIO(type: .stream, fileDescriptor: fd, queue: DispatchQueue.global(),
                         cleanupHandler: cleanupHandler)
    io.setLimit(lowWater: ChannelStream.ioLowWater)
    return io
}
