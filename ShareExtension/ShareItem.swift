import Foundation

struct ShareItem: Identifiable {
    let id = UUID()
    let suggestedName: String
    let temporaryURL: URL
}
