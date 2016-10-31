//
//  LifecycleManager.swift
//  VimChannelKit
//
//  Created by Morgan Lieberthal on 10/30/16.
//
//

/// This class is responsible for managing the lifecycle of a `Server`.
/// It stores and invokes callbacks based on events encountered by the `Server` instance.
class LifecycleManager {
  /// Callbacks to be invoked upon successful startup by the server
  private var startupCallbacks = [() -> Void]()

  /// Callbacks to be invoked upon shutdown by the server
  private var shutdownCallbacks = [() -> Void]()

  /// Callbacks to be invoked upon the server encountering an error
  private var failureCallbacks = [ServerErrorHandler]()

  /// Default initializer 
  init() {}

  /// Perform all `startup` callbacks
  func doStartupCallbacks() {
    for callback in startupCallbacks {
      callback()
    }
  }

  /// Perform all `shutdown` callbacks
  func doShutdownCallbacks() {
    for callback in shutdownCallbacks {
      callback()
    }
  }

  /// Perform all `failure` callbacks
  ///
  /// - parameter error: The error to invoke the callback with
  func doFailureCallbacks(with error: Swift.Error) {
    for callback in failureCallbacks {
      callback(error)
    }
  }

  /// Add a `startup` callback, and invoke it immediately if needed.
  ///
  /// - parameter invokeNow: Whether or not to invoke the callback immediately
  /// - parameter callback: The callback to add
  func addStartupCallback(invokeNow: Bool = false, _ callback: @escaping () -> Void) {
    if invokeNow { callback() }
    self.startupCallbacks.append(callback)
  }
  
  /// Add a `shutdown` callback, and invoke it immediately if needed.
  ///
  /// - parameter invokeNow: Whether or not to invoke the callback immediately
  /// - parameter callback: The callback to add
  func addShutdownCallback(invokeNow: Bool = false, _ callback: @escaping () -> Void) {
    if invokeNow { callback() }
    self.shutdownCallbacks.append(callback)
  }
  
  /// Add a `failure` callback, and invoke it immediately if needed.
  ///
  /// - parameter invokeNow: Whether or not to invoke the callback immediately
  /// - parameter callback: The callback to add
  func addFailureCallback(_ callback: @escaping ServerErrorHandler) {
    self.failureCallbacks.append(callback)
  }
}
