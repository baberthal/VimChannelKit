//
//  ServerResponse.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/5/16.
//
//

import Foundation

/// The ServerResponse protocol allows responses to be abstracted
/// across different networking protocols in an agnostic way.
public protocol ServerResponse: class {
  /// Add a string to the body of the HTTP response.
  ///
  /// - parameter string: The String data to be added.
  /// - throws: Socket.Error if an error occurred while writing to the socket
  func write(from string: String) throws

  /// Add bytes to the body of the response.
  ///
  /// - parameter data: The Data struct that contains the bytes to be added.
  /// - throws: Socket.Error if an error occurred while writing to the socket
  func write(from data: Data) throws

  /// Add a string to the body of the response and complete sending the HTTP response
  ///
  /// - parameter text: The String to add to the body of the response.
  /// - throws: Socket.Error if an error occurred while writing to the socket
  func end(text: String) throws

  /// Complete sending the response
  ///
  /// - throws: Socket.Error if an error occurred while writing to a socket
  func end() throws

  /// Reset this response object back to it's initial state
  func reset()
}
