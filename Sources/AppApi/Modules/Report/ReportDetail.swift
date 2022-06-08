//
//  ReportDetail.swift
//  
//
//  Created by niklhut on 08.06.22.
//

import Foundation

public extension Report {
    struct List: Codable {
        public let id: UUID
        public let title: String
        public let slug: String
        
        public init(id: UUID, title: String, slug: String) {
            self.id = id
            self.title = title
            self.slug = slug
        }
    }
    
    struct Detail<DetailModel: Codable>: Codable {
        public let id: UUID
        public let title: String
        public let slug: String
        public let reason: String
        public let visibleDetail: DetailModel?
        public let status: Status
        public let reportId: UUID
        
        public init(id: UUID, title: String, slug: String, reason: String, visibleDetail: DetailModel?, status: Status, reportId: UUID) {
            self.id = id
            self.title = title
            self.slug = slug
            self.reason = reason
            self.visibleDetail = visibleDetail
            self.status = status
            self.reportId = reportId
        }
    }
    
    struct Create: Codable {
        public let title: String
        public let reason: String
        public let visibleDetailId: UUID
        
        public init(title: String, reason: String, visibleDetailId: UUID) {
            self.title = title
            self.reason = reason
            self.visibleDetailId = visibleDetailId
        }
    }
}
