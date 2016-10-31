//
//  ChannelSendable.swift
//  VimChannelKit
//
//  Created by Morgan Lieberthal on 10/30/16.
//
//

import Foundation
import SwiftyJSON

// MARK: - ChannelSendable

/// The `ChannelSendable` protocol defines an interface for objects that can
/// be sent to a Vim session, over a Channel
public protocol ChannelSendable: class {
  /// Add a string to the body of the HTTP response.
  ///
  /// - parameter string: The String data to be added.
  /// - throws: Socket.error if an error occurred while writing to the socket
  func write(from string: String) throws

  /// Add bytes to the body of the HTTP response.
  ///
  /// - parameter data: The Data struct that contains the bytes to be added.
  /// - throws: Socket.error if an error occurred while writing to the socket
  func write(from data: Data) throws

  /// Add JSON to the body of the HTTP response.
  ///
  /// - parameter json: The JSON struct that contains the data to be added.
  /// - throws: Socket.error if an error occurred while writing to the socket
  func write(from json: JSON) throws

  /// Complete sending the HTTP response
  ///
  /// - throws: Socket.error if an error occurred while writing to a socket
  func end() throws

  /// Reset this response object back to it's initial state
  func reset()
}
