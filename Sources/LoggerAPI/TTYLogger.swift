//
//  TTYLogger.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/5/16.
//
//

import Dispatch
import Foundation

/// A terminal logger implementation
public class TTYLogger {
  /// Whether or not the logger output should be colorized.
  public var colored: Bool = false

  /// If true, use the detailed format when a user logging format wasn't specified.
  public var details: Bool = true

  /// If not nil, specifies the user specified logging format.
  public var format: String?

  /// If not nil, specifies the format used when adding the date and the time to the
  /// logged messages
  public var dateFormat: String?

  /// This logger's DispatchQueue, to be used when logging message asynchronously
  internal let queue: DispatchQueue = DispatchQueue(label: "TTYLogger")

  /// The default detailed format for this logger
  fileprivate static let detailedFormat = "(%level): (%func) (%file):(%line) - (%msg)"
  /// The default format for this logger
  fileprivate static let defaultFormat =  "(%level): (%msg)"
  /// The default date format for this logger
  fileprivate static let defaultDateFormat = "dd.MM.YYY, HH:mm:ss"

  /// This logger's log level
  fileprivate var level: LogLevel = .verbose

  /// Create a `TTYLogger` instance
  public init() {}

  public static func use(_ level: LogLevel = .verbose) {
    Log.logger = TTYLogger(level)
    setbuf(stdout, nil)
  }

  /// Create a `TTYLogger` instance, logging at the given level
  ///
  /// - parameter level: The most detailed level to see in this logger's output
  public required init(_ level: LogLevel) {
    self.level = level
  }
}

// MARK: - Logger Conformance

/// Logger protocol conformance implementation
extension TTYLogger: Logger {
  /// Output a logged message.
  ///
  /// - parameter level:     The level of the message (`LogLevel`) being logged.
  /// - parameter msg:      The mesage to be logged
  /// - parameter function: The name of the function invoking the logger API.
  /// - parameter line:     The line in the source code of the function invoking the logger API.
  /// - parameter file:     The file of the source code of the function invoking the logger API.
  public func log(_ level: LogLevel, msg: String, file: StaticString,
                  function: StaticString, line: UInt, async: Bool) {
    let color = colorForLevel(level)

    var message: String = self.format ?? (self.details ? TTYLogger.detailedFormat :
                                                         TTYLogger.defaultFormat)

    for fmt in FormatValues.all {
      let str = fmt.rawValue
      let replacement: String

      switch fmt {
      case .level:    replacement = level.description
      case .message:  replacement = msg
      case .function: replacement = String(describing: function)
      case .line:     replacement = "\(line)"
      case .file:     replacement = prettyFilename(file)
      case .date:     replacement = formattedDate(format: self.dateFormat)
      }

      message = message.replacingOccurrences(of: str, with: replacement)
    }

    let formattedMsg = colored ? "\(color)\(message)\(LogColor.reset)" : "\(message)"

    if level.rawValue >= self.level.rawValue {
      if async {
        queue.async {
          print(formattedMsg)
        }
      } else {
        print(formattedMsg)
      }
    }
  }

  public func isLogging(_ level: LogLevel) -> Bool {
    return level.rawValue >= self.level.rawValue
  }

  /// - returns: The appropriate color for the given log level
  private func colorForLevel(_ level: LogLevel) -> LogColor {
    switch level {
    case .debug:   return .magenta
    case .verbose: return .cyan
    case .info:    return .green
    case .warning: return .yellow
    case .error:   return .red
    }
  }
}

// MARK: - FormatValues

extension TTYLogger {
  /// A set of substitutions to use when formatting a log message
  public enum FormatValues: String {
    /// The message being logged
    case message  = "(%msg)"
    /// The function in which `log` was called
    case function = "(%func)"
    /// The line in the source code where `log` was called
    case line     = "(%line)"
    /// The file in the source code where `log` was called
    case file     = "(%file)"
    /// The log level of the message
    case level    = "(%level)"
    /// The date of the message
    case date     = "(%date)"

    /// All format substitution values
    static let all: [FormatValues] = [.message, .function, .line, .file, .level, .date]
  }
}

// MARK: - Implementation Details

/// Get a formatted date, given a format string
///
/// - parameter format: The format string to pass to `DateFormatter`.
///                     If nil, `TTYLogger.defaultDateFormat` will be used.
///
/// - Returns: The formatted date, as a `String`
fileprivate func formattedDate(format: String?) -> String {
  let format = format ?? TTYLogger.defaultDateFormat
  let date = Date()
  dateFormatter.dateFormat = format
  return dateFormatter.string(from: date)
}

/// The shared instance of `DateFormatter`, to prevent initializing a
/// new instance each time `formattedDate(_:)` is called
fileprivate let dateFormatter = DateFormatter()
