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
            try validSelectStatementsForGivenTableName.validStatements.forEach { (validSelectStatement, selectOrError) in
                do {
                    let result = try selectParser.parse(validSelectStatement)
                    if case let .select(expectedOutput) = selectOrError {
                        XCTAssertEqual(result, expectedOutput)
                    } else {
                        XCTFail("expected to throw an error but the operation succeeded")
                    }
                } catch {
                    if selectOrError != .error {
                        throw error
                    }
                }
            }
        }
    }
}

struct SelectTestCase {
    let tableName: String
    
    var validStatements: [(String, SelectStatementOrError)] {
        [
            ("SELECT * FROM \(tableName);", .select(SelectStatement(tables: [.table(tableName)], columns: .all))),
            ("SELECT id FROM \(tableName);", .select(SelectStatement(tables: [.table(tableName)], columns: .columns(["id"])))),
            ("SELECT    *     FROM    \(tableName);", .select(SelectStatement(tables: [.table(tableName)], columns: .all))),
            ("""
            SELECT
                *
            FROM
                \(tableName);
            """, .select(SelectStatement(tables: [.table(tableName)], columns: .all))),
            ("""
            SELECT
                id
            FROM
                \(tableName);
            """, .select(SelectStatement(tables: [.table(tableName)], columns: .columns(["id"])))),
            ("SELECT id, link FROM \(tableName);", .select(SelectStatement(tables: [.table(tableName)], columns: .columns(["id", "link"])))),
            ("select * FROM \(tableName);", .select(SelectStatement(tables: [.table(tableName)], columns: .all))),
            ("select * from \(tableName), other_table;", .select(SelectStatement(tables: [.table(tableName), .table("other_table")], columns: .all))),
            ("select * from \(tableName) , other_table;", .select(SelectStatement(tables: [.table(tableName), .table("other_table")], columns: .all))),
            ("select * from \(tableName), other_table ;", .select(SelectStatement(tables: [.table(tableName), .table("other_table")], columns: .all))),
        ]
    }
}

enum SelectStatementOrError: Hashable {
    case select(SelectStatement)
    case error
}

let selectParser = Parse {
    "SELECT".ignoreCase
    Whitespace()
    columnParser
    Whitespace()
    "FROM".ignoreCase
    Whitespace()
    tableParser
    Whitespace()
    ";".utf8
}.map { (_, column, _, tables) in
    SelectStatement(tables: tables, columns: column)
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

let tableParser = Many {
    Prefix<Substring> { $0.isLetter || $0 == "_" }
        .map { SelectedTable.table(String($0)) }
} separator: {
    Whitespace()
    ","
    Whitespace()
}

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
