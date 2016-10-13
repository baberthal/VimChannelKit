//
//  SocketHandler.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/10/16.
//  Adapted from IBM-Swift/Kitura-net/IncomingSocketHandler
//  Licensed under the Apache License, Version 2.0
//

import Dispatch
import Foundation
import LoggerAPI
import Socket


/// This class handles incoming sockets to the HTTPServer. The data sent by the client
/// is read and passed to the current `IncomingDataProcessor`.
///
/// - Note: The IncomingDataProcessor can change due to an Upgrade request.
///
/// - Note: This class uses different underlying technologies depending on:
///
///     1. On Linux, if no special compile time options are specified, epoll is used
///     2. On macOS, DispatchSource is used
///     3. On Linux, if the compile time option -Xswiftc -DGCD_ASYNCH is specified,
///        DispatchSource is used, as it is used on macOS.
public class SocketHandler {
  /// Dispatch queue for socket writing
  static let socketWriteQueue = DispatchQueue(label: "org.jmorgan.vim-channel.socket-write")
  
  /// Dispatch queues for socket reading
  static let socketReaderQueues = [
    DispatchQueue(label: "org.jmorgan.vim-channel.socket-reader-A"),
    DispatchQueue(label: "org.jmorgan.vim-channel.socket-reader-B")
  ]

  /// Dispatch source for socket read
  /// - note: this is optional. To enable it, use the proper initializer
  var readerSource: DispatchSourceRead!
  /// The dispatch source for our writes
  var writerSource: DispatchSourceWrite?

  /// Number of socket reader queues 
  private let socketReaderQueueCount = SocketHandler.socketReaderQueues.count

  /// Return a queue given a fd
  private func socketReaderQueue(fd: Int32) -> DispatchQueue {
    return SocketHandler.socketReaderQueues[Int(fd) % socketReaderQueueCount]
  }

  let socket: Socket

  /// The `IncomingSocketProcessor` instance that processes data read from the underlying socket.
  public var processor: IncomingSocketProcessor?

  /// A reference to our SocketManager
  private weak var manager: SocketManager?

  /// Read buffer
  private let readBuffer = NSMutableData()
  /// Write buffer
  private let writeBuffer = NSMutableData()
  /// The position of our write buffer
  private var writeBufferPosition = 0
  /// Whether or not we are preparing to close
  private var preparingToClose = false

  /// The file descriptor of the incoming socket
  var fileDescriptor: Int32 { return socket.socketfd }

  /// Initialize with a socket, using a processor, managed by a given SocketManager
  /// - parameter socket: The socket we are handling
  /// - parameter using: The `IncomingSocketProcessor` to process the socket
  /// - parameter managedBy: The `SocketManager` instance that is managing this socket
  init(socket: Socket, using: IncomingSocketProcessor, managedBy: SocketManager) {
    self.socket = socket
    self.processor = using
    self.manager = managedBy

    self.readerSource = DispatchSource.makeReadSource(fileDescriptor: socket.socketfd,
                                                      queue: socketReaderQueue(fd: socket.socketfd))
    self.readerSource.setEventHandler(handler: {
      self.handleRead()
    })

    self.readerSource.setCancelHandler(handler: self.handleCancel)
    self.readerSource.resume()

    self.processor?.handler = self
  }

  /// Read in the available data and hand off to common processing code
  ///
  /// - returns: true if the data read in was processed
  @discardableResult
  func handleRead() -> Bool {
    var result = true

    do {
      var len = 1
      while len > 0 {
        len = try socket.read(into: readBuffer)
      }
      if readBuffer.length > 0 {
        result = handleReadHelper()
      } else {
        if socket.remoteConnectionClosed {
          prepareToClose()
        }
      }
    } catch let error as Socket.Error {
      Log.error(error.description)
      prepareToClose()
    } catch {
      Log.error("Unexpected error...")
      prepareToClose()
    }

    return result
  }
  

  private func handleReadHelper() -> Bool {
    guard let processor = self.processor else { return true }

    let processed = processor.process(readBuffer)

    if processed {
      readBuffer.length = 0
    }
    
    return processed
  }

