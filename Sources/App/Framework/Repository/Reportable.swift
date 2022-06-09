//
//  Reportable.swift
//  
//
//  Created by niklhut on 09.06.22.
//

import Fluent

protocol Reportable where Self: RepositoryModel {
    associatedtype Report: ReportModel
    
    var reports: [Report] { get }
    var _$reports: ChildrenProperty<Self, Report> { get }
}
