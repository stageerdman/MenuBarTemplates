import Foundation

public enum TemplateGender: String, Codable, CaseIterable, Sendable {
    case female
    case male
}

public struct PlaceholderValue: Equatable, Sendable {
    public var value: String
    public var isIncluded: Bool

    public init(value: String = "", isIncluded: Bool = true) {
        self.value = value
        self.isIncluded = isIncluded
    }
}

public struct ResolvedTemplate: Equatable, Sendable {
    public var subject: String
    public var bodyHtml: String
    public var bodyPlainText: String

    public init(subject: String, bodyHtml: String, bodyPlainText: String) {
        self.subject = subject
        self.bodyHtml = bodyHtml
        self.bodyPlainText = bodyPlainText
    }
}

public enum TemplateResolver {
    private static let placeholderPattern = #"\{\{\s*([A-Z0-9_ -]+)\s*\}\}"#
    private static let genderPattern = #"\{\{gender:([^|{}]*)\|([^{}]*)\}\}"#

    public static func detectedPlaceholders(subject: String, bodyHtml: String) -> [String] {
        let combined = subject + "\n" + stripHtmlTags(from: bodyHtml)
        let regex = makeRegex(placeholderPattern)
        var names: [String] = []
        var seen: Set<String> = []
        let range = NSRange(combined.startIndex..<combined.endIndex, in: combined)

        regex.enumerateMatches(in: combined, range: range) { match, _, _ in
            guard let match, match.numberOfRanges > 1, let nameRange = Range(match.range(at: 1), in: combined) else {
                return
            }
            let name = combined[nameRange].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, !seen.contains(name) else {
                return
            }
            seen.insert(name)
            names.append(name)
        }
        return names
    }

    public static func containsGenderBlocks(subject: String, bodyHtml: String) -> Bool {
        let combined = subject + "\n" + bodyHtml
        let regex = makeRegex(genderPattern)
        let range = NSRange(combined.startIndex..<combined.endIndex, in: combined)
        return regex.firstMatch(in: combined, range: range) != nil
    }

    public static func resolve(
        subject: String,
        bodyHtml: String,
        placeholders: [String: PlaceholderValue],
        gender: TemplateGender = .female
    ) -> ResolvedTemplate {
        let resolvedSubject = resolveString(subject, placeholders: placeholders, gender: gender)
        let resolvedBody = resolveString(bodyHtml, placeholders: placeholders, gender: gender)
        return ResolvedTemplate(
            subject: resolvedSubject,
            bodyHtml: resolvedBody,
            bodyPlainText: htmlToPlainText(resolvedBody)
        )
    }

    public static func resolveString(
        _ value: String,
        placeholders: [String: PlaceholderValue],
        gender: TemplateGender = .female
    ) -> String {
        let genderResolved = replaceGenderBlocks(in: value, gender: gender)
        return replacePlaceholders(in: genderResolved, placeholders: placeholders)
    }

    public static func htmlToPlainText(_ html: String) -> String {
        stripHtmlTags(from: html)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
    }

    private static func replaceGenderBlocks(in value: String, gender: TemplateGender) -> String {
        let regex = makeRegex(genderPattern)
        let mutable = NSMutableString(string: value)
        let fullRange = NSRange(location: 0, length: mutable.length)
        let matches = regex.matches(in: value, range: fullRange).reversed()

        for match in matches {
            guard
                let maleRange = Range(match.range(at: 1), in: value),
                let femaleRange = Range(match.range(at: 2), in: value)
            else {
                continue
            }
            let replacement = gender == .male ? String(value[maleRange]) : String(value[femaleRange])
            mutable.replaceCharacters(in: match.range, with: replacement)
        }

        return String(mutable)
    }

    private static func replacePlaceholders(in value: String, placeholders: [String: PlaceholderValue]) -> String {
        let regex = makeRegex(placeholderPattern)
        let mutable = NSMutableString(string: value)
        let fullRange = NSRange(location: 0, length: mutable.length)
        let matches = regex.matches(in: value, range: fullRange).reversed()

        for match in matches {
            guard let nameRange = Range(match.range(at: 1), in: value) else {
                continue
            }

            let name = value[nameRange].trimmingCharacters(in: .whitespacesAndNewlines)
            guard let placeholder = placeholders[name] else {
                continue
            }

            if !placeholder.isIncluded {
                mutable.replaceCharacters(in: match.range, with: "")
            } else if !placeholder.value.isEmpty {
                mutable.replaceCharacters(in: match.range, with: placeholder.value)
            }
        }

        return String(mutable)
    }

    private static func stripHtmlTags(from value: String) -> String {
        value.replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression)
    }

    private static func makeRegex(_ pattern: String) -> NSRegularExpression {
        do {
            return try NSRegularExpression(pattern: pattern)
        } catch {
            preconditionFailure("Invalid regex pattern: \(pattern)")
        }
    }
}
