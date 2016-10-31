//
//  Event.swift
//  VimChannelKit
//
//  Created by Morgan Lieberthal on 10/31/16.
//
//

import Foundation

/// An `Event` - Inspired by Python's `Threading.Event`
///
/// `Event`s manage a flag that can be set to `true` with the `set()` method,
/// and reset to `false` with the `clear()` method.
///
/// The `wait()` method blocks until `flag` is `true`.
public struct Event {
  /// The `Condition` used to wait, block, etc.
  private let _condition = Condition()

  /// The flag that this `Event` manages.
  private var _flag: Bool = false

  /// Returns `true` if and only if the internal flag is `true`
  public var isSet: Bool { return self._flag }

  /// Set the internal flag to `true`.
  ///
  /// All threads waiting for the flag to become true are awakened. 
  /// Threads that call `wait()` once the flag is true _will not block at all_.
  public mutating func set() {
    self._condition.whileLocked {
      self._flag = true
      self._condition.broadcast()
    }
  }

  /// Set the internal flag to `false`.
  ///
  /// Threads calling 'wait()` will block until `set()` is called and the
  /// internal flag is `true`.
  public mutating func clear() {
    self._condition.whileLocked {
      self._flag = false
    }
  }

  /// Block until the internal flag is `true`.
  ///
  /// If the internal flag is true on entry, return immediately. Otherwise,
  /// block until another thread calls set() to set the flag to true, or until
  /// the optional timeout occurs.
  ///
  /// - parameter timeout: if present and not `nil`, specifies a timeout for the
  ///             operation in seconds (or fractions thereof).
  ///
  /// - returns: the internal flag on exit, so it will always return
  ///            `true` unless a timeout is given and the operation times out.
  public mutating func wait(timeout: TimeInterval? = nil) -> Bool {
    return self._condition.whileLocked {
      if self._flag == false {
        self._condition.wait(timeout: timeout)
      }

      return self._flag
    }
  }
}
