//
//  Request.swift
//  VimChannelKit
//
//  Created by Morgan Lieberthal on 10/30/16.
//
//

import Foundation

/// The `Request` protocol defines an interface for requests that are 
/// received by a given server.
public protocol Request: class {
  /// The IP Address of the client
  var remoteAddress: String { get }
  
  /// Read data from the body of the request
  ///
  /// - parameter data: A Data struct to hold the data read in.
  ///
  /// - throws: Socket.error if an error occurred while reading from the socket
  /// - returns: The number of bytes read
  func read(into data: inout Data) throws -> Int

  /// Read a string from the body of the request.
  ///
  /// - throws: Socket.Error if an error occurred while reading from the socket
  /// - returns: An Optional string
  func readString() throws -> String?

  /// Read all of the data in the body of the request
  ///
  /// - parameter data: A Data struct to hold the data read in.
  ///
  /// - throws: Socket.error if an error occurred while reading from the socket
  /// - returns: The number of bytes read
  func readAllData(into data: inout Data) throws -> Int
}
