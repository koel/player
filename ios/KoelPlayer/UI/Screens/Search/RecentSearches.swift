@preconcurrency import Shared
import SwiftUI

/// What Search shows before anything is typed: the latest searches to run again.
struct RecentSearches: View {
    let store: SearchStore
    let run: (String) -> Void

    @State private var searches: Live<[String]>

    init(store: SearchStore, run: @escaping (String) -> Void) {
        self.store = store
        self.run = run
        _searches = State(initialValue: Live(store.recentSearches))
    }

    var body: some View {
        List {
            if !searches.value.isEmpty {
                SectionHeader(title: "Recently Searched", action: .init(title: "Clear", role: .destructive) { store.clearRecentSearches() })
                    .listRowInsets(EdgeInsets())
                    .brandListRow()
                    .listRowSeparator(.hidden)
                ForEach(searches.value, id: \.self) { keywords in
                    Button { run(keywords) } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "clock")
                                .foregroundStyle(.secondary)
                            Text(keywords)
                        }
                        .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        RemovalSwipeButton { store.forgetSearch(keywords: keywords) }
                    }
                    .brandListRow()
                }
            }
        }
        .listStyle(.plain)
    }
}
