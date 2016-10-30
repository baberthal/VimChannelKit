//
//  MessageParserDelegate.swift
//  VimChannelKit
//
//  Created by Morgan Lieberthal on 10/30/16.
//
//

/// The `MessageParserDelegate` protocol defines an interface for responding to events
/// that occur while parsing messages from Vim.
///
/// Currently only JSON encoding is supported.
public protocol MessageParserDelegate: class {
  /// The associated parser encountered whitespace
  ///
  /// - parameter char: The whitespace character that was encountered.
  func onWhitespace(_ char: Character)

  /// The associated parser started a document
  func onDocumentStart()

  /// The associated parser mapped a key
  /// 
  /// - parameter key: The key that was mapped
  func onKey(_ key: String)

  /// The associated parser added a value for a key
  ///
  /// - parameter value: The string representation of the value that was mapped
  func onValue(_ value: String)
}
