// Vim.swift - Encapsulates Vim Objects
//
// This source file is part of the VimChannelKit open source project
//
// Copyright (c) 2014 - 2016 
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// -----------------------------------------------------------------------------
///
/// This file contains encapsulations around objects that exist in Vim, like:
///   * Buffers
///   * Windows
// FIXME: Keep this updated
///
// -----------------------------------------------------------------------------

// MARK: - Vim

/// The Vim class is essentially a namespace around objects that exist in Vim.
public final class Vim {
  /// We should never have an instance of the `Vim` class.
  private init() {}
}

// MARK: - Buffer

extension Vim {
  /// Represents a Vim buffer, containing source text.
  public struct Buffer {
    /// Returns this buffers `buffer number`.
    public var number: Int = 0

    /// Returns the complete buffer's string representation.
    public var completeBuffer: String = ""

    /// Returns the lines of the text in a buffer, including line endings. 
    public var lines: [String] = []

    /// Returns the variables set in the buffer.
    public var variables: [String] = []

    /// Returns the current `shiftwidth` of the buffer. 
    ///
    /// - seealso: `sw`
    public var shiftWidth: Int = 0

    /// Alias for `shiftWidth`
    ///
    /// - seealso: `shiftWidth`
    public var sw: Int {
      return shiftWidth
    }

    /// Returns the current `tabstop` of the buffer.
    ///
    /// - seealso: `ts`
    public var tabStop: Int = 0

    /// Alias for `tabStop`
    ///
    /// - seealso: `tabStop`
    public var ts: Int {
      return tabStop
    }
  }
}

// MARK: - TextPosition 

extension Vim {
  /// Represents a position in the source code.
  public struct TextPosition: RawRepresentable, Hashable {
    // MARK: - Properties

    /// Representable as a tuple => `(line, column)`
    public var rawValue: (Int, Int) {
      get { return (line, column) }
      set {
        self.line = newValue.0
        self.column = newValue.1
      }
    }

    /// Column in the source code.  1-based index.
    public var column: Int = 0

    /// Line in the source code.  1-based index.
    public var line: Int = 0

    // MARK: - Initializers

    /// Initialize with a raw tuple.
    ///
    /// - parameter rawValue: `(line, column)` pair for the position.
    public init(rawValue: (Int, Int)) {
      self.column = rawValue.0
      self.line = rawValue.1
    }

    /// Default initializer.
    public init() {}

    /// Create a new text position with a given `line` and `column`.
    ///
    /// - parameter line: The line of the position in the source code.
    /// - parameter column: The column of the position in the source code.
    public init(line: Int, column: Int) {
      self.line = line
      self.column = column
    }

    // MARK: - Methods

    public var hashValue: Int {
      return line.hashValue ^ column.hashValue
    }

    /// Returns true if the `lhs` operand is equal to the `rhs` operand.
    ///
    /// - precondition: The text positions must refer to the same file.  If they
    ///   refer to different files, the behavior is undefined.
    public static func ==(lhs: TextPosition, rhs: TextPosition) -> Bool {
      return lhs.column == rhs.column && lhs.line == rhs.line
    }
  }
}

// MARK: - TextRange

extension Vim {
  /// The `TextRange` structure encapsulates a range of text in a buffer or file.
  public struct TextRange: Hashable {
    /// The start of this text range.
    public var start: TextPosition

    /// The end of this text range.
    public var end: TextPosition

    /// Default initializer
    public init(start: TextPosition, end: TextPosition) {
      self.start = start
      self.end = end
    }

    public var hashValue: Int {
      return start.hashValue ^ end.hashValue
    }

    public static func ==(lhs: TextRange, rhs: TextRange) -> Bool {
      return lhs.start == rhs.start && lhs.end == rhs.end
    }
  }
}
