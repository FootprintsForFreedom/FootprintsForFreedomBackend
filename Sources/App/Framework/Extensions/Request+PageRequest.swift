//
//  Request+PageRequest.swift
//  
//
//  Created by niklhut on 10.10.22.
//

import Vapor
import Fluent

extension Request {
    var pageRequest: PageRequest {
        get throws {
            let pageRequest = try self.query.decode(PageRequest.self)
            return PageRequest(page: max(pageRequest.page, 1), per: max(pageRequest.per, 1))
        }
    }
}
