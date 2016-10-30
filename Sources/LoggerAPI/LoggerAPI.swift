//
//  LogFacility.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/5/16.
//  Adapted from IBM-Swift/LoggerAPI (https://github.com/IBM-Swift/LoggerAPI)
//  Licensed Under The Apache License, Version 2.0
//

/// The level of a particular log message. Passed with the message to be logged to the
/// actual logger implementation. It is also used to enable filtering of the log based
/// on minimal level to log.
public enum LogLevel: Int {
  /// Log all messages (debug, verbose, info, warning, error)
  case debug = 1
  /// Log messages up to verbose (verbose, info, warning, error)
  case verbose
  /// Log messages up to info (info, warning, error)
  case info
  /// Log messages up to warning (warning, error)
  case warning
  /// Log only error messages
  case error
}

/// Conversion of LogLevel into string
extension LogLevel: CustomStringConvertible {
  /// Convert a LogLevel into a printable format
  public var description: String {
    switch self {
    case .debug: return "DEBUG"
    case .verbose: return "VERBOSE"
    case .info: return "INFO"
    case .warning: return "WARNING"
    case .error: return "ERROR"
    }
  }
}

/// A logger protocol implemented by Logger implementations.
public protocol Logger {
  /// Output a logged message.
  ///
  /// - parameter msg: The message to be logged
  /// - parameter level: The level of the message (`LogLevel`) being logged.
  /// - parameter file: The file of the source code of the function invoking the logger API.
  /// - parameter function: The name of the function invoking the logger API.
  /// - parameter line: The line in the source code of the function invoking the logger API.
  /// - parameter async: Whether the log should operate asynchronously
  func log(_ level: LogLevel, msg: String, file: StaticString, function: StaticString, line: UInt,
           async: Bool)

  /// A function that will indicate if a message with a specified level will be output in the log.
  ///
  /// - parameter level: The type of message that one wants to know if it will be output in the log.
  /// - returns: true if a message of the specified level (`LogLevel`) will be output.
  func isLogging(_ level: LogLevel) -> Bool

  /// Create an instance of the most derived class and set it up as the logger used by the
  /// `Logger` protocol.
  /// - parameter level: The most detailed message level (`LogLevel`) to see in the output of the
  ///                    logger. Defaults to `.verbose`.
  static func use(_ level: LogLevel)

  /// Create an instance of the most derived class, using the specified log level
  /// - parameter level: The most detailed message level (`LogLevel`) to see in the output of the
  ///                    logger.
  init(_ level: LogLevel)
}

extension Logger {
  /// Returns a String of the current filename, without full path or extension.
  ///
  /// Analogous to the C preprocessor macro `THIS_FILE`.
  func prettyFilename(_ filename: StaticString = #file) -> String {
    var str = String(describing: filename)
    if let idx = str.range(of: "/", options: .backwards)?.upperBound {
      str = str.substring(from: idx)
    }

    if let idx = str.range(of: ".", options: .backwards)?.lowerBound {
      str = str.substring(to: idx)
    }

    return str
  }

  /// Convenience initializer.
  /// Equivalent to init(_:) with an argument label
  public init(level: LogLevel) {
    self.init(level)
  }

  /// Create an instance of the most derived class and set it up as the logger used by the
  /// `Logger` protocol.
  /// - parameter level: The most detailed message level (`LogLevel`) to see in the output of the
  ///                    logger. Defaults to `.verbose`.
  public static func use(_ level: LogLevel = .verbose) {
    Log.logger = self.init(level)
  }
}

/// A class of static members used by anyone who wants to log mesages.
public class Log {
  /// An instance of the logger. It should usually be the one and only reference
  /// of the actual `Logger` protocol implementation in the system.
  public static var logger: Logger?

