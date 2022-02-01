//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import SwiftHtml

public struct LinkTemplate: TemplateRepresentable {

    var context: LinkContext
    var body: Tag
    var pathInfix: String?

    public init(_ context: LinkContext, pathInfix: String? = nil, _ builder: ((String) -> Tag)? = nil) {
        self.context = context
        self.pathInfix = pathInfix
        self.body = builder?(context.label) ?? Text(context.label)
    }

    @TagBuilder
    public func render(_ req: Request) -> Tag {
        A { body }
            .href(context.url(req, pathInfix?.pathComponents ?? []))
            .target(.blank, context.isBlank)
    }
}


