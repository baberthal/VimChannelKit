//
//  RequestMessage.swift
//  VimChannelKit
//
//  Created by Morgan Lieberthal on 10/30/16.
//
//

import Socket
import SwiftyJSON

// MARK: RequestMessage

public class RequestMessage {
  // MARK: - Properties

  /// The message associated with this request
  public internal(set) var message = Message()

  /// The remote host address
  public var remoteAddress: String {
    return clientSocket.prettyHost
  }

  /// The `id` of our message
  public var id: Int {
    get { return message.id }
    set { message.id = newValue }
  }

  /// The `body` of our message
  public var body: JSON {
    get { return message.body }
    set { message.body = newValue }
  }

  /// The client socket that the connection is using to communicate
  private var clientSocket: Socket

  // MARK: - Initializers

  /// Create a `RequestMessage` over a given socket
  init(socket: Socket) {
    self.clientSocket = socket
  }

  // MARK: - Methods

  
}