  /// Helper function for handling data read in while the processor couldn't
  /// process it, if there is any
  func handleBufferedReadDataHelper() -> Bool {
    let result: Bool

    if readBuffer.length > 0 {
      result = handleReadHelper()
    } else {
      result = true
    }

    return result
  }

  /// Handle data read in while the processor couldn't process it, if there is any
  func handleBufferedReadData() {
    socketReaderQueue(fd: socket.socketfd).sync { [unowned self] in
      _ = self.handleBufferedReadDataHelper()
    }
  }

  /// Inner function to write out any buffered data now that the socket can accept more data,
  /// invoked in serial queue.
  private func handleWriteHelper() {
    if writeBuffer.length != 0 {
      do {
        let amountToWrite = writeBuffer.length - writeBufferPosition
        
        let written: Int
        
        if amountToWrite > 0 {
          written = try socket.write(from: writeBuffer.bytes + writeBufferPosition,
                                     bufSize: amountToWrite)
        } else {
          if amountToWrite < 0 {
            Log.error("Amount of bytes to write to file descriptor \(socket.socketfd) was negative \(amountToWrite)")
          }
          
          written = amountToWrite
        }
        
        if written != amountToWrite {
          writeBufferPosition += written
        } else {
          writeBuffer.length = 0
          writeBufferPosition = 0
        }
      } catch {
        Log.error("Write to socket (file descriptor \(socket.socketfd) failed. Error number=\(errno). Message=\(errorString(error: errno)).")
      }

      if writeBuffer.length == 0, let writerSource = writerSource {
        writerSource.cancel()
      }
    }

    if preparingToClose { close() }
  }

  private func createWriterSource() {
    writerSource = DispatchSource.makeWriteSource(fileDescriptor: socket.socketfd,
                                                  queue: SocketHandler.socketWriteQueue)
    writerSource!.setEventHandler(handler: self.handleWriteHelper)
    writerSource!.setCancelHandler(handler: {
      self.writerSource = nil
    })
    writerSource!.resume()
  }

  /// Write as much data to the socket as possible, buffering the rest
  ///
  /// - parameter data: The NSData object containing the bytes to write to the socket.
  public func write(from data: NSData) {
    write(from: data.bytes, length: data.length)
  }

  /// Write a sequence of bytes in an array to the socket
  ///
  /// - parameter from: An UnsafeRawPointer to the sequence of bytes to be written to the socket.
  /// - parameter length: The number of bytes to write to the socket.
  public func write(from bytes: UnsafeRawPointer, length: Int) {
    guard socket.socketfd > -1 else { return }

    do {
      let written: Int

      if writeBuffer.length == 0 {
        written = try socket.write(from: bytes, bufSize: length)
      } else {
        written = 0
      }

      if written != length {
        SocketHandler.socketWriteQueue.sync { [unowned self] in
          self.writeBuffer.append(bytes + written, length: length - written)
        }

        if writerSource == nil {
          createWriterSource()
        }
      }
    } catch {
      Log.error("Write to socket (fd=\(self.socket.socketfd) failed. Error number=\(errno) " +
                "Message=\(errorString(error: errno)).")
    }
  }

  /// If there is data waiting to be written, set a flag and the socket will
  /// be closed when all the buffered data has been written.
  /// Otherwise, immediately close the socket.
  public func prepareToClose() {
    if writeBuffer.length == writeBufferPosition {
      close()
    } else {
      preparingToClose = true
    }
  }

  /// Close the socket and mark this handler as no longer in progress.
  /// - note: The cancel handler will actually close the socket
  private func close() {
    readerSource.cancel()
  }

  /// DispatchSource cancel handler
  private func handleCancel() {
    if socket.socketfd > -1 {
      socket.close()
    }
    processor?.inProgress = false
  }
}

/// - Returns: String containing relevant text about the error.
fileprivate func errorString(error: Int32) -> String {
  return String(validatingUTF8: strerror(error)) ?? "Error: \(error)"
}
