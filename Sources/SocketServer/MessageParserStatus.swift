//
//  MessageParserStatus.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/11/16.
//
//

/// Represents the status of the MessageParser
struct MessageParserStatus {
  /// List of parser states
  enum State {
    /// The parser is in its `initial` state
    case initial
    /// The message has been read
    case messageComplete
    /// The parser is in a `reset` state
    case reset
  }

  /// Represents an error that occurs when dealing with the `MessageParser`
  enum ErrorType: Swift.Error {
    /// Unexpectedly got EOF
    case unexpectedEOF
    /// A JSON object was invalid
    case invalidJSON
    /// We parsed fewer bytes than we read
    case parsedTooFew
    /// An internal error occured
    case `internal`
  }

  init() { }

  /// The state of the parser
  var state: State  = .initial

  /// An error, if one occured
  var error: ErrorType? = nil

  mutating func reset() {
    self.state = .initial
    self.error = nil
  }
}

extension MessageParserStatus.ErrorType: CustomStringConvertible {
  var description: String {
    switch self {
    case .unexpectedEOF: return "Unexpectedly got EOF while reading the request."
    case .invalidJSON: return "Invalid json object."
    case .parsedTooFew: return "Parsed fewer bytes than read!"
    case .internal: return "An internal error occured."
    }
  }
}
