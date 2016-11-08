//
//  Extensions.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/6/16.
//
//

import Socket
import Dispatch

extension Socket {
  /// Returns a 'pretty' version of the remoteHostname:remotePort pair
  public var prettyHost: String {
    return "\(remoteHostname):\(remotePort)"
  }

  /// Writes data to the socket from a `DispatchData` instance
  ///
  /// - parameter data: The `DispatchData` instance containing the data to write to the socket
  /// - returns: The number of bytes written to the socket
  @discardableResult
  public func write(from data: DispatchData) throws -> Int {
    // don't do anything if the data is empty, just fail silently
    guard data.count > 0 else { return 0 }

    return try data.withUnsafeBytes(body: { (pointer: UnsafePointer<UInt8>) in
      return try write(from: pointer, bufSize: data.count)
    })
  }
}

import LoggerAPI

extension Log {
  /// Log a message, if and only if `condition` returns `true`.
  ///
  /// - parameter message: The message to log if `condition` is true.
  /// - parameter condition: The condition to evaluate.
  public static func error(_ message: String, `if` condition: @autoclosure() -> Bool) {
    guard condition() else { return }
    Log.error(message)
  }

  /// Log a socket error.
  ///
  /// - parameter socketError: The `Socket.Error` to log.
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
