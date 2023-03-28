//
//  ReportDetail.swift
//  
//
//  Created by niklhut on 08.06.22.
//

import Foundation

public extension Report {
    /// Used to list report objects.
    struct List: Codable {
        /// Id uniquely identifying the report.
        public let id: UUID
        /// The report title.
        public let title: String
        /// The slug uniquely identifying the report.
        public let slug: String
        
        /// Creates a report list object.
        /// - Parameters:
        ///   - id: Id uniquely identifying the report.
        ///   - title: The report title.
        ///   - slug: The slug uniquely identifying the report.
        public init(id: UUID, title: String, slug: String) {
            self.id = id
            self.title = title
            self.slug = slug
        }
    }
    
    /// Used to detail report objects.
    struct Detail<DetailModel: Codable>: Codable {
        /// Id uniquely identifying the repository to which the report belongs..
        public let id: UUID
        /// The report title.
        public let title: String
        /// The slug uniquely identifying the report.
        public let slug: String
        /// The reason to report the detail object.
        public let reason: String
        /// The detail object which was visible while the report was created. This is so it is known to which language this report belongs and wether the detail object has since been updated.
        public let visibleDetail: DetailModel?
        /// Id uniquely identifying the report.
        public let reportId: UUID
        
        /// Creates a report detail object.
        /// - Parameters:
        ///   - id: Id uniquely identifying the repository to which the report belongs..
        ///   - title: The report title.
        ///   - slug: The slug uniquely identifying the report.
        ///   - reason: The reason to report the detail object.
        ///   - visibleDetail: The detail object which was visible while the report was created. This is so it is known to which language this report belongs and wether the detail object has since been updated.
        ///   - reportId: Id uniquely identifying the report.
        public init(id: UUID, title: String, slug: String, reason: String, visibleDetail: DetailModel?, reportId: UUID) {
            self.id = id
            self.title = title
            self.slug = slug
            self.reason = reason
            self.visibleDetail = visibleDetail
            self.reportId = reportId
        }
    }
    
    /// Used to create report objects.
    struct Create: Codable {
        /// The report title.
        public let title: String
        /// The reason to report the detail object.
        public let reason: String
        /// The currently visible detail id. This is so it is known to which language this report belongs and wether the detail object has since been updated.
        public let visibleDetailId: UUID
        
        /// Creates a report create object.
        /// - Parameters:
        ///   - title: The report title.
        ///   - reason: The reason to report the detail object.
        ///   - visibleDetailId: The currently visible detail id. This is so it is known to which language this report belongs and wether the detail object has since been updated.
        public init(title: String, reason: String, visibleDetailId: UUID) {
            self.title = title
            self.reason = reason
            self.visibleDetailId = visibleDetailId
        }
    }
}
