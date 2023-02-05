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
        
        /// Snippet used to indicate a username.
        case username = "<username>"
        /// Snippet used to indicate the app name.
        case appName = "<app-name>"
        /// Snippet used to indicate a verification link.
        case verificationLink = "<verification-link>"
    }
}
