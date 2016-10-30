//
//  File.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/11/16.
//
//

import Foundation
import LoggerAPI

public class PrintLogger: Logger {
  public func log(_ level: LogLevel, msg: String, file: StaticString,
                  function: StaticString, line: UInt, async: Bool) {
    print("\(level): \(function) \(file):\(line) -- \(msg)")
  }

  public func isLogging(_ level: LogLevel) -> Bool {
    return true
  }

  public static func use() {
    Log.logger = PrintLogger()
    setbuf(stdout, nil)
  }

  required public init(_ level: LogLevel) {}
  init() {}
}
