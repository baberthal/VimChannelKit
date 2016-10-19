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

// MARK: - ChannelStream 

public class ChannelStream: ChannelBackend {
  /// The `low-water` mark for our input channel. All received messages should
  /// be a vaild JSON array, so we look for a string at least as long as `"[]"`.
  public static let ioLowWater = "[]".lengthOfBytes(using: .utf8)

  // MARK: - Properties 

  /// Channel delegate that will handle the request-response cycle
  public weak var delegate: ChannelDelegate?

  /// A back reference to the channel we are serving
  public weak var channel: Channel!

  /// The input DispatchIO stream for communication
  private var inputStream: DispatchIO!

  /// The output DispatchIO stream for communication
  private var outputStream: DispatchIO!

  /// A buffer for input
  private var inputBuffer = BufferList()

  // MARK: - Initializers

  /// Create a ChannelStream serving a given `Channel`.
  ///
  /// - parameter channel: The channel we are serving.
  public init(serving channel: Channel) {
    self.channel = channel
    self.delegate = channel.delegate

    self.inputStream = DispatchIO(type: .stream,
                                  fileDescriptor: STDIN_FILENO,
                                  queue: DispatchQueue.global(),
                                  cleanupHandler: self.cleanupHandler)

    self.outputStream = DispatchIO(type: .stream,
                                   fileDescriptor: STDIN_FILENO,
                                   queue: DispatchQueue.global(),
                                   cleanupHandler: self.cleanupHandler)

    self.inputStream.setLimit(lowWater: ChannelStream.ioLowWater)

    self.outputStream.setLimit(lowWater: ChannelStream.ioLowWater)
  }

  // MARK: - Public Methods

  public func start() {
    self.inputStream.read(offset: 0,
                          length: Int.max,
                          queue: DispatchQueue.global(),
                          ioHandler: { [unowned self] (done, data, err) in
                            self.ioReadHandler(done: done, data: data, errorCode: err)
    })
  }

  public func stop() {
    if let inputStream = self.inputStream {
      inputStream.close()
    }
  }

  func write(data: DispatchData) {
    self.outputStream.write(offset: 0,
                            data: data,
                            queue: DispatchQueue.global(),
                            ioHandler: {_,_,_ in })
  }

  // MARK: - Private Methods

  /// Handle io reads from stdin
  private func ioReadHandler(done: Bool, data: DispatchData?, errorCode: Int32) {
    guard errorCode == 0 else {
      Log.error("Error occured: (\(errorCode))")
      prepareShutdown()
      return
    }

    guard let data = data, data.count > 0 else {
      Log.error("Data was nil (or empty)!")
      return
    }

    if done && self.inputBuffer.count == 0 {
      write(data: data)
      return
    }

    data.withUnsafeBytes(body: { (bytes: UnsafePointer<UInt8>) in
      self.inputBuffer.append(bytes: bytes, length: data.count)
    })

    if done { finish() }
  }

  /// Finish reading a request
  func finish() {
    guard self.inputBuffer.count > 0 else { return }
    let dispatchData = self.inputBuffer.dispatchData
    write(data: dispatchData)
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
