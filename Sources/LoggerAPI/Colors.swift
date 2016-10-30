//
//  Colors.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/6/16.
//
//

import Foundation

/// Escape Codes for setting the color in a terminal, or the Xcode console
public enum LogColor: String {
  /// The type of output we are dealing with
  public enum OutputType {
    /// A standard TTY
    case terminal
    /// The Xcode console
    case xcode
  }

  /// Log text in black
  case black
  /// Log text in red
  case red
  /// Log text in green
  case green
  /// Log text in yellow
  case yellow
  /// Log text in blue
  case blue
  /// Log text in magenta
  case magenta
  /// Log text in cyan
  case cyan
  /// Log text in white
  case white
  /// Log text in the default foreground color
  case foreground
  /// Log text in the default background color
  case background
  /// Reset to all normal colors (fg ang bg)
  case reset

  /// All available colors
  public static let allColors: [LogColor] = [.black, .red, .green, .yellow, .blue, .magenta,
                                             .cyan, .white, .foreground, .background]

  /// Get the effective escape sequence for the given color
  public var color: String { return colorFor(effectiveOutputType) }

  /// Get the effective escape sequence for the given color, as a background color
  public var backgroundColor: String { return backgroundColorFor(effectiveOutputType) }

  /// Get the escape code for a given output type
  public func colorFor(_ outputType: OutputType) -> String {
    switch outputType {
    case .terminal: return ttyColor
    case .xcode: return xcodeColor
    }
  }

  /// Return the escape sequence to set the background for the current logger
  ///
  /// - parameter outputType: The `OutputType` to query
  /// - returns: The appropriate escape sequence for `OutputType` to set the background color
  public func backgroundColorFor(_ outputType: OutputType) -> String {
    switch outputType {
    case .terminal: return ttyColor.replacingOccurrences(of: "[0;3", with: "[0;4")
    case .xcode: return xcodeColor.replacingOccurrences(of: "[fg", with: "[bg")
    }
  }

  /// Escape Codes for setting the color in a terminal
  public var ttyColor: String {
    switch self {
    case .black: return "\u{001B}[0;30m"
    case .red: return "\u{001B}[0;31m"
    case .green: return "\u{001B}[0;32m"
    case .yellow: return "\u{001B}[0;33m"
    case .blue: return "\u{001B}[0;34m"
    case .magenta: return "\u{001B}[0;35m"
    case .cyan: return "\u{001B}[0;36m"
    case .white: return "\u{001B}[0;37m"
    case .foreground: return "\u{001B}[0;39m"
    case .background: return "\u{001B}[0;49m"
    case .reset: return "\u{001B}[0m"
    }
  }

  /// Escape Codes for setting the color in the xcode console
  public var xcodeColor: String {
    switch self {
    case .black: return "\u{001B}[fg7,54,66;"
    case .red: return "\u{001B}[fg220,50,47;"
    case .green: return "\u{001B}[fg113,153,0;"
    case .yellow: return "\u{001B}[fg181,137,0;"
    case .blue: return "\u{001B}[fg38,139,210;"
    case .magenta: return "\u{001B}[fg211,54,130;"
    case .cyan: return "\u{001B}[fg42,161,152;"
    case .white: return "\u{001B}[fg238,232,213;"
    case .foreground: return "\u{001B}[fg;"
    case .background: return "\u{001B}[bg;"
    case .reset: return "\u{001B}[;"
    }
  }

  /// Determine if we are running in the xcode console
  fileprivate var effectiveOutputType: OutputType {
    if let setEnv = getenv("XcodeColors"), let xc = String(validatingUTF8: setEnv), xc == "YES" {
      return .xcode
    }
    return .terminal
  }
}

/// Custom string conversion for LogColor
extension LogColor: CustomStringConvertible {
  public var description: String {
    return self.color
  }
}

extension String {
  /// Returns a copy of `self`, colorized with the given color
  /// - parameter aColor: The color to make the string
  /// - returns: a copy of `self`, with escape codes to print in `aColor`
  public func colorize(_ aColor: LogColor, on: LogColor? = nil) -> String {
    if let background = on {
      return "\(aColor)\(background.backgroundColor)\(self)\(LogColor.reset)"
    } else {
      return "\(aColor)\(self)\(LogColor.reset)"
    }
  }

  /// Renamed `colorize`
  @available(*, unavailable, renamed: "colorize")
  public func color(_ aColor: LogColor) -> String {
    return colorize(aColor)
  }

  /// All available colors
  public static var availableColors: [LogColor] {
    return LogColor.allColors
  }

  /// Returns a copy of `self`, colorized in black
  public var black: String {
    return "\(LogColor.black)\(self)\(LogColor.reset)"
  }

  /// Returns a copy of `self`, colorized in red
  public var red: String {
    return "\(LogColor.red)\(self)\(LogColor.reset)"
  }

  /// Returns a copy of `self`, colorized in green
  public var green: String {
    return "\(LogColor.green)\(self)\(LogColor.reset)"
  }

  /// Returns a copy of `self`, colorized in yellow
  public var yellow: String {
    return "\(LogColor.yellow)\(self)\(LogColor.reset)"
  }

  /// Returns a copy of `self`, colorized in blue
  public var blue: String {
    return "\(LogColor.blue)\(self)\(LogColor.reset)"
  }

  /// Returns a copy of `self`, colorized in magenta
  public var magenta: String {
    return "\(LogColor.magenta)\(self)\(LogColor.reset)"
  }

  /// Returns a copy of `self`, colorized in cyan
  public var cyan: String {
    return "\(LogColor.cyan)\(self)\(LogColor.reset)"
  }

  /// Returns a copy of `self`, colorized in white
  public var white: String {
    return "\(LogColor.white)\(self)\(LogColor.reset)"
  }

  /// Returns a copy of `self`, colorized in the default foreground color
  public var defaultForeground: String {
    return "\(LogColor.foreground)\(self)\(LogColor.reset)"
  }

  /// Returns a copy of `self`, colorized in the default background color
  public var defaultBackground: String {
    return "\(LogColor.foreground)\(self)\(LogColor.reset)"
  }
}
