// String extensions for Swift Embedded code generation

import Foundation

// String extensions for case conversion
public extension String {
    func camelCased() -> String {
        let parts = self.split(separator: "_")
        guard !parts.isEmpty else { return self }
        
        let first = String(parts[0])
        let rest = parts.dropFirst().map { $0.capitalized }
        
        return ([first] + rest).joined()
    }
    
    func pascalCased() -> String {
        let parts = self.split(separator: "_")
        return parts.map { $0.capitalized }.joined()
    }
}