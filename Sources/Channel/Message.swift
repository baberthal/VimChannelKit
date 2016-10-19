//
//  Message.swift
//  VimChannelKit
//
//  Created by Morgan Lieberthal on 10/18/16.
//
//

import Foundation
import SwiftyJSON

// MARK: - Message

/// Represents a message to or from Vim, sent over a channel.
public struct Message {
  /// ID of the message. 
  /// If this is a positive number, it came from Vim.
  /// If this is a negative number, the message originated from the server.
  public var id: Int = 0

  /// Body of the message, as a `JSON` object.
  public var body: JSON
}

// MARK: - JSONInitializable

/// JSONInitializable
extension Message: JSONInitializable {
  public init?(json: JSON) {
    if let id = json[0].int {
      self.id = id
      self.body = json[1]
    } else {
      return nil
    }
  }

  init() {
    self.body = nil
  }

  public var json: JSON {
    return [id, body.object]
  }

  public func rawData() throws -> Data {
    return try json.rawData(options: [])
  }

  public func jsonString(using: String.Encoding = .utf8) -> String? {
    return json.rawString(using, options: [])
  }

  public mutating func update(from json: JSON) {
    if let id = json[0].int {
      self.id = id
      self.body = json[1]
    } else {
      self.body = json
    }
  }
}

// MARK: - CustomStringConvertible

extension Message: CustomStringConvertible {
  public var description: String {
    return "[\(id), \(body.rawString)]"
  }
}

extension Message: CustomDebugStringConvertible {
  public var debugDescription: String {
    return "Message:(\n\tid = \(id)\n\tbody = \(body.debugDescription)\n)"
  }
}
