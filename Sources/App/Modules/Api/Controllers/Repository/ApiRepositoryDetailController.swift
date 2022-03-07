//
//  ApiRepositoryDetailController.swift
//  
//
//  Created by niklhut on 07.03.22.
//

import Vapor

protocol ApiRepositoryDetailController: RepositoryController, ApiDetailController {
    func detailOutput(_ req: Request, _ repository: DatabaseModel, _ waypoint: ObjectModel) async throws -> DetailObject
}
