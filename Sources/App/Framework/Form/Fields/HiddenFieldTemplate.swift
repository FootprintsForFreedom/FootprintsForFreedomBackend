//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import SwiftHtml

public struct HiddenFieldTemplate: TemplateRepresentable {

    var context: HiddenFieldContext
    
    public init(_ context: HiddenFieldContext) {
        self.context = context
    }

    @TagBuilder
    public func render(_ req: Request) -> Tag {
        Input()
            .type(.hidden)
            .name(context.key)
            .value(context.value)
    }
}
