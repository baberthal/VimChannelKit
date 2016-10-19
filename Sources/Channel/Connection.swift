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

  /// Minimum number of bytes to process before invoking the handler.
  /// We set it to the length of the string "[]", because each message must be a JSON array
  static private let lowWaterMark = "[]".lengthOfBytes(using: .utf8)

  /// Dispatch queues for reading from sockets
  static let socketReadQueues = [
    DispatchQueue(label: "vim-channel.socket-reader.A"),
    DispatchQueue(label: "vim-channel.socket-reader.B")
  ]

  // MARK: - Public Properties 

  /// The associated DataProcessor
  public var processor: DataProcessor?

  // MARK: - Internal Properties

  /// The associated socket
  let socket: Socket

  /// A back reference to the `ConnectionManager` that manages this connection
  weak var manager: ConnectionManager?

  /// The file descriptor of our socket
  var fileDescriptor: Int32 { return socket.socketfd }

  /// Dispatch read source for socket ops
  var readSource: DispatchSourceRead!

  /// Dispatch write source for socket ops
  var writeSource: DispatchSourceWrite?

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

  /// A shortcut for `socketReadQueue(fd: socket.socketfd)`
  private var socketReadQueue: DispatchQueue {
    return socketReadQueue(fd: socket.socketfd)
  }

  // MARK: - Initializers 

  /// Initialize a connection with a Socket, managed by a `ConnectionManager`
  init(socket: Socket, using: DataProcessor, managedBy manager: ConnectionManager) {
    self.socket = socket
    self.processor = using
    self.manager = manager

    self.readSource = DispatchSource.makeReadSource(fileDescriptor: socket.socketfd,
                                                    queue: socketReadQueue)

    self.readSource.setEventHandler(handler: { _ = self.handleRead() })
    self.readSource.setCancelHandler(handler: self.handleCancel)
    self.readSource.resume()

    self.processor?.connection = self
  }

  // MARK: - Public Methods

  func write(buffer: UnsafeBufferPointer<UInt8>) {
    guard socket.socketfd > -1 else { return }

    do {
      try writeImpl(buffer: buffer)
    } catch {
      Log.error("Write to socket (fd=\(self.socket.socketfd) failed. " +
                "Error number=\(errno) Message=\(errorString(errno)).")
    }
  }

  /// Write a sequence of bytes in an array to the socket
  ///
  /// - parameter from: An UnsafeRawPointer to the sequence of bytes to be written to the socket.
  /// - parameter length: The number of bytes to write to the socket.
  
  public func write(from bytes: UnsafeRawPointer, length: Int) {
    let bytePointer = bytes.assumingMemoryBound(to: UInt8.self)
    let buffer = UnsafeBufferPointer(start: bytePointer, count: length)
    write(buffer: buffer)
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

  /// Read available data from the socket, into `readBuffer`
  ///
  /// - returns: true if the data was processed, false otherwise
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
      Log.error(socketError: error)
      close()
    } catch {
      Log.error("Unknown error: \(error)")
      close()
    }

    return result
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
                  "Error number=\(errno). Message=\(errorString(errno)).")
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

  /// The actual write implementation
  private func writeImpl(buffer: UnsafeBufferPointer<UInt8>) throws {
    let written: Int = try {
      guard writeBuffer.count > 0 else { return 0 }
      return try socket.write(from: buffer.baseAddress!, bufSize: buffer.count)
    }()

    guard written != buffer.count else { return }

    Connection.socketWriteQueue.sync { [unowned self] in
      self.writeBuffer.append(buffer)
    }

    if writeSource == nil { self.createWriteSource() }
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

  /// The cleanup handler for our dispatch IO
  private func cleanupIO(_ fd: Int32) {

  }

  /// The cancel handler for our dispatch read source
  private func handleCancel() {
    if socket.socketfd > -1 {
      socket.close()
    }
  }
}

/// - Returns: String containing relevant text about the error.
fileprivate func errorString(_ error: Int32) -> String {
  return String(validatingUTF8: strerror(error)) ?? "Error: \(error)"
}
