//
//  MessageTests.swift
//  SocketServer
//
//  Created by Morgan Lieberthal on 10/10/16.
//
//

import XCTest
@testable import SocketServer

class MessageTests: XCTestCase {
  var request: VimMessage!
  var response: VimMessage!
  
  override func setUp() {
    super.setUp()
    self.request = VimMessage(1, body: "hello!")
    self.response = VimMessage(1, body: "got it!")
  }
  
  override func tearDown() {
    super.tearDown()
  }

  func testMessageID() {
    XCTAssert(request.id == response.id)
    XCTAssert(request.body == "hello!")
    XCTAssert(response.body == "got it!")
  }

  func testMessageJSON() {
  }

  //  func testPerformanceExample() {
  //    self.measure {
  //    }
  //  }
}
