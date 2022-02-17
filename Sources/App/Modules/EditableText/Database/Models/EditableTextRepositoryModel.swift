//
//  EditableTextRepositoryModel.swift
//  
//
//  Created by niklhut on 09.02.22.
//

import Vapor
import Fluent

final class EditableTextRepositoryModel: DatabaseModelInterface, LinkedListModel {
    typealias Module = EditableTextModule
    typealias NodeObject = EditableTextObjectModel
    
    static let identifier = "repositories"
    
    @ID() var id: UUID?
    @OptionalChild(for: \.$currentObjectInList) var current: EditableTextObjectModel?
    @OptionalChild(for: \.$lastObjectInList) var last: EditableTextObjectModel?
    
    var currentProperty: OptionalChildProperty<EditableTextRepositoryModel, EditableTextObjectModel> { $current }
    var lastProperty: OptionalChildProperty<EditableTextRepositoryModel, EditableTextObjectModel> { $last }
    
    init() { }
}
