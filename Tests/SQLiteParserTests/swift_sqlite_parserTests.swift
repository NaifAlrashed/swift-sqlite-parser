import XCTest
@testable import SQLiteParser
import Parsing

final class SqliteParserTests: XCTestCase {
    func testSelectStatement() throws {
        let validSelectStatements = [
            "SELECT * FROM users;",
            "SELECT    *     FROM    users;",
            """
            SELECT
                *
            FROM
                users;
            """
        ]
        let expectedOutput = SelectStatement(table: "users", columns: .all)
        try validSelectStatements.forEach { validSelectStatement in
            let result = try selectParser.parse("SELECT * FROM users;")
            XCTAssertEqual(result, expectedOutput)
        }
    }
}

let selectParser = Parse {
    "SELECT".utf8
    Whitespace()
    "*".utf8
    Whitespace()
    "FROM".utf8
    Whitespace()
    "users;".utf8
}.map { _ in
    SelectStatement(table: "users", columns: .all)
}

struct SelectStatement: Hashable {
    let table: String
    let columns: Columns
}

enum Columns: Hashable {
    case all
}
