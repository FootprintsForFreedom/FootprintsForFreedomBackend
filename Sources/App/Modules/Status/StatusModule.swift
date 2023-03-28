//
//  StatusModule.swift
//  
//
//  Created by niklhut on 05.06.22.
//

import Vapor

struct StatusModule: ModuleInterface {
    func boot(_ app: Application) throws {
        app.migrations.add(StatusMigrations.v1())
    }
}
