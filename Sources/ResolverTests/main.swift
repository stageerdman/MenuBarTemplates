import EmailTemplateCore
import Foundation

private func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ name: String) {
    guard actual == expected else {
        fatalError("\(name) failed. Expected \(expected), got \(actual)")
    }
}

private func expect(_ condition: Bool, _ name: String) {
    guard condition else {
        fatalError("\(name) failed")
    }
}

let subjectResult = TemplateResolver.resolve(
    subject: "Hello {{ NAME }}",
    bodyHtml: "",
    placeholders: ["NAME": PlaceholderValue(value: "Jan")]
)
expectEqual(subjectResult.subject, "Hello Jan", "Placeholder replacement in subject")

let bodyResult = TemplateResolver.resolve(
    subject: "",
    bodyHtml: "<p>Hello {{ NAME }}</p>",
    placeholders: ["NAME": PlaceholderValue(value: "Anna")]
)
expectEqual(bodyResult.bodyHtml, "<p>Hello Anna</p>", "Placeholder replacement in body HTML")

let repeatedResult = TemplateResolver.resolve(
    subject: "",
    bodyHtml: "<p>Hi {{ NAME }}, your name is {{ NAME }}.</p>",
    placeholders: ["NAME": PlaceholderValue(value: "Jan")]
)
expectEqual(repeatedResult.bodyHtml, "<p>Hi Jan, your name is Jan.</p>", "Repeated placeholder replacement")

let emptyResult = TemplateResolver.resolve(
    subject: "Dobrý den, {{ NAME }}",
    bodyHtml: "",
    placeholders: ["NAME": PlaceholderValue(value: "")]
)
expectEqual(emptyResult.subject, "Dobrý den, {{ NAME }}", "Empty placeholder leaves token")

let oneSpaceResult = TemplateResolver.resolve(
    subject: "Hello {{ NAME }}!",
    bodyHtml: "",
    placeholders: ["NAME": PlaceholderValue(value: " ")]
)
expectEqual(oneSpaceResult.subject, "Hello  !", "One-space placeholder replacement")

let uncheckedResult = TemplateResolver.resolve(
    subject: "Dobrý den, {{ NAME }},",
    bodyHtml: "",
    placeholders: ["NAME": PlaceholderValue(value: "Jan", isIncluded: false)]
)
expectEqual(uncheckedResult.subject, "Dobrý den, ,", "Unchecked placeholder removal")

let defaultGenderResult = TemplateResolver.resolve(
    subject: "",
    bodyHtml: "<p>{{gender:viděl|viděla}} jste</p>",
    placeholders: [:]
)
expectEqual(defaultGenderResult.bodyHtml, "<p>viděla jste</p>", "Gender default female")

let maleGenderResult = TemplateResolver.resolve(
    subject: "",
    bodyHtml: "<p>{{gender:viděl|viděla}} jste</p>",
    placeholders: [:],
    gender: .male
)
expectEqual(maleGenderResult.bodyHtml, "<p>viděl jste</p>", "Gender male")

let multipleGenderResult = TemplateResolver.resolve(
    subject: "{{gender:Pane|Paní}}",
    bodyHtml: "<p>{{gender:byl|byla}} jste {{gender:spokojený|spokojená}}</p>",
    placeholders: [:],
    gender: .female
)
expectEqual(multipleGenderResult.subject, "Paní", "Multiple gender subject")
expectEqual(multipleGenderResult.bodyHtml, "<p>byla jste spokojená</p>", "Multiple gender body")

let detectedNames = TemplateResolver.detectedPlaceholders(
    subject: "{{gender:Pane|Paní}} {{ NAME }}",
    bodyHtml: "<p>{{ COMPANY }}</p>"
)
expectEqual(detectedNames, ["NAME", "COMPANY"], "Gender blocks ignored as placeholders")

let formattingResult = TemplateResolver.resolve(
    subject: "",
    bodyHtml: "<h2>Hello <strong>{{ NAME }}</strong></h2><ul><li>{{ COMPANY }}</li></ul>",
    placeholders: [
        "NAME": PlaceholderValue(value: "Jan"),
        "COMPANY": PlaceholderValue(value: "Acme")
    ]
)
expectEqual(
    formattingResult.bodyHtml,
    "<h2>Hello <strong>Jan</strong></h2><ul><li>Acme</li></ul>",
    "HTML formatting remains intact"
)

let htmlOutputResult = TemplateResolver.resolve(
    subject: "",
    bodyHtml: "<p><a href=\"https://example.com\">{{ LABEL }}</a></p>",
    placeholders: ["LABEL": PlaceholderValue(value: "Open")]
)
expect(
    htmlOutputResult.bodyHtml.contains("<a href=\"https://example.com\">Open</a>"),
    "Copy body produces HTML output"
)
expect(!htmlOutputResult.bodyPlainText.isEmpty, "Copy body produces plain-text fallback")

print("Resolver tests passed")
