//
//  Page+Page.swift
//  
//
//  Created by niklhut on 08.01.23.
//

import Vapor
import Fluent
import AppApi

extension AppApi.Page: AsyncRequestDecodable, AsyncResponseEncodable, RequestDecodable, ResponseEncodable, Content where T: Codable { }

extension AppApi.Page {
    static func from(_ page: Fluent.Page<T>) -> Self {
        return .init(items: page.items, metadata: .from(page.metadata))
    }
}

extension AppApi.PageMetadata {
    static func from(_ pageMetadata: Fluent.PageMetadata) -> Self {
        return .init(page: pageMetadata.page, per: pageMetadata.per, total: pageMetadata.total)
    }
}
