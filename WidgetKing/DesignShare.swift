import Foundation

/// Export and import designs as shareable JSON files, so widget designs can
/// be swapped between people and devices.
enum DesignShare {
    static func exportURL(for design: WidgetDesign) throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(design)

        let safeName = design.name
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        let fileName = "\(safeName.isEmpty ? "Widget" : safeName).widgetking.json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: url, options: .atomic)
        return url
    }

    static func importDesign(from url: URL) throws -> WidgetDesign {
        let scoped = url.startAccessingSecurityScopedResource()
        defer {
            if scoped { url.stopAccessingSecurityScopedResource() }
        }
        let data = try Data(contentsOf: url)
        var design = try JSONDecoder().decode(WidgetDesign.self, from: data)
        design.id = UUID()
        return design
    }
}
