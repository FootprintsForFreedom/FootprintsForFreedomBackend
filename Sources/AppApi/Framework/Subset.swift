//
//  Subset.swift
//  
//
//  Created by niklhut on 08.01.23.
//

/// A single section of a larger, traversable result set.
public struct Subset<T> {
    /// The page's items.
    public let items: [T]
    
    /// Metadata containing information about current page, items per page, and total items.
    public let metadata: SubsetMetadata
    
    /// Creates a new `Page`.
    public init(items: [T], metadata: SubsetMetadata) {
        self.items = items
        self.metadata = metadata
    }
}

extension Subset: Encodable where T: Encodable {}
extension Subset: Decodable where T: Decodable {}

/// Metadata for a given `Page`.
public struct SubsetMetadata: Codable {
    /// Current page number. Starts at `1`.
    public let page: Int
    
    /// Max items per page.
    public let per: Int
    
    /// Total number of items available.
    public let total: Int
    
    /// Computed total number of pages with `1` being the minimum.
    public var pageCount: Int {
        let count = Int((Double(self.total)/Double(self.per)).rounded(.up))
        return count < 1 ? 1 : count
    }
    
    /// Creates a new `PageMetadata` instance.
    ///
    /// - Parameters:
    ///.  - page: Current page number.
    ///.  - per: Max items per page.
    ///.  - total: Total number of items available.
    public init(page: Int, per: Int, total: Int) {
        self.page = page
        self.per = per
        self.total = total
    }
}
