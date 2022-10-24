//
//  ESSuggestDocumentResponse.swift
//  
//
//  Created by niklhut on 24.10.22.
//

import ElasticsearchNIOClient

struct ESSuggestDocumentsResponse<Document: Decodable>: Decodable {
    struct Suggest: Decodable {
        let text: String
        let offset: Int
        let length: Int
        let options: [ESGetSingleDocumentResponse<Document>]
    }
    
    private let suggest: [String: [Suggest]]
    
    func suggestFor(_ key: String) throws -> Suggest {
        guard let suggest = suggest[key]?.first else {
            throw ElasticSearchClientError(message: "Key not found", status: .notFound)
        }
        return suggest
    }
}
