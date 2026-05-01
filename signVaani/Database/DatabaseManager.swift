//
//  DatabaseManager.swift
//  signVaani
//
//  Created by Mahak on 11/04/26.
//

import Foundation
import SQLite3

class DatabaseManager {
    //singelton class as only one database is present
    static let shared = DatabaseManager()
    private var db: OpaquePointer?
    
    private init() {
        openDatabase()
    }
    
    private func openDatabase() {
        if let path = Bundle.main.path(forResource: "sign", ofType: "db") {
            if sqlite3_open(path, &db) == SQLITE_OK {
                print("Database opened")
            } else {
                print("Failed to open database")
            }
        } else {
            print("Database file not found")
        }
    }
    
    // MARK: - Core Fetch (with proper binding)
    func getAnimationSmart(for word: String) -> String? {
        
        let normalized = word
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("Searching for:", normalized)
        let query = "SELECT animation_json FROM signs WHERE word = ? LIMIT 1;"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            print("Failed to prepare query")
            return nil
        }
        
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

        normalized.withCString { cString in
            sqlite3_bind_text(statement, 1, cString, -1, SQLITE_TRANSIENT)
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        if sqlite3_step(statement) == SQLITE_ROW {
            
            if let cString = sqlite3_column_text(statement, 0) {
                let result = String(cString: cString)
                return result
            } else {
                print("NULL JSON column for:", normalized)
            }
            
        } else {
            print("NO ROW FOUND for:", normalized)
        }
        
        return nil
    }
}
