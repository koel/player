@preconcurrency import Shared
import SwiftUI

/// The top of album, playlist, genre and podcast screens: the cover, titles, then Play between
/// round Favorite and Shuffle buttons.
struct CollectionHeader<Accessory: View>: View {
    static var height: CGFloat { 360 }

    let artworkUrl: String?
    let title: String
    var subtitle: String?
    var subtitleAction: (() -> Void)?
    var detail: String?
    var favorite: FavoriteToggle?
    let playables: [any Playable]
    @ViewBuilder var accessory: () -> Accessory

    @Environment(AppModel.self) private var app
    @Environment(\.coverTint) private var tint

    var body: some View {
        VStack(spacing: 16) {
            Artwork(url: artworkUrl, size: 260, cornerRadius: 12)
                .shadow(color: .black.opacity(0.4), radius: 20, y: 10)

            VStack(spacing: 4) {
                Text(title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                subtitleView
                if let detail {
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)

            accessory()

            CollectionActions(favorite: favorite, playables: playables)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var subtitleView: some View {
        if let subtitle {
            if let subtitleAction {
                Button(subtitle, action: subtitleAction)
                    .font(.title3)
                    .foregroundStyle(tint ?? .secondary)
                    .disabled(app.isOffline)
            } else {
                Text(subtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

/// Play between round Favorite and Shuffle buttons, in the cover color when there is one.
struct CollectionActions: View {
    var favorite: FavoriteToggle?
    let playables: [any Playable]

    @Environment(AppModel.self) private var app
    @Environment(\.coverTint) private var tint

    var body: some View {
        HStack(spacing: 16) {
            if let favorite, app.core.session.supports(feature: .favoriteEntities) {
                RoundIconButton(
                    title: favorite.isFavorite ? "Undo Favorite" : "Favorite",
                    systemImage: favorite.isFavorite ? "heart.fill" : "heart"
                ) {
                    favorite.perform(app: app)
                }
            }

            PlayButton(playables: playables, tint: tint)

            RoundIconButton(title: "Shuffle", systemImage: "shuffle") {
                app.player.play(playables, shuffled: true)
            }
            .disabled(playables.isEmpty)
        }
        .controlSize(.large)
        .padding(.horizontal)
    }
}

extension CollectionHeader where Accessory == EmptyView {
    init(
        artworkUrl: String?,
        title: String,
        subtitle: String? = nil,
        subtitleAction: (() -> Void)? = nil,
        detail: String? = nil,
        favorite: FavoriteToggle? = nil,
        playables: [any Playable]
    ) {
        self.init(
            artworkUrl: artworkUrl,
            title: title,
            subtitle: subtitle,
            subtitleAction: subtitleAction,
            detail: detail,
            favorite: favorite,
            playables: playables
        ) {
            EmptyView()
        }
    }
}

extension EnvironmentValues {
    /// The cover color of the collection on screen, nil when its cover has no usable color.
    @Entry var coverTint: Color?
}

extension View {
    /// The look shared by screens topped with a `CollectionHeader` or the artist photo: a wash of the
    /// cover color, controls tinted with it, and the title in the bar only once `headerHeight` has
    /// scrolled away. A header extending under the navigation bar starts at the very top of the screen.
    func collectionScreen(
        title: String,
        artworkUrl: String?,
        headerHeight: @escaping (ScrollGeometry) -> CGFloat = { _ in CollectionHeader<EmptyView>.height },
        extendsUnderNavigationBar: Bool = false
    ) -> some View {
        modifier(CollectionScreen(
            title: title,
            artworkUrl: artworkUrl,
            headerHeight: headerHeight,
            extendsUnderNavigationBar: extendsUnderNavigationBar
        ))
    }
}

private struct CollectionScreen: ViewModifier {
    let title: String
    let artworkUrl: String?
    let headerHeight: (ScrollGeometry) -> CGFloat
    let extendsUnderNavigationBar: Bool

    @State private var coverColor: Color?
    @State private var isHeaderScrolledAway = false

    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .ignoresSafeArea(edges: extendsUnderNavigationBar ? .top : [])
            .background { CoverBackground(color: coverColor) }
            .tint(coverColor ?? .primary)
            .environment(\.coverTint, coverColor)
            .navigationTitle(isHeaderScrolledAway ? title : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(extendsUnderNavigationBar ? .hidden : .automatic, for: .navigationBar)
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top > headerHeight(geometry)
            } action: { _, scrolledAway in
                isHeaderScrolledAway = scrolledAway
            }
            .task(id: artworkUrl) {
                let color = await CoverColor.of(artworkUrl)
                await CoverColor.fade(from: coverColor, to: color) { coverColor = $0 }
            }
    }
}

struct PlayShuffleButtons: View {
    let playables: [any Playable]

    @Environment(AppModel.self) private var app

    var body: some View {
        PlayShuffleRow(isDisabled: playables.isEmpty) {
            app.player.play(playables)
        } shuffle: {
            app.player.play(playables, shuffled: true)
        }
    }
}

/// Play and Shuffle above a list's songs, spaced the same on every screen.
struct PlayShuffleRow: View {
    let isDisabled: Bool
    let play: () -> Void
    let shuffle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: play) {
                Label("Play", systemImage: "play.fill").frame(maxWidth: .infinity)
            }
            Button(action: shuffle) {
                Label("Shuffle", systemImage: "shuffle").frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.glass)
        .controlSize(.large)
        .disabled(isDisabled)
        .padding(.horizontal)
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: SectionHeader.contentGap - PlayableRow.verticalInset, trailing: 0))
        .listRowSeparator(.hidden)
    }
}

/// Square artwork with two lines below, for album/artist/podcast grids and carousels.
struct ArtworkCard: View {
    let artworkUrl: String?
    let title: String
    var subtitle: String?
    var size: CGFloat = 160
    var isCircular = false

    var body: some View {
        VStack(alignment: isCircular ? .center : .leading, spacing: 6) {
            Artwork(url: artworkUrl, size: size, cornerRadius: 10, isCircle: isCircular)
            VStack(alignment: isCircular ? .center : .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(width: size, alignment: isCircular ? .center : .leading)
        }
        .contentShape(.rect)
    }
}

/// A toolbar menu that picks a sort field and flips the order when the same field is picked again.
struct SortMenu: View {
    let options: [(field: String, label: String)]
    let field: String
    let order: Shared.SortOrder
    var layout: Binding<CollectionLayout>?
    let onChange: (_ field: String, _ order: Shared.SortOrder) -> Void

    var body: some View {
        Menu {
            if let layout {
                Picker("Layout", selection: layout) {
                    ForEach(CollectionLayout.allCases, id: \.self) { option in
                        Label(option.label, systemImage: option.systemImage)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
                Divider()
            }
            ForEach(options, id: \.field) { option in
                Button {
                    onChange(option.field, option.field == field ? order.toggled() : .asc)
                } label: {
                    if option.field == field {
                        Label(option.label, systemImage: order == .asc ? "chevron.up" : "chevron.down")
                    } else {
                        Text(option.label)
                    }
                }
            }
        } label: {
            Label("Sort", systemImage: "line.3.horizontal.decrease")
        }
    }
}
