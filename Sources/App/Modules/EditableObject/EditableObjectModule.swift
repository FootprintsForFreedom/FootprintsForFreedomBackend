//
//  EditableTextModule.swift
//  
//
//  Created by niklhut on 09.02.22.
//

import Vapor

struct EditableObjectModule: ModuleInterface {
    func boot(_ app: Application) throws {
        app.migrations.add(EditableObjectMigrations.v1())
    }
}
