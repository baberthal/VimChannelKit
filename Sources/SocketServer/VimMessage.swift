//
//  VimMessage.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/5/16.
//
//

import Foundation
import Yajl

/// A representation of an incoming message from a Vim channel
public class VimMessage: JSONInitializable {
  /// The number of the message, from Vim.
  public var id: Int

  /// The parsed json of the message body.
  public var body: JSONRepresentable

  /// The raw array that will be encoded as json and sent to vim.
  ///
  /// Vim always expects the same message format, so we standardize it here.
  public final var json: JSONRepresentable {
    return [self.id, self.body]
  }
  
  /// Default internal initializer
  convenience init() { self.init(id: 0) }

  init(id: Int) {
    self.id = id
    self.body = nil
  }

  /// This is equivalent to calling `init(json: JSON(data: data))`.
  ///
  /// - parameter data: The data to parse
  /// 
  /// For example:
  /// ````
  /// let dataFromNetworking: Data = ... 
  /// let message = VimMessage(data: dataFromNetworking)
  /// ````
  public convenience init?(data: Data) {
    if let json = JSONRepresentable(data: data) {
      self.init(json: json)
    } else {
      return nil
    }
  }

  /// Create a new vim message, given a message number and body
  /// - parameter id: The message id number
  /// - parameter body: The message body, as JSON
  public init(_ id: Int, body: JSONRepresentable) {
    self.id = id
    self.body = body
  }

  /// Initialize with a json array
  public required init?(json: JSONRepresentable) {
    self.id = json[0].int ?? -1
    self.body = json[1]
  }

  /// Return the body of the message as a string, if it is a string.
  /// Return nil otherwise.
  public var bodyString: String? {
    return body.string
  }

  public func jsonString(using encoding: String.Encoding) -> String? {
    return json.rawString(encoding, options: [])
  }

  /// Convert the JSON representation of this message to raw data,
  /// suitable for writing over a socket
  public func rawData() throws -> Data {
    return try json.rawData()
  }
}

extension VimMessage: CustomStringConvertible, CustomDebugStringConvertible {
  public var description: String {
    return json.description
  }

  public var debugDescription: String {
    return json.debugDescription
  }
}

/// Describes the TYPE of message
public enum MessageType {
  /// A request, sent from the Vim session.
  ///
  /// These will be in the following format:
  /// ````
  /// [{id}, {body}]
  /// ````
  /// where `{id}` is an `Int`, and `{body}` is `JSON`.
  /// `{id}` will be set by Vim and is to be used in the response.
  case request
  
  /// A response, responding to a `.request` from Vim.
  /// These will be in the following format:
  /// ````
  /// [{id}, {body}]
  /// ````
  /// where `{id}` is the `id` of the `.request` message, and `{body}` is a 
  /// JSON-serializable data type, responding to the request.
  case response

  /// A command, sent from the `ChannelServer` to the Vim session, without
  /// first having recieved a request.  The format of these differs, so please
  /// see the individual `Command` documentation for further details.
  case command
}
