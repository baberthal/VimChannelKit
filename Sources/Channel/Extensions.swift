//
//  Extensions.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/6/16.
//
//

import Socket

extension Socket {
  /// Returns a 'pretty' version of the remoteHostname:remotePort pair
  public var prettyHost: String {
    return "\(remoteHostname):\(remotePort)"
  }
}
