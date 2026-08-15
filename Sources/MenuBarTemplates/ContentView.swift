import EmailTemplateCore
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: TemplateStore
    @State private var placeholderValues: [String: PlaceholderValue] = [:]
    @State private var selectedGender: TemplateGender = .female
    @State private var isPreviewing = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 340)
        } detail: {
            detail
        }
        .frame(minWidth: 980, minHeight: 680)
        .onChange(of: store.selectedTemplateID) { _, _ in
            isPreviewing = false
            syncDynamicFields()
        }
        .onChange(of: store.selectedTemplate?.subject ?? "") { _, _ in
            syncDynamicFields()
        }
        .onChange(of: store.selectedTemplate?.bodyHtml ?? "") { _, _ in
            syncDynamicFields()
        }
        .onAppear {
            syncDynamicFields()
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            TextField("Search templates...", text: $store.searchText)
                .textFieldStyle(.roundedBorder)
                .padding([.horizontal, .top], 12)
                .padding(.bottom, 8)

            List(selection: $store.selectedTemplateID) {
                ForEach(store.filteredTemplates) { template in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(template.name.isEmpty ? "Untitled Template" : template.name)
                            .lineLimit(1)
                        if !template.subject.isEmpty {
                            Text(template.subject)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .tag(template.id)
                    .padding(.vertical, 4)
                }
            }

            Divider()

            HStack(spacing: 8) {
                Button {
                    store.createTemplate()
                } label: {
                    Image(systemName: "plus")
                }
                .help("Create template")

                Button {
                    showingDeleteConfirmation = true
                } label: {
                    Image(systemName: "minus")
                }
                .disabled(store.selectedTemplate == nil)
                .help("Delete template")
                .confirmationDialog(
                    "Delete this template?",
                    isPresented: $showingDeleteConfirmation
                ) {
                    Button("Delete", role: .destructive) {
                        store.deleteSelectedTemplate()
                    }
                    Button("Cancel", role: .cancel) {}
                }

                Button {
                    store.duplicateSelectedTemplate()
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .disabled(store.selectedTemplate == nil)
                .help("Duplicate template")

                Spacer()
            }
            .buttonStyle(.bordered)
            .padding(12)
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let template = store.selectedTemplate {
            editor(for: template)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "tray")
                    .font(.system(size: 42))
                    .foregroundStyle(.secondary)
                Text("No Template Selected")
                    .font(.title3)
                Text("Create or select a template to start editing.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func editor(for template: EmailTemplate) -> some View {
        let resolved = resolvedTemplate(for: template)
        let placeholders = TemplateResolver.detectedPlaceholders(subject: template.subject, bodyHtml: template.bodyHtml)
        let hasGender = TemplateResolver.containsGenderBlocks(subject: template.subject, bodyHtml: template.bodyHtml)

        return VStack(alignment: .leading, spacing: 12) {
            topFields(template: template, resolved: resolved)

            if !placeholders.isEmpty || hasGender {
                dynamicControls(placeholders: placeholders, hasGender: hasGender)
            }

            HStack(spacing: 8) {
                Button("Copy Subject") {
                    ClipboardWriter.copySubject(resolved.subject)
                }
                Button("Copy Body") {
                    ClipboardWriter.copyBody(resolved)
                }
                Button(isPreviewing ? "Edit Template" : "View Email") {
                    isPreviewing.toggle()
                }
                Spacer()
            }
            .buttonStyle(.borderedProminent)

            Divider()

            HStack {
                Text("Body")
                    .font(.headline)
                Spacer()
                FormattingToolbar(disabled: isPreviewing)
            }

            HTMLBodyEditor(
                html: bodyBinding(resolved: resolved),
                isEditable: !isPreviewing
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor))
            }
        }
        .padding(18)
    }

    private func topFields(template: EmailTemplate, resolved: ResolvedTemplate) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Template Name", text: nameBinding)
                .font(.title2)
                .textFieldStyle(.plain)
                .disabled(isPreviewing)

            Text("Subject:")
                .font(.headline)

            if isPreviewing {
                Text(resolved.subject.isEmpty ? " " : resolved.subject)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(nsColor: .separatorColor))
                    }
            } else {
                TextField("Subject", text: subjectBinding)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private func dynamicControls(placeholders: [String], hasGender: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if !placeholders.isEmpty {
                Text("Fields:")
                    .font(.headline)
                ForEach(placeholders, id: \.self) { name in
                    HStack(spacing: 10) {
                        Text(name)
                            .font(.callout.monospaced())
                            .frame(width: 130, alignment: .leading)
                            .lineLimit(1)
                        TextField("Value", text: placeholderValueBinding(for: name))
                        Toggle("Include", isOn: placeholderIncludeBinding(for: name))
                            .toggleStyle(.checkbox)
                            .frame(width: 88, alignment: .trailing)
                    }
                }
            }

            if hasGender {
                HStack {
                    Text("Gender:")
                        .font(.headline)
                    Picker("Gender", selection: $selectedGender) {
                        Text("Female").tag(TemplateGender.female)
                        Text("Male").tag(TemplateGender.male)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var nameBinding: Binding<String> {
        Binding {
            store.selectedTemplate?.name ?? ""
        } set: { value in
            store.updateSelected { $0.name = value }
        }
    }

    private var subjectBinding: Binding<String> {
        Binding {
            store.selectedTemplate?.subject ?? ""
        } set: { value in
            store.updateSelected { $0.subject = value }
        }
    }

    private func bodyBinding(resolved: ResolvedTemplate) -> Binding<String> {
        Binding {
            if isPreviewing {
                return resolved.bodyHtml
            }
            return store.selectedTemplate?.bodyHtml ?? ""
        } set: { value in
            guard !isPreviewing else {
                return
            }
            store.updateSelected { $0.bodyHtml = value }
        }
    }

    private func placeholderValueBinding(for name: String) -> Binding<String> {
        Binding {
            placeholderValues[name, default: PlaceholderValue()].value
        } set: { value in
            var current = placeholderValues[name, default: PlaceholderValue()]
            current.value = value
            placeholderValues[name] = current
        }
    }

    private func placeholderIncludeBinding(for name: String) -> Binding<Bool> {
        Binding {
            placeholderValues[name, default: PlaceholderValue()].isIncluded
        } set: { value in
            var current = placeholderValues[name, default: PlaceholderValue()]
            current.isIncluded = value
            placeholderValues[name] = current
        }
    }

    private func resolvedTemplate(for template: EmailTemplate) -> ResolvedTemplate {
        TemplateResolver.resolve(
            subject: template.subject,
            bodyHtml: template.bodyHtml,
            placeholders: placeholderValues,
            gender: selectedGender
        )
    }

    private func syncDynamicFields() {
        guard let template = store.selectedTemplate else {
            placeholderValues = [:]
            return
        }

        let detected = TemplateResolver.detectedPlaceholders(subject: template.subject, bodyHtml: template.bodyHtml)
        var next: [String: PlaceholderValue] = [:]
        for name in detected {
            next[name] = placeholderValues[name] ?? PlaceholderValue()
        }
        placeholderValues = next
    }
}
