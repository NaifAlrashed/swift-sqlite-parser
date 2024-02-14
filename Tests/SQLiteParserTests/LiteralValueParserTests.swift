//
//  LiteralValueParserTests.swift
//  
//
//  Created by Naif Alrashed on 14/02/2024.
//

import XCTest
@testable import SQLiteParser

final class LiteralValueParserTests: XCTestCase {
    func testCanParseInteger() throws {
        for i in (UInt.max-500)...UInt.max {
            let stringValue = "\(i)"
            try XCTAssertEqual(numericLiteralParser.parse(stringValue[...]), Double(i))
        }
        for i in 0...500 as ClosedRange<UInt> {
            let stringValue = "\(i)"
            try XCTAssertEqual(numericLiteralParser.parse(stringValue[...]), Double(i))
        }
    }
    
    func testCanParseFloatingPointValuesStartingWithDot() throws {
        for i in 0...500 {
            let stringValue = ".\(i)"
            let double = Double(stringValue)!
            try XCTAssertEqual(numericLiteralParser.parse(stringValue[...]), double)
        }
    }
}