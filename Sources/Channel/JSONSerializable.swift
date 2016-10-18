//
//  JSONSerializable.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/6/16.
//
//

import SwiftyJSON
import Foundation

/// A type that can be represented as JSON
public protocol JSONSerializable {
  /// A JSON-compatible representation of the conforming type
  var json: JSON { get }
  
  /// The raw JSON string of the message body.
  ///
  /// - parameter using: The encoding to use when creating the string
  func jsonString(using encoding: String.Encoding) -> String?

  /// Equivalent to calling jsonString(using: .utf8)
  func jsonString() -> String?

  /// Convert the JSON representation of this message to raw data,
  /// suitable for writing over a socket
  func rawData() throws -> Data
}

/// Extends JSONSerializable to allow initialization from JSON
public protocol JSONInitializable: JSONSerializable {
  /// Required initializer from a JSON Object
  ///
  /// - parameter json: The json object containing the message data
  init?(json: JSON)
}

/// Default implementations
extension JSONSerializable {
  /// Equivalent to calling jsonString(using: .utf8)
  public func jsonString() -> String? {
    return jsonString(using: .utf8)
  }

  /// Equivalent to `jsonString()`
  public func toJSON() -> String? {
    return jsonString()
  }
}
