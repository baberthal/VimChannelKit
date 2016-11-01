//
//  SynchronizedQueue.swift
//  VimChannelKit
//
//  Created by Morgan Lieberthal on 11/1/16.
//
//

/// This class can be used as a shared queue between multiple threads
/// providing thread-safe APIs.
public final class SynchronizedQueue<Element> {
  /// Storage for the queue
  private var storage: [Element]

  /// Condition variable to block the thread trying to dequeue
  private var notEmptyCondition: Condition

  /// Create a new `SynchronizedQueue`
  public init() {
    storage = []
    notEmptyCondition = Condition()
  }

  /// Safely enqueue an element to the end of the queue, and signal a blocked thread
  /// upon dequeue.
  ///
  /// - parameters:
  ///    - element: The element to be enqueued.
  public func enqueue(_ element: Element) {
    notEmptyCondition.whileLocked {
      storage.append(element)
      notEmptyCondition.signal()
    }
  }

  /// Dequeue an element from the _front_ of the queue. Blocks the calling thread 
  /// until the element is available.
  ///
  /// - returns: The first element in the queue.
  public func dequeue() -> Element {
    return notEmptyCondition.whileLocked {
      while storage.isEmpty {
        notEmptyCondition.wait()
      }

      // FIXME: This is O(n), should be optimized
      return storage.removeFirst()
    }
  }
}
