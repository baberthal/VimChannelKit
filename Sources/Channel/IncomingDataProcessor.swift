/*
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

/// This protocol defines the API of the classes used to process the data that
/// comes in from a client's request. There should be one `IncomingDataProcessor`
/// instance per incoming request.
public protocol IncomingDataProcessor: class {
  /// A flag to indicate that the socket has a request in progress
  var inProgress: Bool { get set }
  
  /// A back reference to the `Connection` processing the socket that
  /// this `IncomingDataProcessor` is processing.
  weak var handler: SocketHandler? { get set }
  
  /// Process data read from the socket.
  ///
  /// - Parameter buffer: An NSData object containing the data that was read in
  ///                    and needs to be processed.
  ///
  /// - Returns: true if the data was processed, false if it needs to be processed later.
  func process(_ buffer: Data) -> Bool
  
  /// Write data to the socket
  ///
  /// - Parameter from: An NSData object containing the bytes to be written to the socket.
  func write(from data: Data)
  
  /// Write a sequence of bytes in an array to the socket
  ///
  /// - Parameter from: An UnsafeRawPointer to the sequence of bytes to be written to the socket.
  /// - Parameter length: The number of bytes to write to the socket.
  func write(from bytes: UnsafeRawPointer, length: Int)
  
  /// Close the socket and mark this handler as no longer in progress.
  func close()
}
