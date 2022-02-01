//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

public final class HiddenField: AbstractFormField<String, HiddenFieldTemplate> {

    public convenience init(_ key: String) {
        self.init(key: key, input: "", output: .init(.init(key: key)))
    }
    
    public override func process(req: Request) async throws {
        try await super.process(req: req)
        output.context.value = input
    }
}

