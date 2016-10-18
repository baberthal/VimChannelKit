//
//  ChannelProtocols.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/11/16.
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
