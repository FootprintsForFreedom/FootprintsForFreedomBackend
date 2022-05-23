//
//  TagApiController.swift
//  
//
//  Created by niklhut on 21.05.22.
//

import Vapor
import Fluent

struct TagApiController: ApiController {
    typealias ApiModel = Tag.Detail
    typealias DatabaseModel = TagRepositoryModel
}
