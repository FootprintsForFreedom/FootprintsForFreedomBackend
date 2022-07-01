//
//  AsyncValidatorBuilder.swift
//  
//
//  Created by niklhut on 01.02.22.
//

/// Allows to return an enum of ``AsyncValidator``s via result builders.
@resultBuilder
public enum AsyncValidatorBuilder {
    /// Transforms multiple ``AsyncValidator``s to an array of ``AsyncValidator``s.
    /// - Parameter components: The separate ``AsyncValidator``s.
    /// - Returns: An array of all given ``AsyncValidator``s.
    public static func buildBlock(_ components: AsyncValidator...) -> [AsyncValidator] {
        components
    }
}
