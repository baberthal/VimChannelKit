//
//  DataProcessor.swift
//  VimChannelKit
//
//  Created by Morgan Lieberthal on 10/17/16.
//
//

import Foundation

/// This protocol defines the API of the classes used to process the data that
/// comes in from a client's request. There should be one `DataProcessor`
/// instance per incoming request.
public protocol DataProcessor: class {
  /// A flag to indicate that the socket has a request in progress
  var inProgress: Bool { get set }
  
  /// A back reference to the `Connection` processing the socket that
  /// this `IncomingDataProcessor` is processing.
  weak var connection: Connection? { get set }
  
  /// Process data read from the socket.
  ///
  /// - parameter buffer: An NSData object containing the data that was read in
  ///             and needs to be processed.
  ///
  /// - returns: true if the data was processed, false if it needs to be processed later.
  func process(_ buffer: Data) -> Bool
  
  /// Write data to the socket
  ///
  /// - parameter from: An NSData object containing the bytes to be written to the socket.
  func write(from data: Data)
  
  /// Write a sequence of bytes in an array to the socket
  ///
  /// - parameter from: An UnsafeRawPointer to the sequence of bytes to be written to the socket.
  /// - parameter length: The number of bytes to write to the socket.
  func write(from bytes: UnsafeRawPointer, length: Int)

  /// Write a sequence of bytes, from an unsafe buffer pointer to the socket
  func write(from buffer: UnsafeBufferPointer<UInt8>)
  
  /// Close the socket and mark this handler as no longer in progress.
  func close()
}
