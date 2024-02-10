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
            ("SELECT * FROM \(tableName);", SelectStatement(tables: [.table(tableName)], columns: .all)),
            ("SELECT id FROM \(tableName);", SelectStatement(tables: [.table(tableName)], columns: .columns(["id"]))),
            ("SELECT    *     FROM    \(tableName);", SelectStatement(tables: [.table(tableName)], columns: .all)),
            ("""
            SELECT
                *
            FROM
                \(tableName);
            """, SelectStatement(tables: [.table(tableName)], columns: .all)),
            ("""
            SELECT
                id
            FROM
                \(tableName);
            """, SelectStatement(tables: [.table(tableName)], columns: .columns(["id"]))),
            ("SELECT id, link FROM \(tableName);", SelectStatement(tables: [.table(tableName)], columns: .columns(["id", "link"]))),
            ("select * FROM \(tableName);", SelectStatement(tables: [.table(tableName)], columns: .all)),
            ("select * from \(tableName);", SelectStatement(tables: [.table(tableName)], columns: .all)),
        ]
    }
}

let selectParser = Parse {
    "SELECT".ignoreCase
    Whitespace()
    columnParser
    Whitespace()
    "FROM".ignoreCase
    Whitespace()
    Prefix { $0 != ";".utf8.first }
    ";".utf8
}.map { (_, column, _, tableName) in
    SelectStatement(tables: [.table(String(tableName)!)], columns: column)
}

extension String {
    var ignoreCase: Parsers.Filter<Prefix<Substring>> {
        let lowercaseMatch = self.lowercased()
        return Prefix<Substring>
            .init(while: \.isLetter)
            .filter { $0.lowercased() == lowercaseMatch }
    }
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
    let tables: [SelectedTable]
    let columns: Columns
}

enum SelectedTable: Hashable {
    case table(String)
}

enum Columns: Hashable {
    case all
    case columns(Array<String>)
}
