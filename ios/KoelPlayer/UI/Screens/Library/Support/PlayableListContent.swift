@preconcurrency import Shared
import SwiftUI

/// Song rows for a `List`, split into lettered sections with a side index when sorted by title and long.
struct PlayableListContent: View {
    let playables: [any Playable]
    var style = PlayableRow.Style.standard
    var isSortedByTitle = false
    var removal: ((any Playable) -> PlayableRow.Removal)?

    var body: some View {
        if SectionIndex.isShown(itemCount: playables.count, isSortedByName: isSortedByTitle) {
            ForEach(SectionIndex.sections(playables, name: \.title)) { section in
                Section {
                    rows(section.items)
                }
                .sectionIndexLabel(section.letter)
            }
        } else {
            rows(playables)
        }
    }

    private func rows(_ playables: [any Playable]) -> some View {
        ForEach(playables, id: \.id) { playable in
            PlayableRow(playable: playable, style: style, removal: removal?(playable))
        }
    }
}
