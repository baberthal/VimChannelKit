//
//  SystemLogger.swift
//  VimChannelKit
//
//  Created by Morgan Lieberthal on 10/30/16.
//
//

#if os(Linux)
import Glibc
#else
import os
#endif

import Dispatch
import Foundation

/// The SystemLogger implements the logger interface using `syslog` on Linux,
/// and `os_log` on Darwin where available, and `asl_log` otherwise.
public class SystemLogger: Logger {
  /// Queue for our log messages, to 'get out of the way'
  /// of our normal progam execution
  internal let queue = DispatchQueue(label: "SystemLogger")

  /// This logger's log level
  internal var level: LogLevel = .verbose

  /// Default initializer
  public init() {}

  // MARK: - Logger Protocol Conformance

  /// Required initializer
  public required init(_ level: LogLevel) {
    self.level = level
  }

  public func log(_ level: LogLevel, msg: String, file: StaticString,
                  function: StaticString, line: UInt, async: Bool) {
  }

  public func isLogging(_ level: LogLevel) -> Bool {
    return level.rawValue >= self.level.rawValue
  }
}

/// Helper extension on LogLevel
fileprivate extension LogLevel {
  var osLogType: OSLogType! {
    if #available(OSX 10.12, *) {
      switch self {
      case .verbose: return .default
      case .info: return .info
      case .debug: return .debug
      case .warning: return .error
      case .error: return .fault
      }
    } else {
      return nil
    }
  }
}
