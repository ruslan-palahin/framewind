import Foundation
import Testing

private let repositoryRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()

private let supportedLanguages = [
    "ar", "bg", "ca", "cs", "da", "de", "el", "en", "es", "et",
    "fi", "fr", "he", "hi", "hr", "hu", "id", "it", "ja", "kk",
    "ko", "lt", "lv", "ms", "nb", "nl", "pl", "pt-BR", "pt-PT", "ro",
    "ru", "sk", "sl", "sv", "th", "tr", "uk", "vi", "zh-Hans", "zh-Hant",
]

private let formatKeyArguments: [String: [Int: String]] = [
    "menu.hideApp %@": [1: "@"],
    "menu.quitApp %@": [1: "@"],
    "message.unplayable %@": [1: "@"],
    "message.openFailed %@ %@": [1: "@", 2: "@"],
]

private let placeholderExamples: [(String, [Int: String])] = [
    ("Plain text", [:]),
    ("100%% sure", [:]),
    ("File: %@", [1: "@"]),
    ("%@ and %@", [1: "@", 2: "@"]),
    ("%1$@ failed: %2$@", [1: "@", 2: "@"]),
    ("%2$@ — %1$@", [1: "@", 2: "@"]),
    ("%lld items", [1: "lld"]),
]

struct LocalizationTests {
    @Test func everySupportedLanguageHasExactlyOneTable() throws {
        let folders = try FileManager.default.contentsOfDirectory(atPath: repositoryRoot.appending(path: "Resources").path)
            .filter { $0.hasSuffix(".lproj") }
            .map { String($0.dropLast(".lproj".count)) }
        #expect(folders.sorted() == supportedLanguages.sorted())
    }

    @Test(arguments: supportedLanguages)
    func tableIsCompleteAndMatchesEnglish(language: String) throws {
        let english = try StringsTable(language: "en")
        let table = try StringsTable(language: language)
        #expect(table.duplicateKeys.isEmpty, "\(language): duplicate keys \(table.duplicateKeys)")
        #expect(Set(table.keysInFileOrder) == Set(table.entries.keys), "\(language): file has lines the parser skipped")
        #expect(Set(table.entries.keys) == Set(english.entries.keys), "\(language): keys differ from en")
        for (key, value) in table.entries {
            #expect(!value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "\(language): \(key) is empty")
            let expected = try placeholderArguments(in: english.entries[key] ?? "")
            #expect(try placeholderArguments(in: value) == expected, "\(language): \(key) placeholders differ from en")
        }
    }

    @Test func englishFormatStringsTakeTheirArguments() throws {
        let english = try StringsTable(language: "en")
        for (key, arguments) in formatKeyArguments {
            #expect(try placeholderArguments(in: english.entries[key] ?? "") == arguments, "\(key)")
        }
    }

    @Test func codeUsesExactlyTheKeysOfTheEnglishTable() throws {
        let english = try StringsTable(language: "en")
        let code = try LocalizedKeysInCode(scanning: repositoryRoot.appending(path: "Sources"))
        #expect(code.recognizedCalls == code.totalCalls, "a String(localized:) call uses a form the scanner does not read")
        #expect(code.keys == Set(english.entries.keys))
        #expect(code.keys.isSuperset(of: formatKeyArguments.keys))
    }

    @Test func fallbackLanguageIsEnglish() throws {
        let data = try Data(contentsOf: repositoryRoot.appending(path: "Resources/Info.plist"))
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        #expect(plist?["CFBundleDevelopmentRegion"] as? String == "en")
    }

    @Test(arguments: placeholderExamples)
    func readsPlaceholderArguments(format: String, expected: [Int: String]) throws {
        #expect(try placeholderArguments(in: format) == expected)
    }

    @Test(arguments: ["%1$@ and %@", "%1$@ and %3$@", "%1$@ and %1$d"])
    func rejectsBrokenPlaceholders(format: String) {
        #expect(throws: LocalizationError.self) { try placeholderArguments(in: format) }
    }
}

private enum LocalizationError: Error {
    case notAStringsTable(String)
    case mixedPlaceholderNumbering(String)
    case conflictingPlaceholderTypes(String)
    case missingPlaceholderPosition(String)
}

private struct StringsTable {
    let entries: [String: String]
    let keysInFileOrder: [String]

    var duplicateKeys: [String] {
        Dictionary(grouping: keysInFileOrder, by: { $0 }).filter { $0.value.count > 1 }.map(\.key).sorted()
    }

    init(language: String) throws {
        let data = try Data(contentsOf: repositoryRoot.appending(path: "Resources/\(language).lproj/Localizable.strings"))
        guard let entries = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String] else {
            throw LocalizationError.notAStringsTable(language)
        }
        let keyPattern = try Regex(#"^\s*"((?:[^"\\]|\\.)*)"\s*="#).anchorsMatchLineEndings()
        self.entries = entries
        keysInFileOrder = String(decoding: data, as: UTF8.self)
            .matches(of: keyPattern)
            .compactMap { $0.output[1].substring.map(String.init) }
    }
}

private struct LocalizedKeysInCode {
    private(set) var keys: Set<String> = []
    private(set) var totalCalls = 0
    private(set) var recognizedCalls = 0

    init(scanning folder: URL) throws {
        let call = try Regex(#"String\(localized: "((?:[^"\\]|\\\([^()]*\))*)"\)"#)
        let interpolation = try Regex(#"\\\([^()]*\)"#)
        let files = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: nil)?.allObjects ?? []
        for case let file as URL in files where file.pathExtension == "swift" {
            let source = try String(contentsOf: file, encoding: .utf8)
            totalCalls += source.ranges(of: "String(localized:").count
            for match in source.matches(of: call) {
                guard let literal = match.output[1].substring else { continue }
                keys.insert(String(literal).replacing(interpolation, with: "%@"))
                recognizedCalls += 1
            }
        }
    }
}

private func placeholderArguments(in format: String) throws -> [Int: String] {
    let placeholder = try Regex(#"%%|%(?:(\d+)\$)?[-+ #0]*\d*(?:\.\d+)?((?:hh|h|ll|l|q|L|z|t|j)?[@dDiuUxXoOfFeEgGcCsSpaA])"#)
    var arguments: [Int: String] = [:]
    var nextPosition = 1
    var isNumbered: Bool?
    for match in format.matches(of: placeholder) {
        guard let type = match.output[2].substring.map(String.init) else { continue }
        let explicitPosition = match.output[1].substring.flatMap { Int($0) }
        if let isNumbered, isNumbered != (explicitPosition != nil) {
            throw LocalizationError.mixedPlaceholderNumbering(format)
        }
        isNumbered = explicitPosition != nil
        let position = explicitPosition ?? nextPosition
        nextPosition += 1
        if let existing = arguments[position], existing != type {
            throw LocalizationError.conflictingPlaceholderTypes(format)
        }
        arguments[position] = type
    }
    guard Set(arguments.keys) == Set(1..<(arguments.count + 1)) else {
        throw LocalizationError.missingPlaceholderPosition(format)
    }
    return arguments
}
