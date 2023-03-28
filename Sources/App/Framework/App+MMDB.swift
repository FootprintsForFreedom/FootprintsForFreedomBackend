//
//  App+MMDB.swift
//  
//
//  Created by niklhut on 30.12.22.
//

import Vapor
import MMDB

extension Application {
    var mmdb: MMDBObject {
        .init(application: self)
    }
    
    struct MMDBObject {
        let application: Application
        
        struct Key: StorageKey {
            typealias Value = MMDB
        }
        
        var mmdb: MMDB {
            if self.application.storage[Key.self] == nil {
                try! self.loadMMDB()
            }
            return self.application.storage[Key.self]!
        }
        
        func loadMMDB() throws {
            let url = URL(fileURLWithPath: application.directory.resourcesDirectory).appendingPathComponent(Environment.mmdbPath)
            self.application.storage[Key.self] = try! .init(from: url)
        }
    }
}

extension Request {
    var mmdb: MMDB {
        application.mmdb.mmdb
    }
}
