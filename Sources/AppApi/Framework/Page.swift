//
//  Page.swift
//  
//
//  Created by niklhut on 08.01.23.
//

/// A single section of a larger, traversable result set.
public struct Page<T> {
    /// The page's items.
    public let items: [T]
    
    /// Metadata containing information about current page, items per page, and total items.
    public let metadata: PageMetadata
    
    /// Creates a new `Page`.
    public init(items: [T], metadata: PageMetadata) {
        self.items = items
        self.metadata = metadata
    }
}

extension Page: Encodable where T: Encodable {}
extension Page: Decodable where T: Decodable {}

/// Metadata for a given `Page`.
public struct PageMetadata: Codable {
    /// Current page number. Starts at `1`.
    public let page: Int
    
    /// Max items per page.
    public let per: Int
    
    /// Total number of items available.
    ///
    /// For larger datasets the total elements count is only an estimate.
    public let total: Int
    
    /// Computed total number of pages with `1` being the minimum.
    ///
    /// Since the page count is computed by using the ``PageMetadata/total`` count of elements it is only an estimate for larger datasets.
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

/// Represents information needed to generate a `Page` from the full result set.
public struct PageRequest: Decodable {
    /// Page number to request. Starts at `1`.
    public let page: Int
    
    /// Max items per page.
    public let per: Int
    
    enum CodingKeys: String, CodingKey {
        case page = "page"
        case per = "per"
    }
    
    /// `Decodable` conformance.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.page = try container.decodeIfPresent(Int.self, forKey: .page) ?? 1
        self.per = try container.decodeIfPresent(Int.self, forKey: .per) ?? 10
    }
    
    /// Crates a new `PageRequest`
    /// - Parameters:
    ///   - page: Page number to request. Starts at `1`.
    ///   - per: Max items per page.
    public init(page: Int, per: Int) {
        self.page = page
        self.per = per
    }
    
    var start: Int {
        (self.page - 1) * self.per
    }
    
    var end: Int {
        self.page * self.per
    }
}
