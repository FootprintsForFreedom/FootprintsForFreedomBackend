// 'Swifty' API wrapper for ObjC diff_match_patch module

import diff_match_patch

public func computeDiff(_ string1: String, _ string2: String, checklines: Bool = true) -> [diff_match_patch.Diff] {
    let dmp = DiffMatchPatch()
    return dmp.diff_main(ofOldString: string1, andNewString: string2, checkLines: checklines)
}

public func cleanupSemantics(_ diffs: [diff_match_patch.Diff]) -> [diff_match_patch.Diff] {
    let dmp = DiffMatchPatch()
    return dmp.diff_cleanupSemantic(diffs)
}

public extension Array where Element == diff_match_patch.Diff {
    func cleaningUpSemantics() -> [diff_match_patch.Diff] {
        return cleanupSemantics(self)
    }
    
    func converted() -> [Diff] {
        self.map { Diff(from: $0) }
    }
}

public struct Diff: Codable {
    public let operation: Operation
    public let text: String
    
    init(from: diff_match_patch.Diff) {
        self.operation = Operation(from: from.operation)
        self.text = from.text
    }
}

public enum Operation: String, Codable {
    case delete
    case insert
    case equal
    
    init(from: diff_match_patch.Operation) {
        switch from {
        case .diffDelete: self = .delete
        case .diffInsert: self = .insert
        case .diffEqual: self = .equal
        @unknown default:
            fatalError()
        }
    }
}
