import SwiftUI

/// Artwork beside a title and a secondary line: the layout of song, playlist, artist, genre, podcast and station rows.
struct MediaRow<Leading: View>: View {
    let title: String
    var subtitle: String?
    var titleLineLimit = 1
    @ViewBuilder var leading: () -> Leading

    var body: some View {
        HStack(spacing: 12) {
            leading()
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .lineLimit(titleLineLimit)
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}

extension MediaRow where Leading == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle) { EmptyView() }
    }
}

extension View {
    /// Dims artwork of `size` behind a status symbol, such as the now-playing bars or a buffering spinner.
    func artworkOverlay<Status: View>(
        isShown: Bool,
        size: CGFloat,
        cornerRadius: CGFloat = 6,
        dimming: Double = 0.45,
        @ViewBuilder status: () -> Status
    ) -> some View {
        overlay {
            if isShown {
                status()
                    .frame(width: size, height: size)
                    .background(.black.opacity(dimming), in: .rect(cornerRadius: cornerRadius))
            }
        }
    }

    func nowPlayingOverlay(isCurrent: Bool, isPlaying: Bool, size: CGFloat) -> some View {
        artworkOverlay(isShown: isCurrent, size: size) {
            NowPlayingIndicator(isPlaying: isPlaying)
        }
    }
}
