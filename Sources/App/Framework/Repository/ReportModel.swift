//
//  ReportModel.swift
//  
//
//  Created by niklhut on 08.06.22.
//

import Vapor
import Fluent

protocol ReportModel: DatabaseModelInterface, Timestamped, Titled, Slugable {
    associatedtype Repository: RepositoryModel
    
    var _$slug: FieldProperty<Self, String> { get }
    
    var status: Status { get set }
    var _$status: EnumProperty<Self, Status> { get }
    
    var reason: String { get set }
    var _$reason: FieldProperty<Self, String> { get }
    
    var visibleDetail: Repository.Detail? { get set }
    var _$visibleDetail: OptionalParentProperty<Self, Repository.Detail> { get }
    
    var repository: Repository { get }
    var _$repository: ParentProperty<Self, Repository> { get }
    
    var user: UserAccountModel? { get }
    var _$user: OptionalParentProperty<Self, UserAccountModel> { get }
    
    var _$updatedAt: TimestampProperty<Self, DefaultTimestampFormat> { get }
}
