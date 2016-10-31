//
//  Condition.swift
//  VimChannelKit
//
//  Created by Morgan Lieberthal on 10/31/16.
//
//

import Foundation

/// A simple condition wrapper
public struct Condition {
  private let _condition = NSCondition()

  /// Creates a new `Condition`
  public init() {}

  /// Wait for this condition to become available
  ///
  /// - parameter timeout: An optional timeout value (in seconds)
  public func wait(timeout seconds: TimeInterval? = nil) {
    guard let timeout = seconds else {
      _condition.wait()
      return
    }

    let timeoutDate = Date(timeIntervalSinceNow: timeout)
    _condition.wait(until: timeoutDate)
  }
  
  /// Signal the availability of this condition
  /// (awake one thread waiting on the condition).
  public func signal() {
    _condition.signal()
  }

  /// Broadcast the availability of the condition
  /// (awake all threads waiting on the condition).
  public func broadcast() {
    _condition.broadcast()
  }

  /// Executes `block` while the condition is locked.
  /// 
  /// - parameter block: The block to execute.
  /// - returns: The result of calling `block()`.
  public func whileLocked<T>(_ block: () throws -> T) rethrows -> T {
    _condition.lock()
    defer { _condition.unlock() }
    return try block()
  }
}
