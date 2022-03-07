//
//  StorableMigrations.swift
//  
//
//  Created by niklhut on 09.02.22.
//

import Vapor

struct StorableModule: ModuleInterface {
    func boot(_ app: Application) throws {
        app.migrations.add(StorableMigrations.v1())
    }
}
