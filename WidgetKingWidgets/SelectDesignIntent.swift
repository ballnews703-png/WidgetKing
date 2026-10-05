import AppIntents
import WidgetKit

/// Lets the user pick one of their saved designs when editing the widget on
/// the Home Screen. Ids are the designer's own string ids.
struct DesignEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Widget Design"
    static var defaultQuery = DesignQuery()

    var id: String
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    init(design: WKDesign) {
        id = design.id
        name = design.name
    }
}

struct DesignQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [DesignEntity] {
        WKStore.designs().filter { identifiers.contains($0.id) }.map(DesignEntity.init)
    }

    func suggestedEntities() async throws -> [DesignEntity] {
        WKStore.designs().map(DesignEntity.init)
    }

    func defaultResult() async -> DesignEntity? {
        WKStore.designs().first.map(DesignEntity.init)
    }
}

struct SelectDesignIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Choose Design"
    static var description = IntentDescription("Pick which of your WidgetKing designs to show.")

    @Parameter(title: "Design")
    var design: DesignEntity?
}
