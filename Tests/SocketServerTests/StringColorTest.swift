//
//  StringColorTest.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/6/16.
//
//

import XCTest
@testable import LoggerAPI

class StringColorTest: XCTestCase {
  override func setUp() {
    super.setUp()
  }

  override func tearDown() {
    super.tearDown()
  }

  func testColorsAreCorrect() {
    for color in String.availableColors {
      let colorName = color.rawValue
      let theString = "I should be \(colorName)".colorize(color)
      print(theString)
    }

    for color in String.availableColors {
      let colorName = color.rawValue
      let theString = "I should be on a \(colorName) background".colorize(.foreground, on: color)
      print(theString)
    }

    for color in String.availableColors {
      let fgName = color.rawValue
      for background in String.availableColors {
        let bgName = background.rawValue
        let theString = "I should be \(fgName) on \(bgName)".colorize(color, on: background)
        print(theString)
      }
    }
  }
}
