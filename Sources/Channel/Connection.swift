//
//  Connection.swift
//  VimChannelKit
//
//  Created by Morgan Lieberthal on 10/30/16.
//
//

import Foundation
import Dispatch
import Socket
import LoggerAPI

/// A `ChannelBackend` implementation for communicating over a socket.
public class Connection: ChannelBackend {
  // MARK: - Properties

  /// The MessageProcessor that will process messages that are received via this connection
  public private(set) var processor: MessageProcessor!

  /// A back reference to the owning `Channel` instance
  weak var channel: Channel? {
    didSet {
      self.processor.channel = channel
    }
  }

  /// The queue this connection is using
  let readQueue: DispatchQueue

  /// The queue this connection is using
  let writeQueue: DispatchQueue

  /// The socket this connection is using
  let socket: Socket

  /// Weak reference to the manager that manages this connection
  weak var manager: ConnectionManager?

  /// Same as `fileDescriptor`
  var sockfd: Int32 { return socket.socketfd }

  /// Dispatch read source for socket ops
  var readSource: DispatchSourceRead!

  /// Dispatch write source for socket ops
  var writeSource: DispatchSourceWrite?

  /// Buffer for socket reads
  private var readBuffer = Data()

  // FIXME: Use `RingBuffer`s
  /// Buffer for socket writes
  private var writeBuffer = Data()

  /// The position (index) of our write buffer
  private var writeBufferPosition = 0

  /// This is `true` if we are preparing to close the connection
  private var preparingToClose = false

  // MARK: - Initializers

  /// Create a connection over `socket`, using `delegate` to handle messages.
  ///
  /// - parameter socket: The socket over which the connection will communicate.
  /// - parameter delegate: The delegate of the channel this connection serves.
  /// - parameter manager: The connection manager that will manage the lifecycle of this connection.
  init(socket: Socket, using delegate: ChannelDelegate, managedBy manager: ConnectionManager) {
    self.readQueue  = createQueue(forSocket: socket, type: .read)
    self.writeQueue = createQueue(forSocket: socket, type: .write)

    self.socket    = socket
    self.manager   = manager
    self.processor = MessageProcessor(backend: self, using: delegate)

    self.readSource = DispatchSource.makeReadSource(fileDescriptor: sockfd, queue: readQueue)
    self.readSource.setEventHandler(handler: { _ = self.handleRead() })
    self.readSource.setCancelHandler(handler: self.handleReadCancel)
    
    self.readSource.resume()
  }

  // MARK: - Methods

  /// Starts the channel.
  func start() {}

  /// Stops the channel.
  func stop() {
    prepareToClose()
  }

  /// Read available data from the socket, into `readBuffer`
  ///
  /// - returns: true if the data was processed, false otherwise
  func handleRead() -> Bool {
    var result = false // pessimist! 

    do {
      var len = 1
      while len > 0 {
        len = try socket.read(into: &readBuffer)
      }

      if readBuffer.count > 0 {
        result = processReadData()
      } else if socket.remoteConnectionClosed {
        prepareToClose()
      }
      
    } catch let error as Socket.Error {
      Log.error(error.description)
      prepareToClose()
    } catch {
      Log.error("Unexpected Error: \(error)!")
      prepareToClose()
    }

    return result
  }

  /// Write a sequence of bytes in an UnsafeBufferPointer to the socket
  ///
  /// - parameter from: An UnsafeBufferPointer to the sequence of bytes to be written to the socket.
  func write(from buffer: UnsafeBufferPointer<UInt8>) {
    guard socket.socketfd > -1 else { return }

    do {
      try writeImpl(buffer: buffer)
    } catch {
      Log.error("Write to socket (fd: \(socket.socketfd)) failed -- (\(errno)) \(strerror())")
    }
  }

  /// If there is data waiting to be written, set a flag and the socket will
  /// be closed when all the buffered data has been written.
  /// Otherwise, immediately close the socket.
  public func prepareToClose() {
    if writeBuffer.count == writeBufferPosition {
      close()
    } else {
      preparingToClose = true
    }
  }
  
