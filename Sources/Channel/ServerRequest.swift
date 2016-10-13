//
//  ServerRequest.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/5/16.
//
//

import Foundation

/// The ServerRequest protocol allows requests to be abstracted
/// across different networking protocols in an agnostic way.
public protocol ServerRequest: class {
  /// The IP address:PORT pair of the client
  var remoteAddress: String { get }

  /// Read data from the body of the request
  ///
  /// - parameter data: A data structure to read data into
  /// - throws: Socket.Error if an error occured while reading the socket
  /// - returns: The number of bytes read
  func read(into data: inout Data) throws -> UInt

  /// Read a string from the body of the request
  /// 
  /// - throws: Socket.Error if an error occured while reading the socket
  /// - returns: A string of the body, or nil if there is no body
  func readString() throws -> String?

  /// Read all of the data in the body of the request
  ///
  /// - parameter data: A Data structure to read data into
  /// - throws: Socket.Error if an error occurred while reading from the socket
  /// - returns: The number of bytes read
  func readAllData(into data: inout Data) throws -> UInt
}
