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

import LoggerAPI

extension Log {
  public static func error(_ message: String, `if` condition: Bool) {
    guard condition else { return }
    Log.error(message)
  }

  public static func error(socketError: Socket.Error) {
    Log.error("Socket Error: (\(socketError.errorCode)) \(socketError.description)")
  }
}

import func Foundation.strerror
import var Foundation.errno

/// 'Swifty' wrapper around the C standard library function `strerror`
internal func strerror(_ errno: Int32 = Foundation.errno) -> String {
  return String(validatingUTF8: strerror(errno)) ?? "Error: (\(errno))"
}