  /// Log a log message for use when in verbose logging mode.
  ///
  /// - parameter msg: The message to be logged
  /// - parameter file: The file of the source code of the function invoking the logger API.
  ///                   Defaults to the file of the actual function invoking this function.
  /// - parameter function: The name of the function invoking the logger API.
  ///                       Defaults to the actual name of the function invoking this function.
  /// - parameter line: The line in the source code of the function invoking the logger API.
  ///                   Defaults to the actual line of the actual function invoking this function.
  /// - parameter async: True if the message should be logged asynchronously
  public class func verbose(_ msg: @autoclosure () -> String,
                             file: StaticString = #file,
                             function: StaticString = #function,
                             line: UInt = #line,
                             async: Bool = true) {
    logger?.log(.verbose, msg: msg(), file: file, function: function, line: line, async: async)
  }

  /// Log an informational message.
  ///
  /// - parameter msg: The message to be logged
  /// - parameter file: The file of the source code of the function invoking the logger API.
  ///                   Defaults to the file of the actual function invoking this function.
  /// - parameter function: The name of the function invoking the logger API.
  ///                       Defaults to the actual name of the function invoking this function.
  /// - parameter line: The line in the source code of the function invoking the logger API.
  ///                   Defaults to the actual line of the actual function invoking this function.
  /// - parameter async: True if the message should be logged asynchronously
  public class func info(_ msg: @autoclosure () -> String,
                         file: StaticString = #file,
                         function: StaticString = #function,
                         line: UInt = #line,
                         async: Bool = true) {
    logger?.log(.info, msg: msg(), file: file, function: function, line: line, async: async)
  }

  /// Log a warning message.
  ///
  /// - parameter msg: The message to be logged
  /// - parameter file: The file of the source code of the function invoking the logger API.
  ///                   Defaults to the file of the actual function invoking this function.
  /// - parameter function: The name of the function invoking the logger API.
  ///                       Defaults to the actual name of the function invoking this function.
  /// - parameter line: The line in the source code of the function invoking the logger API.
  ///                   Defaults to the actual line of the actual function invoking this function.
  /// - parameter async: True if the message should be logged asynchronously
  public class func warning(_ msg: @autoclosure () -> String,
                            file: StaticString = #file,
                            function: StaticString = #function,
                            line: UInt = #line,
                            async: Bool = true) {
    logger?.log(.warning, msg: msg(), file: file, function: function, line: line, async: async)
  }

  /// Log an error message.
  ///
  /// - parameter msg: The message to be logged
  /// - parameter file: The file of the source code of the function invoking the logger API.
  ///                   Defaults to the file of the actual function invoking this function.
  /// - parameter function: The name of the function invoking the logger API.
  ///                       Defaults to the actual name of the function invoking this function.
  /// - parameter line: The line in the source code of the function invoking the logger API.
  ///                   Defaults to the actual line of the actual function invoking this function.
  /// - parameter async: True if the message should be logged asynchronously
  public class func error(_ msg: @autoclosure () -> String,
                          file: StaticString = #file,
                          function: StaticString = #function,
                          line: UInt = #line,
                          async: Bool = true) {
    logger?.log(.error, msg: msg(), file: file, function: function, line: line, async: async)
  }

  /// Log a debuging message.
  ///
  /// - parameter msg: The message to be logged
  /// - parameter file: The file of the source code of the function invoking the logger API.
  ///                   Defaults to the file of the actual function invoking this function.
  /// - parameter function: The name of the function invoking the logger API.
  ///                       Defaults to the actual name of the function invoking this function.
  /// - parameter line: The line in the source code of the function invoking the logger API.
  ///                   Defaults to the actual line of the actual function invoking this function.
  /// - parameter async: True if the message should be logged asynchronously
  public class func debug(_ msg: @autoclosure () -> String,
                          file: StaticString = #file,
                          function: StaticString = #function,
                          line: UInt = #line,
                          async: Bool = true) {
    logger?.log(.debug, msg: msg(), file: file, function: function, line: line, async: async)
  }

  /// A function that will indicate if a message with a specified level will be output in the log.
  ///
  /// - parameter level: The type of message that one wants to know if it will be output in the log.
  /// - returns: true if a message of the specified level (`LogLevel`) will be output.
  public class func isLogging(_ level: LogLevel) -> Bool {
    guard let logger = logger else {
      return false
    }
    return logger.isLogging(level)
  }
}
