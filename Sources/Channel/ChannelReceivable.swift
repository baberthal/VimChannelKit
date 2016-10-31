//
//  ChannelReceivable.swift
//  VimChannelKit
//
//  Created by Morgan Lieberthal on 10/30/16.
//
//

import Foundation
import SwiftyJSON

// MARK: - ChannelReceivable

/// The `ChannelReceivable` protocol defines an interface for objects that can
/// be received over a Vim channel.
public protocol ChannelReceivable: class {
  /// The IP address of the client
  var remoteAddress: String { get }

  /// The `id` of the message from Vim
  var id: Int { get }

  /// The body of the message
  var body: JSON { get }

  /// Read data from the body of the request
  ///
  /// - Parameter data: A Data struct to hold the data read in.
  ///
  /// - Throws: Socket.error if an error occurred while reading from the socket
  /// - Returns: The number of bytes read
  func read(into data: inout Data) throws -> Int

  /// Read a string from the body of the request.
  ///
  /// - Throws: Socket.error if an error occurred while reading from the socket
  /// - Returns: An Optional string
  func readString() throws -> String?

  /// Read a json object from the body of the request.
  ///
  /// - Throws: Socket.error if an error occurred while reading from the socket
  /// - Returns: A JSON object
  func readJSON() throws -> JSON

  /// Read all of the data in the body of the request
  ///
  /// - Parameter data: A Data struct to hold the data read in.
  ///
  /// - Throws: Socket.error if an error occurred while reading from the socket
  /// - Returns: The number of bytes read
  func readAllData(into data: inout Data) throws -> Int
}

