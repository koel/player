import SwiftUI

/// The Sort button of every sorted list, remembering the choice under `rememberKey` before passing it on.
struct SortToolbarItem: ToolbarContent {
    let options: [SortOption]
    let sort: SortSetting
    let rememberKey: String
    var layout: Binding<CollectionLayout>?
    let onChange: (SortSetting) -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            SortMenu(options: options, field: sort.field, order: sort.order, layout: layout) { field, order in
                let setting = SortSetting(field: field, order: order)
                setting.remember(for: rememberKey)
                onChange(setting)
            }
        }
    }
}

/// The "…" button holding a screen's own actions.
struct MoreMenuToolbarItem<Content: View>: ToolbarContent {
    @ViewBuilder let content: () -> Content

    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu("More", systemImage: "ellipsis", content: content)
        }
    }
}
