//
//  RepositoryController.swift
//  
//
//  Created by niklhut on 07.03.22.
//

import Vapor

protocol RepositoryController: ModelController {
    associatedtype ObjectModel: DatabaseModelInterface
}
