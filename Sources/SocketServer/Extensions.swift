//
//  Extensions.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/6/16.
//
//

import Socket

extension Socket {
  /// Returns a 'pretty' version of the remoteHostname:remotePort pair
  public var prettyHost: String {
    return "\(remoteHostname):\(remotePort)"
  }
}

import Foundation
import Yajl

extension JSON {
  /// Raw data, representing the json object
  public func rawData() throws -> Data {
    return try Yajl.data(withJSONObject: self)
  }

  public func rawString(using encoding: String.Encoding) -> String? {
    switch self {
    case .array, .dict:
      if let data = try? self.rawData() {
        return String(data: data, encoding: encoding)
      }
      return nil
      
    default:
      return self.description
    }
  }
}

extension JSON: ExpressibleByNilLiteral {
  public init(nilLiteral: ()) { self = .null }
}
