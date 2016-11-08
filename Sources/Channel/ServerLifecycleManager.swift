// ServerLifecycleManager.swift - Manages the lifecycle of a server
//
// This source file is part of the VimChannelKit open source project
//
// Copyright (c) 2014 - 2016 
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// -----------------------------------------------------------------------------
///
/// The `ServerLifecycleManager` is responsible for invoking callbacks during
/// the lifecycle of a given instance of the `Server` class.
///
// -----------------------------------------------------------------------------

import Libc
import Dispatch

/// This class is responsible for managing the lifecycle of a `Server`.
/// It stores and invokes callbacks based on events encountered by the `Server` instance.
class ServerLifecycleManager {
  /// A callback to invoke upon the server encountering an error.
  typealias ErrorCallback = (Swift.Error) -> Void
  
  // MARK: - Properties 

  /// Callbacks to be invoked upon successful startup by the server.
  private var startupCallbacks = [() -> Void]()

  /// Callbacks to be invoked upon shutdown by the server.
  private var shutdownCallbacks = [() -> Void]()

  /// Callbacks to be invoked upon the server encountering an error.
  private var failureCallbacks = [ErrorCallback]()

  /// Callbacks to be invoked upon the delivery of a Unix signal, using `DispatchSource`s
  private var signalSources = [Signal: DispatchSourceSignal]()

  // MARK: - Initializers

  /// Default initializer 
  init() {}

  // MARK: - Methods 

  /// Invoke the callbacks registered for server startup.
  func invokeStartupCallbacks() {
    for callback in startupCallbacks {
      callback()
    }
  }

  /// Invoke the callbacks registered for server shutdown.
  func invokeShutdownCallbacks() {
    for callback in shutdownCallbacks {
      callback()
    }
  }

  /// Invoke the callbacks registered for server failure, with a given error.
  ///
  /// - parameter error: The error that was encountered.
  func invokeFailureCallbacks(withError error: Swift.Error) {
    for callback in failureCallbacks {
      callback(error)
    }
  }

  /// Add a callback to be invoked upon server startup.
  ///
  /// - parameter callback: The callback to add.
  /// - parameter invokeNow: Indicates whether or not the callback should be 
  ///   invoked immediately.  Defaults to `false`.
  func addStartupCallback(invokeNow: Bool = false, _ callback: @escaping () -> Void) {
    if invokeNow { callback() }

    self.startupCallbacks.append(callback)
  }
  
  /// Add a callback to be invoked upon server shutdown.
  ///
  /// - parameter callback: The callback to add.
  /// - parameter invokeNow: Indicates whether or not the callback should be 
  ///   invoked immediately.  Defaults to `false`.
  func addShutdownCallback(invokeNow: Bool = false, _ callback: @escaping () -> Void) {
    if invokeNow { callback() }

    self.shutdownCallbacks.append(callback)
  }
  
  /// Add a callback to be invoked upon server shutdown.
  ///
  /// - parameter callback: The callback to add.
  func addFailureCallback(_ callback: @escaping ErrorCallback) {
    self.failureCallbacks.append(callback)
  }

  /// Add a handler for a signal, using a DispatchSource
  ///
  /// - parameter signal: The signal to handle.
  /// - parameter callback: The action to invoke upon delivery of `signal`.
  func addDispatchSignalHandler(forSignal signal: Signal, _ callback: @escaping () -> Void) {
    _ = Libc.signal(signal.rawValue, SIG_IGN)
    let queue = DispatchQueue.global()
    let source = DispatchSource.makeSignalSource(signal: signal.rawValue, queue: queue)
    source.setEventHandler(handler: callback)
    self.signalSources[signal] = source
    source.resume()
  }

  /// Remove a handler for a given signal, reverting to the default action.
  ///
  /// - parameter signal: The signal for which to remove the handler.
  func removeSignalHandler(forSignal signal: Signal) {
    guard let sigsource = self.signalSources[signal] else { return }
    sigsource.cancel()
    _ = Libc.signal(signal.rawValue, SIG_DFL)
  }
}
