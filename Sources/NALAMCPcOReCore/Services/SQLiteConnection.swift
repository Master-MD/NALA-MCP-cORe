import CSQLite
import Foundation

public enum SQLiteValue {
    case text(String)
    case int(Int)
    case null
}

public typealias SQLiteRow = [String: String]

public final class SQLiteConnection {
    private var database: OpaquePointer?
    private let path: String
    private let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    public init(path: String) throws {
        self.path = path
        if sqlite3_open(path, &database) != SQLITE_OK {
            throw StableCoreError.databaseOpenFailed(lastError)
        }
    }

    deinit {
        sqlite3_close(database)
    }

    public func execute(_ sql: String, parameters: [SQLiteValue] = []) throws {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw StableCoreError.databaseExecutionFailed(lastError)
        }
        defer { sqlite3_finalize(statement) }

        try bind(parameters, to: statement)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw StableCoreError.databaseExecutionFailed(lastError)
        }
    }

    public func query(_ sql: String, parameters: [SQLiteValue] = []) throws -> [SQLiteRow] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw StableCoreError.databaseExecutionFailed(lastError)
        }
        defer { sqlite3_finalize(statement) }

        try bind(parameters, to: statement)

        var rows: [SQLiteRow] = []
        while true {
            let result = sqlite3_step(statement)
            if result == SQLITE_ROW {
                var row: SQLiteRow = [:]
                for index in 0..<sqlite3_column_count(statement) {
                    let name = String(cString: sqlite3_column_name(statement, index))
                    if let text = sqlite3_column_text(statement, index) {
                        row[name] = String(cString: text)
                    } else {
                        row[name] = ""
                    }
                }
                rows.append(row)
            } else if result == SQLITE_DONE {
                return rows
            } else {
                throw StableCoreError.databaseExecutionFailed(lastError)
            }
        }
    }

    public func scalarString(_ sql: String, parameters: [SQLiteValue] = []) throws -> String {
        try query(sql, parameters: parameters).first?.values.first ?? ""
    }

    private func bind(_ parameters: [SQLiteValue], to statement: OpaquePointer?) throws {
        for (offset, parameter) in parameters.enumerated() {
            let index = Int32(offset + 1)
            let result: Int32
            switch parameter {
            case .text(let value):
                result = sqlite3_bind_text(statement, index, value, -1, transient)
            case .int(let value):
                result = sqlite3_bind_int64(statement, index, sqlite3_int64(value))
            case .null:
                result = sqlite3_bind_null(statement, index)
            }
            guard result == SQLITE_OK else {
                throw StableCoreError.databaseExecutionFailed(lastError)
            }
        }
    }

    private var lastError: String {
        if let database, let message = sqlite3_errmsg(database) {
            return String(cString: message)
        }
        return "Unknown SQLite error for \(path)"
    }
}
