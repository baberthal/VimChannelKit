//
//  Connection.swift
//  VimChannelKit
//
//  Created by Morgan Lieberthal on 10/17/16.
//
//

import Dispatch
import Foundation
import Socket
import LoggerAPI

/// The `ConnectionHandler` class is responsible for handling incoming data, and 
/// passing it to the current `DataProcessor`.
public class Connection {
  // MARK: - Static Properties

  /// Dispatch queue for writing to sockets
  static let socketWriteQueue = DispatchQueue(label: "vim-channel.socket-writer")

  /// Dispatch queues for reading from sockets
  static let socketReadQueues = [
    DispatchQueue(label: "vim-channel.socket-reader.A"),
    DispatchQueue(label: "vim-channel.socket-reader.B")
  ]

  // MARK: - Public Properties 

  /// The associated DataProcessor
  public var processor: IncomingDataProcessor?

  // MARK: - Internal Properties

  /// Dispatch source for socket reading
  /// - note: This property is optional. Use the appropriate initializer to enable it.
  var readSource: DispatchSourceRead!

  /// Dispatch source for socket writing
  var writeSource: DispatchSourceWrite?

  /// The associated socket
  let socket: Socket

  /// A back reference to the `ConnectionManager` that manages this connection
  weak var manager: ConnectionManager?

  /// The file descriptor of our socket
  var fileDescriptor: Int32 { return socket.socketfd }

  // MARK: - Private Properties 
  
  /// Number of socket read queues
  private let socketReadQueueCount = Connection.socketReadQueues.count

  /// Buffer for socket reads
  private var readBuffer = Data()

  /// Buffer for socket writes
  private var writeBuffer = Data()

  /// The position (index) of our write buffer
  private var writeBufferPosition = 0

  /// This is `true` if we are preparing to close the connection
  private var preparingToClose = false

  // MARK: - Initializers 

  /// Initialize a connection with a Socket, managed by a `ConnectionManager`
  init(socket: Socket, using: IncomingDataProcessor, managedBy manager: ConnectionManager) {
    self.socket = socket
    self.processor = using
    self.manager = manager

    let q = socketReadQueue(fd: socket.socketfd)

    self.readSource = DispatchSource.makeReadSource(fileDescriptor: socket.socketfd, queue: q)
    self.readSource.setEventHandler(handler: { _ = self.handleRead() })
    self.readSource.setCancelHandler(handler: self.handleCancel)
    self.readSource.resume()
  }

  // MARK: - Public Methods

  /// Write a sequence of bytes in an array to the socket
  ///
  /// - parameter from: An UnsafeRawPointer to the sequence of bytes to be written to the socket.
  /// - parameter length: The number of bytes to write to the socket.
  public func write(from bytes: UnsafeRawPointer, length: Int) {
    func writeInternal() throws {
      let written: Int

      if writeBuffer.count == 0 {
        written = try socket.write(from: bytes, bufSize: length)
      } else {
        written = 0
      }

      guard written == length else { return }

      Connection.socketWriteQueue.sync { [unowned self] in
        self.writeBuffer.append(bytes.advanced(by: written).assumingMemoryBound(to: UInt8.self),
                                count: length - written)
      }

      if self.writeSource == nil { self.createWriteSource() }
    }

    guard socket.socketfd > -1 else { return }

    do {
      try writeInternal()
    } catch {
      Log.error("Write to socket (fd=\(self.socket.socketfd) failed. " +
                "Error number=\(errno) Message=\(errorString(error: errno)).")
    }
  }

  /// Write as much data to the socket as possible, buffering the rest
  ///
  /// - parameter data: The NSData object containing the bytes to write to the socket.
  public func write(from data: NSData) {
    write(from: data.bytes, length: data.length)
  }

  /// Write as much data to the socket as possible, buffering the rest
  ///
  /// - parameter data: The Data object containing the bytes to write to the socket.
  public func write(from data: Data) {
    data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in
      write(from: bytes, length: data.count)
    }
  }

  /// If there is data waiting to be written, set a flag and the socket will
  /// be closed when all the buffered data has been written.
  /// Otherwise, immediately close the socket.
  public func close() {
    if writeBuffer.count == writeBufferPosition {
      doClose()
    } else {
      preparingToClose = true
    }
  }

  // MARK: - Internal Methods 
  
  /// The event handler for our dispatch read source
  func handleRead() -> Bool {
    var result = true

    do {
      var len = 1

      while len > 0 {
        len = try socket.read(into: &readBuffer)
      }

      if readBuffer.count > 0 {
        result = processRead()
      } else if socket.remoteConnectionClosed {
        close()
      }
    } catch let error as Socket.Error {
      Log.error(error.description)
      close()
    } catch {
      Log.error("Unexpected error! -- \(error)")
      close()
    }
    
    return result
  }

  /// Helper for handling buffered reads
  func handleBufferedReadImpl() -> Bool {
    if readBuffer.count > 0 {
      return handleRead()
    } else {
      return true
    }
  }

  func handleBufferedRead() {
    socketReadQueue(fd: socket.socketfd).sync { [unowned self] in
      _ = self.handleBufferedReadImpl()
    }
  }

  // MARK: - Private Methods 

  /// Handle write to the socket
  private func handleWrite() {
    func logIfNegative(_ amount: Int) {
      guard amount < 0 else { return }
      Log.error("Amount of bytes to write to file descriptor \(socket.socketfd) was " +
                "negative \(amount)")
    }
    
    func handleWriteInternal() {
      do {
        let amountToWrite = writeBuffer.count - writeBufferPosition
        try writeBuffer.withUnsafeBytes { (bytes: UnsafePointer<Int8>) in
          let written: Int

          if amountToWrite > 0 {
            written = try socket.write(from: bytes, bufSize: amountToWrite)
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
      } catch {
        Log.error("Write to socket (file descriptor \(socket.socketfd) failed. " +
                  "Error number=\(errno). Message=\(errorString(error: errno)).")
      }

      if let writeSource = writeSource, writeBuffer.count == 0 {
        writeSource.cancel()
      }
    }

    if writeBuffer.count != 0 {
      handleWriteInternal()
    }

    if preparingToClose { doClose() }
  }

  /// Create a dispatch write source
  private func createWriteSource() {
    writeSource = DispatchSource.makeWriteSource(fileDescriptor: socket.socketfd,
                                                 queue: Connection.socketWriteQueue)
    writeSource!.setEventHandler(handler: self.handleWrite)
    writeSource!.setCancelHandler(handler: { self.writeSource = nil })
    writeSource!.resume()
  }

  /// Return a socket read queue for a given file descriptor
  private func socketReadQueue(fd: Int32) -> DispatchQueue {
    let idx = Int(fd) % socketReadQueueCount
    return Connection.socketReadQueues[idx]
  }

  /// Helper for handling reads
  private func processRead() -> Bool {
    guard let processor = self.processor else { return true }

    let processed = processor.process(self.readBuffer)

    if processed {
      readBuffer.count = 0
    }

    return processed
  }

  /// Close the socket and mark this handler as no longer in progress.
  /// - note: The cancel handler will actually close the socket
  private func doClose() {
    readSource.cancel()
  }

  /// The cancel handler for our dispatch read source
  private func handleCancel() {
    if socket.socketfd > -1 {
      socket.close()
    }
  }
}

/// - Returns: String containing relevant text about the error.
fileprivate func errorString(error: Int32) -> String {
  return String(validatingUTF8: strerror(error)) ?? "Error: \(error)"
}
