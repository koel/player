@preconcurrency import Shared
import SwiftUI

/// Album cards in as many columns as fit, inset from the screen's edges.
struct AlbumGrid: View {
    let albums: [Album]
    let layout: GridLayout
    var showsYear = false
    let onEdit: (Album) -> Void

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.fixed(layout.cardSize), spacing: layout.spacing), count: layout.columnCount),
            spacing: layout.rowSpacing
        ) {
            ForEach(albums, id: \.id) { album in
                AlbumGridCard(album: album, size: layout.cardSize, showsYear: showsYear) { onEdit(album) }
            }
        }
        .padding(.horizontal, layout.padding)
    }
}
