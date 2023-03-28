//
//  String+Slugify.swift
//  
//
//  Created by niklhut on 02.06.22.
//

import Foundation

extension String {
    /// Generate a slug for a string.
    ///
    /// A slug can be used as a request parameter. Therefore it does not consist of any special characters and is lowercased.
    /// - Returns: The slugified string.
    public func slugify() -> String {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-_.")
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "ä", with: "ae")
            .replacingOccurrences(of: "ö", with: "oe")
            .replacingOccurrences(of: "ü", with: "ue")
            .replacingOccurrences(of: "ß", with: "ss")
            .folding(options: .diacriticInsensitive, locale: .init(identifier: "en_US"))
            .components(separatedBy: allowed.inverted)
            .filter { $0 != "" }
            .joined(separator: "-")
    }
}
