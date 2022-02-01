//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

@resultBuilder
public enum AsyncValidatorBuilder {
    
    public static func buildBlock(_ components: AsyncValidator...) -> [AsyncValidator] {
        components
    }
}
