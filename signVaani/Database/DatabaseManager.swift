//
//  DatabaseManager.swift
//  signVaani
//
//  Created by Mahak on 11/04/26.
//

import Foundation
import SQLite3  //C API for interacting with SQLite DB

class DatabaseManager {
    //singelton class to ensure only one database connection exists
    static let shared = DatabaseManager()
    private var db: OpaquePointer?  //OpaquePointer is pointer to SQLite DB. It is used to represent C pointers in swift as SQLite is written in C.
    private var cache: [String: String] = [:]
    //prevents external instantiation and automatically opens DB when singleton is created
    private init() {
        openDatabase()
    }
    
    private func openDatabase() {
        //opens db file in app bundle (read only)
        if let path = Bundle.main.path(forResource: "sign", ofType: "db") {
            //sqlite3_open returns SQLITE_OK if db is opened and stores its reference in &db
            if sqlite3_open(path, &db) == SQLITE_OK {
                print("Database opened")
            } else {
                print("Failed to open database")
            }
        } else {
            print("Database file not found")
        }
    }
    func hasGloss(for word: String) -> Bool {

        let normalized = word
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let query = """
        SELECT 1
        FROM signs
        WHERE word = ?
        LIMIT 1;
        """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return false
        }

        defer {
            sqlite3_finalize(statement)
        }

        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

        let _ : Int32 = normalized.withCString { cString in
            sqlite3_bind_text(statement, 1, cString, -1, SQLITE_TRANSIENT)
        }

        return sqlite3_step(statement) == SQLITE_ROW
    }
    func getAnimationSmart(for word: String) -> String? {

        let normalized = word
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // MEMORY CACHE
        if let cached = cache[normalized] {
            return cached
        }

        let query = """
        SELECT animation_json
        FROM signs
        WHERE word = ?
        LIMIT 1;
        """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return nil
        }

        defer {
            sqlite3_finalize(statement)
        }

        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

        let _ : Int32 = normalized.withCString { cString in
            sqlite3_bind_text(statement, 1, cString, -1, SQLITE_TRANSIENT)
        }

        if sqlite3_step(statement) == SQLITE_ROW {

            if let cString = sqlite3_column_text(statement, 0) {

                let result = String(cString: cString)

                cache[normalized] = result

                return result
            }
        }

        return nil
    }
}

