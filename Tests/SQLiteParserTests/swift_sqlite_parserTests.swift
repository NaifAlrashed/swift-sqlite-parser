import XCTest
@testable import SQLiteParser
import Parsing

final class SqliteParserTests: XCTestCase {
    func testSelectAllStatement() throws {
        let validSelectStatementWithDifferentTableNames: [SelectTestCase] = [
            SelectTestCase(tableName: "users"),
            SelectTestCase(tableName: "employees"),
        ]
        try validSelectStatementWithDifferentTableNames.forEach { validSelectStatementsForGivenTableName in
            let expectedOutput = SelectStatement(
                table: validSelectStatementsForGivenTableName.tableName,
                columns: .all
            )
            try validSelectStatementsForGivenTableName.validStatements.forEach { validSelectStatement in
                let result = try selectParser.parse(validSelectStatement)
                XCTAssertEqual(result, expectedOutput)
            }
        }
    }
}

struct SelectTestCase {
    let tableName: String
    
    var validStatements: [String] {
        [
            "SELECT * FROM \(tableName);",
            "SELECT    *     FROM    \(tableName);",
            """
            SELECT
                *
            FROM
                \(tableName);
            """
        ]
    }
}

let selectParser = Parse {
    "SELECT".utf8
    Whitespace()
    "*".utf8
    Whitespace()
    "FROM".utf8
    Whitespace()
    Prefix { $0 != ";".utf8.first }
    ";".utf8
}.map { tableName in
    SelectStatement(table: String(tableName)!, columns: .all)
}

struct SelectStatement: Hashable {
    let table: String
    let columns: Columns
}

enum Columns: Hashable {
    case all
}
