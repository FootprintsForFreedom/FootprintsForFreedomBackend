//
//  EditableTextModule.swift
//  
//
//  Created by niklhut on 09.02.22.
//

import Vapor

struct EditableTextModule: ModuleInterface {
    func boot(_ app: Application) throws {
        app.migrations.add(EditableTextMigrations.v1())
    }
}
