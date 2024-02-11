import XCTest
@testable import SQLiteParser
import Parsing

final class SqliteParserTests: XCTestCase {
    func testSelectAllStatement() throws {
        try testCases.forEach { (validSelectStatement, selectOrError) in
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

let testCases: [(String, SelectStatementOrError)] = [
    ("SELECT * FROM users;", .select(SelectStatement(tables: [.table("users")], columns: .all, whereClause: nil))),
    ("SELECT id FROM users;", .select(SelectStatement(tables: [.table("users")], columns: .columns(["id"]), whereClause: nil))),
    ("SELECT    *     FROM    users;", .select(SelectStatement(tables: [.table("users")], columns: .all, whereClause: nil))),
    ("""
    SELECT
        *
    FROM
        users;
    """, .select(SelectStatement(tables: [.table("users")], columns: .all, whereClause: nil))),
    ("""
    SELECT
        id
    FROM
        users;
    """, .select(SelectStatement(tables: [.table("users")], columns: .columns(["id"]), whereClause: nil))),
    ("SELECT id, link FROM users;", .select(SelectStatement(tables: [.table("users")], columns: .columns(["id", "link"]), whereClause: nil))),
    ("select * FROM users;", .select(SelectStatement(tables: [.table("users")], columns: .all, whereClause: nil))),
    ("select * from users, other_table;", .select(SelectStatement(tables: [.table("users"), .table("other_table")], columns: .all, whereClause: nil))),
    ("select * from users , other_table;", .select(SelectStatement(tables: [.table("users"), .table("other_table")], columns: .all, whereClause: nil))),
    ("select * from users, other_table ;", .select(SelectStatement(tables: [.table("users"), .table("other_table")], columns: .all, whereClause: nil))),
    ("select * from users WHERE id > 1;", .select(SelectStatement(tables: [.table("users")], columns: .all, whereClause: WhereClause(comparison: .init(first: .column("id"), operation: .bigger, second: .int(1)))))),
]

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
    Optionally { whereParser }
    Whitespace()
    ";".utf8
}.map { (_, column, _, tables, whereClause) in
    SelectStatement(tables: tables, columns: column, whereClause: whereClause)
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
    Prefix {
        $0 != ",".utf8.first && $0 != " ".utf8.first && $0 != "\n".utf8.first
    }
    .compactMap(String.init)
} separator: {
    Whitespace()
    ",".utf8
    Whitespace()
}
.map { Columns.columns($0) }

let allColumns = "*".utf8.map { Columns.all }

let tableParser = Many {
    nameParser
        .map { SelectedTable.table(String($0)) }
} separator: {
    Whitespace()
    ","
    Whitespace()
}

let nameParser = Prefix<Substring> { $0.isLetter || $0 == "_" }

let whereParser = Parse {
    "WHERE"
    Whitespace()
    parseComparison
}
.map(WhereClause.init)

let parseComparison = Parse {
    nameParser.map { ComparisonElement.column(String($0)) }
    Whitespace()
    ">".map { _ in ComparisonOperation.bigger }
    Whitespace()
    Int.parser().map(ComparisonElement.int)
}
.map { firstElement, operation, secondElement in
    Comparison(first: firstElement, operation: operation, second: secondElement)
}

struct SelectStatement: Hashable {
    let tables: [SelectedTable]
    let columns: Columns
    let whereClause: WhereClause?
}

enum SelectedTable: Hashable {
    case table(String)
}

enum Columns: Hashable {
    case all
    case columns(Array<String>)
}

struct WhereClause: Hashable {
    let comparison: Comparison
}

struct Comparison: Hashable {
    let first: ComparisonElement
    let operation: ComparisonOperation
    let second: ComparisonElement
}

enum ComparisonOperation: Hashable {
    case bigger
}

enum ComparisonElement: Hashable {
    case column(String)
    case int(Int)
}
