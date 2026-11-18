import Foundation
import Testing

struct CoreImportsTests {
    private static let allowedModules: Set<String> = ["Foundation", "CoreGraphics"]
    private static let forbiddenCalls = ["String(localized:", "NSLocalizedString("]
    private static let importPattern =
        #"(?:^|;)\s*(?:@\w+(?:\([^)]*\))?\s+)*(?:(?:public|package|internal|fileprivate|private)\s+)?import\s+(?:(?:typealias|struct|class|enum|protocol|let|var|func)\s+)?([A-Za-z_][A-Za-z0-9_]*)"#

    private static let coreSources = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appending(path: "Sources/PlayerCore")

    private static func swiftFiles(in folder: URL) -> [URL] {
        let files = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: nil)?.allObjects ?? []
        return files.compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
    }

    private static func importedModules(in source: String) throws -> [String] {
        let pattern = try Regex(importPattern).anchorsMatchLineEndings()
        return source.matches(of: pattern).compactMap { $0.output[1].substring.map(String.init) }
    }

    @Test func coreUsesOnlyFoundationAndCoreGraphics() throws {
        let files = Self.swiftFiles(in: Self.coreSources)
        #expect(!files.isEmpty)
        for file in files {
            let source = try String(contentsOf: file, encoding: .utf8)
            let modules = try Self.importedModules(in: source)
            let unexpected = Set(modules).subtracting(Self.allowedModules)
            #expect(unexpected.isEmpty, "\(file.lastPathComponent) imports \(unexpected.sorted())")
        }
    }

    @Test func coreHasNoLocalizedStrings() throws {
        for file in Self.swiftFiles(in: Self.coreSources) {
            let source = try String(contentsOf: file, encoding: .utf8)
            for call in Self.forbiddenCalls {
                #expect(!source.contains(call), "\(file.lastPathComponent) calls \(call)")
            }
        }
    }
}
