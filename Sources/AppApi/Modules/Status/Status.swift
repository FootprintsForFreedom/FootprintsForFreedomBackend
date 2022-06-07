//
//  Status.swift
//  
//
//  Created by niklhut on 05.06.22.
//

import Foundation

public enum Status: String, Codable, CaseIterable, ApiModuleInterface {
    case pending, verified, rejected, deleteRequested
}
