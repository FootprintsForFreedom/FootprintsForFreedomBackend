//
//  Subset+Page.swift
//  
//
//  Created by niklhut on 08.01.23.
//

import Fluent

extension Subset {
    static func from(_ page: Page<T>) -> Self {
        return .init(items: page.items, metadata: .from(page.metadata))
    }
}

extension SubsetMetadata {
    static func from(_ pageMetadata: PageMetadata) -> Self {
        return .init(page: pageMetadata.page, per: pageMetadata.per, total: pageMetadata.total)
    }
}