  /// Write a sequence of bytes to the channel
  ///
  /// The default implementation simply forwards to `write(from:)`
  ///
  /// - parameter from: An UnsafePointer<UInt8> that contains the bytes to be written
  /// - parameter count: The number of bytes to write
  internal func write(from bytes: UnsafePointer<UInt8>, count: Int) {
    let buffer = UnsafeBufferPointer(start: bytes, count: count)
    write(from: buffer)
  }

  /// Write as much data to the socket as possible, buffering the rest
  ///
  /// - parameter data: The Data object containing the bytes to write to the socket.
  public func write(from data: Data) {
    data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in
      write(from: bytes, count: data.count)
    }
  }

  // MARK: - Private Methods

  /// Helper for processing data once read into `readBuffer`
  private func processReadData() -> Bool {
    let processed = self.processor.process(self.readBuffer)

    // reset `readBuffer` if the message was successfully processed
    if processed {
      readBuffer.count = 0
    }

    return processed
  }

  /// Cancel handler for our `DispatchReadSource`
  private func handleReadCancel() {
    guard socket.socketfd > -1 else { return }
    socket.close()
  }

  /// Handle write to the socket
  private func handleWrite() {
    if writeBuffer.count != 0 {
      do {
        try handleWriteInternal()
      } catch {
        Log.error("Write to socket (fd: \(socket.socketfd)) failed -- (\(errno)) \(strerror())")
      }

      if let writeSource = self.writeSource, writeBuffer.count == 0 {
        writeSource.cancel()
      }
    }

    if preparingToClose {
      close()
    }
  }

  /// Helper function for reading data from the socket
  private func handleWriteInternal() throws {
    func logIfNegative(_ amount: Int) {
      guard amount < 0 else { return }
      Log.error("Amount of bytes to write to file descriptor \(sockfd) was negative: \(amount)")
    }

    let amountToWrite = writeBuffer.count - writeBufferPosition
    var written: Int

    if amountToWrite > 0 {
      written = try writeBuffer.withUnsafeBytes { [unowned self] (bytePtr: UnsafePointer<UInt8>) in
        let bufStart = bytePtr + self.writeBufferPosition
        return try self.socket.write(from: bufStart, bufSize: amountToWrite)
      }
    } else {
      logIfNegative(amountToWrite)
      written = amountToWrite
    }

    if written != amountToWrite {
      writeBufferPosition += written
    } else {
      writeBuffer.count = 0
      writeBufferPosition = 0
    }
  }

  /// Create a `DispatchWriteSource` for our socket
  private func createWriteSource() {
    self.writeSource = DispatchSource.makeWriteSource(fileDescriptor: sockfd, queue: writeQueue)
    self.writeSource!.setEventHandler(handler: self.handleWrite)
    self.writeSource!.setCancelHandler { self.writeSource = nil }
    self.writeSource!.resume()
  }

  /// The actual write implementation
  private func writeImpl(buffer: UnsafeBufferPointer<UInt8>) throws {
    let written: Int = try {
      guard let base = buffer.baseAddress, writeBuffer.count > 0 else { return 0 }
      return try socket.write(from: base, bufSize: buffer.count)
    }()

    guard written != buffer.count else { return }

    writeQueue.sync { [unowned self] in
      self.writeBuffer.append(buffer)
    }

    if self.writeSource == nil { self.createWriteSource() }
  }

  /// Actually close the socket, and mark this handler as __`inactive`__
  private func close() {
    self.readSource.cancel()
  }
}

// MARK: - Helper Functions & Implementation Details

/// For `createQueue(forSocket:type:)`
fileprivate enum QueueType: String {
  case read, write
}

/// Create a `DispatchQueue` for a given Socket
fileprivate func createQueue(forSocket socket: Socket, type: QueueType = .read) -> DispatchQueue {
  let label = "vim-channel.connection.sockfd=\(socket.socketfd).\(type)"
  return DispatchQueue(label: label)
}
