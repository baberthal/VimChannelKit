//
//  Lock.swift
//  VimChannelKit
//
//  Created by Morgan Lieberthal on 10/31/16.
//
//

import Foundation

/// A simple Lock wrapper
public struct Lock {
  private var _lock = NSLock()

  /// Create a new lock
  public init() {}

  /// Execute the given block while holding the lock
  /// 
  /// - parameter block: The block to execute.
  /// - returns: The result of calling `block()`.
  public mutating func withLock<T>(_ block: () throws -> T) rethrows -> T {
    _lock.lock()
    defer { _lock.unlock() }
    return try block()
  }
}
