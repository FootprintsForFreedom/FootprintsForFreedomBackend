//
//  File.swift
//  
//
//  Created by niklhut on 21.03.22.
//

import Foundation
import DiffMatchPatch

public extension Waypoint {
    enum Repository: ApiModelInterface {
        public typealias Module = AppApi.Waypoint
    }
}

public extension Waypoint.Repository {
    struct DetailChangesRequest: Codable {
        public let from: UUID
        public let to: UUID
        
        public init(from: UUID, to: UUID) {
            self.from = from
            self.to = to
        }
    }
    
    struct ListUnverifiedWaypoints: Codable {
        public let modelId: UUID
        public let title: String
        public let detailText: String
        public let languageCode: String
        
        public init(modelId: UUID, title: String, detailText: String, languageCode: String) {
            self.modelId = modelId
            self.title = title
            self.detailText = detailText
            self.languageCode = languageCode
        }
    }
    
    struct ListUnverifiedLocations: Codable {
        public let locationId: UUID
        public let location: Waypoint.Location
        
        public init(locationId: UUID, location: Waypoint.Location) {
            self.locationId = locationId
            self.location = location
        }
    }
    
    struct Changes: Codable {
        public let titleDiff: [Diff]
        public let detailTextDiff: [Diff]
        public let fromUser: User.Account.Detail
        public let toUser: User.Account.Detail
        
        public init(titleDiff: [Diff], detailTextDiff: [Diff], fromUser: User.Account.Detail, toUser: User.Account.Detail) {
            self.titleDiff = titleDiff
            self.detailTextDiff = detailTextDiff
            self.fromUser = fromUser
            self.toUser = toUser
        }
    }
}
