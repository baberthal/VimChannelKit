//
//  ASLLogger.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/11/16.
//
//

import asl
import Dispatch

public class ASLLogger {
  /// If true, use the detailed format when a user logging format wasn't specified.
  public var details: Bool = true

  /// If not nil, specifies the user specified logging format.
  public var format: String?

  /// If not nil, specifies the format used when adding the date and the time to the
  /// logged messages
  public var dateFormat: String?

  /// This logger's DispatchQueue, to be used when logging message asynchronously
  internal let queue: DispatchQueue = DispatchQueue(label: "ASLLogger")

  /// The default detailed format for this logger
  fileprivate static let detailedFormat = "(%level): (%func) (%file):(%line) - (%msg)"
  /// The default format for this logger
  fileprivate static let defaultFormat =  "(%level): (%msg)"
  /// The default date format for this logger
  fileprivate static let defaultDateFormat = "dd.MM.YYY, HH:mm:ss"

  /// This logger's log level
  fileprivate var level: LogLevel = .verbose

  /// This logger's ASL Client
  fileprivate let client: aslclient

  /// Create a `ASLLogger` instance
  public init() {
    self.client = asl_open(nil, "com.apple.console", 0)
  }

  /// Create a `TTYLogger` instance, logging at the given level
  ///
  /// - parameter level: The most detailed level to see in this logger's output
  public required init(_ level: LogLevel) {
    self.client = asl_open(nil, "com.apple.console", 0)
    self.level = level
  }
}

extension ASLLogger: Logger {
  /// Output a logged message.
  ///
  /// - parameter msg: The message to be logged
  /// - parameter level: The level of the message (`LogLevel`) being logged.
  /// - parameter file: The file of the source code of the function invoking the logger API.
  /// - parameter function: The name of the function invoking the logger API.
  /// - parameter line: The line in the source code of the function invoking the logger API.
  /// - parameter async: Whether the log should operate asynchronously
  public func log(_ level: LogLevel, msg: String, file: StaticString,
                  function: StaticString, line: UInt, async: Bool) {
  }

  public func isLogging(_ level: LogLevel) -> Bool {
    return level.rawValue >= self.level.rawValue
  }
}
