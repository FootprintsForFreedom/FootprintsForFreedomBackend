//
//  StaticContentSnippet.swift
//  
//
//  Created by niklhut on 10.06.22.
//

import Foundation

public extension StaticContent {
    /// The snippets which can be used in a static content object.
    enum Snippet: String, Codable, CaseIterable, ApiModelInterface {
        public typealias Module = AppApi.StaticContent
        
        case username = "<username>"
        case appName = "<app-name>"
        case verificationLink = "<verification-link>"
    }
}
