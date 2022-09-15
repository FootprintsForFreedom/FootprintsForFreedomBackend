//
//  ElasticsearchModelInterface.swift
//  
//
//  Created by niklhut on 15.09.22.
//

import Vapor
import Fluent

public protocol ElasticsearchModelInterface: Codable, LockKey {
    associatedtype IDValue: Hashable
    static var schema: String { get }
    
    var id: IDValue { get }
    var languageCode: String { get }
}

extension ElasticsearchModelInterface {
    var uniqueId: String {
        "\(self.id)_\(self.languageCode)"
    }
    
    static func uniqueId(repositoryId: UUID, languageCode: String) -> String {
        "\(repositoryId)_\(languageCode)"
    }
}
