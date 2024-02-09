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
            try validSelectStatementsForGivenTableName.validStatements.forEach { (validSelectStatement, expectedOutput) in
                let result = try selectParser.parse(validSelectStatement)
                XCTAssertEqual(result, expectedOutput)
            }
        }
    }
}

struct SelectTestCase {
    let tableName: String
    
    var validStatements: [(String, SelectStatement)] {
        [
            ("SELECT * FROM \(tableName);", SelectStatement(table: tableName, columns: .all)),
            ("SELECT id FROM \(tableName);", SelectStatement(table: tableName, columns: .columns(["id"]))),
            ("SELECT    *     FROM    \(tableName);", SelectStatement(table: tableName, columns: .all)),
            ("""
            SELECT
                *
            FROM
                \(tableName);
            """, SelectStatement(table: tableName, columns: .all)),
            ("""
            SELECT
                id
            FROM
                \(tableName);
            """, SelectStatement(table: tableName, columns: .columns(["id"]))),
            ("SELECT id, link FROM \(tableName);", SelectStatement(table: tableName, columns: .columns(["id", "link"])))
        ]
    }
}

let selectParser = Parse {
    "SELECT".utf8
    Whitespace()
    columnParser
    Whitespace()
    "FROM".utf8
    Whitespace()
    Prefix { $0 != ";".utf8.first }
    ";".utf8
}.map { (column, tableName) in
    SelectStatement(table: String(tableName)!, columns: column)
}

let columnParser = OneOf {
    allColumns
    multipleColumns
}

let multipleColumns = Many {
    Prefix { $0 != ",".utf8.first && $0 != " ".utf8.first && $0 != "\n".utf8.first }.compactMap(String.init)
} separator: {
    Whitespace()
    ",".utf8
    Whitespace()
}
.map { Columns.columns($0) }

let allColumns = "*".utf8.map { Columns.all }

struct SelectStatement: Hashable {
    let table: String
    let columns: Columns
}

enum Columns: Hashable {
    case all
    case columns(Array<String>)
}
