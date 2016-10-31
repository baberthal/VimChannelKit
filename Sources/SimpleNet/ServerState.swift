//
//  ServerState.swift
//  VimChannelKit
//
//  Created by Morgan Lieberthal on 10/30/16.
//
//

/// Represents the state of a given server
public enum ServerState {
  /// The initial state of a `Server`
  case unknown
  /// Indicates the `Server` has started
  case started
  /// Indicates the `Server` has stopped
  case stopped
  /// Indicates the `Server` has encountered an error
  case failed
}
