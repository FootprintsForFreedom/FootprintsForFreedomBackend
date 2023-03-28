//
//  Reportable.swift
//  
//
//  Created by niklhut on 09.06.22.
//

import Fluent

/// A repository model which can be reported.
protocol Reportable where Self: RepositoryModel {
    /// The report model which belongs to the repository.
    associatedtype Report: ReportModel
    
    /// The repositories reports.
    var reports: [Report] { get }
    /// The repositories reports.
    var _$reports: ChildrenProperty<Self, Report> { get }
}
