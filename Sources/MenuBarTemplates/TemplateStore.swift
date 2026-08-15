import Combine
import EmailTemplateCore
import Foundation

@MainActor
final class TemplateStore: ObservableObject {
    @Published var templates: [EmailTemplate] = []
    @Published var selectedTemplateID: UUID?
    @Published var searchText = ""

    private let storageURL: URL
    private var saveTask: Task<Void, Never>?

    init(storageURL: URL = TemplateStore.defaultStorageURL()) {
        self.storageURL = storageURL
        load()
    }

    var filteredTemplates: [EmailTemplate] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return templates
        }
        return templates.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var selectedTemplate: EmailTemplate? {
        guard let selectedTemplateID else {
            return nil
        }
        return templates.first { $0.id == selectedTemplateID }
    }

    func createTemplate() {
        let template = EmailTemplate.blank()
        templates.append(template)
        selectedTemplateID = template.id
        scheduleSave()
    }

    func duplicateSelectedTemplate() {
        guard let selectedTemplate else {
            return
        }
        let duplicate = selectedTemplate.duplicated()
        templates.append(duplicate)
        selectedTemplateID = duplicate.id
        scheduleSave()
    }

    func deleteSelectedTemplate() {
        guard let selectedTemplateID else {
            return
        }
        templates.removeAll { $0.id == selectedTemplateID }
        self.selectedTemplateID = templates.first?.id
        scheduleSave()
    }

    func updateSelected(_ update: (inout EmailTemplate) -> Void) {
        guard let selectedTemplateID, let index = templates.firstIndex(where: { $0.id == selectedTemplateID }) else {
            return
        }
        update(&templates[index])
        templates[index].updatedAt = Date()
        scheduleSave()
    }

    func saveImmediately() {
        saveTask?.cancel()
        persist()
    }

    private func load() {
        do {
            let data = try Data(contentsOf: storageURL)
            let database = try JSONDecoder.templateDecoder.decode(TemplateDatabase.self, from: data)
            templates = database.templates.sorted { $0.updatedAt > $1.updatedAt }
            selectedTemplateID = templates.first?.id
        } catch {
            templates = []
            selectedTemplateID = nil
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else {
                return
            }
            self?.persist()
        }
    }

    private func persist() {
        do {
            try FileManager.default.createDirectory(at: storageURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let database = TemplateDatabase(templates: templates)
            let data = try JSONEncoder.templateEncoder.encode(database)
            try data.write(to: storageURL, options: [.atomic])
        } catch {
            NSLog("Failed to save templates: \(error.localizedDescription)")
        }
    }

    private static func defaultStorageURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport
            .appendingPathComponent("MenuBarTemplates", isDirectory: true)
            .appendingPathComponent("templates.json")
    }
}

private extension JSONDecoder {
    static var templateDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

private extension JSONEncoder {
    static var templateEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
