@preconcurrency import Shared
import SwiftUI
import UIKit

/// Now Playing's scroller: the player, then the queue. A UIKit list rather than a SwiftUI `List`, since only
/// a UIKit list shows drag handles outside edit mode alongside swipe actions, as Apple Music's queue does,
/// and builds only the rows on screen.
struct NowPlayingScroller<Player: View, Heading: View>: UIViewRepresentable {
    let queue: [any Playable]
    let playerHeight: CGFloat
    @ViewBuilder let player: () -> Player
    @ViewBuilder let heading: () -> Heading
    let onMove: (_ from: Int, _ to: Int) -> Void
    let onRemove: (any Playable) -> Void

    @Environment(AppModel.self) private var app
    @Environment(\.brandColor) private var brandColor

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UICollectionView {
        let coordinator = context.coordinator
        let collectionView = Self.makeCollectionView(layout: coordinator.layout())
        collectionView.delegate = coordinator
        coordinator.connect(to: collectionView)
        return collectionView
    }

    /// The sheet's blurred cover runs behind the status bar, so the list draws no edge effect there.
    static func makeCollectionView(layout: UICollectionViewLayout) -> UICollectionView {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.allowsSelection = false
        collectionView.selfSizingInvalidation = .disabled
        collectionView.topEdgeEffect.isHidden = true
        return collectionView
    }

    func updateUIView(_ collectionView: UICollectionView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.apply(queue)
    }

    final class Coordinator: NSObject, UICollectionViewDelegate {
        var parent: NowPlayingScroller!
        private var dataSource: UICollectionViewDiffableDataSource<NowPlayingSection, NowPlayingItem>!
        private var playables: [String: any Playable] = [:]

        func layout() -> UICollectionViewLayout {
            var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
            configuration.backgroundColor = .clear
            configuration.separatorConfiguration.color = UIColor(Color.hairline)
            configuration.itemSeparatorHandler = { [weak self] indexPath, separator in
                var separator = separator
                let isPlayable = self?.isPlayable(at: indexPath) ?? false
                separator.topSeparatorVisibility = .hidden
                separator.bottomSeparatorVisibility = isPlayable ? .visible : .hidden
                separator.bottomSeparatorInsets.leading = PlayableRow.dividerInset
                return separator
            }
            configuration.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
                guard let self, let playable = playable(at: indexPath) else { return nil }
                let remove = UIContextualAction(style: .destructive, title: "Remove") { _, _, completion in
                    self.parent.onRemove(playable)
                    completion(true)
                }
                remove.image = UIImage(systemName: "minus.circle")
                return UISwipeActionsConfiguration(actions: [remove])
            }
            return UICollectionViewCompositionalLayout.list(using: configuration)
        }

        func connect(to collectionView: UICollectionView) {
            let registration = UICollectionView.CellRegistration<UICollectionViewListCell, NowPlayingItem> { [weak self] cell, _, item in
                self?.configure(cell, for: item)
            }
            dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
                collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: item)
            }
            dataSource.reorderingHandlers.canReorderItem = { item in
                if case .playable = item { true } else { false }
            }
            dataSource.reorderingHandlers.didReorder = { [weak self] transaction in
                self?.commitMove(transaction)
            }
        }

        func apply(_ queue: [any Playable]) {
            let previous = playables
            playables = Dictionary(queue.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

            var snapshot = NSDiffableDataSourceSnapshot<NowPlayingSection, NowPlayingItem>()
            snapshot.appendSections([.player])
            snapshot.appendItems([.player], toSection: .player)
            if !queue.isEmpty {
                snapshot.appendSections([.queue])
                snapshot.appendItems([.heading] + queue.map { .playable(id: $0.id) }, toSection: .queue)
                snapshot.reconfigureItems([.heading])
            }
            let changed = queue.filter { playable in previous[playable.id].map { !($0 as AnyObject).isEqual(playable) } ?? false }
            snapshot.reconfigureItems([.player] + changed.map { .playable(id: $0.id) })
            dataSource.apply(snapshot, animatingDifferences: !previous.isEmpty)
        }

        private func configure(_ cell: UICollectionViewListCell, for item: NowPlayingItem) {
            cell.backgroundConfiguration = .clear()
            switch item {
            case .player:
                cell.accessories = []
                cell.contentConfiguration = UIHostingConfiguration {
                    parent.player().frame(height: parent.playerHeight).modifier(parent.environment)
                }
                .margins(.all, 0)
            case .heading:
                cell.accessories = []
                cell.contentConfiguration = UIHostingConfiguration { parent.heading().modifier(parent.environment) }
                    .margins(.horizontal, 0)
            case .playable(let id):
                guard let playable = playables[id] else { return }
                cell.accessories = [.reorder(displayed: .always, options: .init(tintColor: .secondaryLabel, showsVerticalSeparator: false))]
                cell.contentConfiguration = UIHostingConfiguration {
                    PlayableRow(playable: playable, style: .queue).modifier(parent.environment)
                }
                .margins(.horizontal, 16)
                .margins(.vertical, PlayableRow.verticalInset)
            }
        }

        private func commitMove(_ transaction: NSDiffableDataSourceTransaction<NowPlayingSection, NowPlayingItem>) {
            guard let difference = transaction.sectionTransactions.first(where: { $0.sectionIdentifier == .queue })?.difference else { return }
            var removedAt: Int?
            var insertedAt: Int?
            for change in difference {
                switch change {
                case .remove(let offset, _, _): removedAt = offset
                case .insert(let offset, _, _): insertedAt = offset
                }
            }
            guard let removedAt, let insertedAt else { return }
            let from = removedAt - 1
            let finalIndex = insertedAt - 1
            parent.onMove(from, finalIndex > from ? finalIndex + 1 : finalIndex)
        }

        private func playable(at indexPath: IndexPath) -> (any Playable)? {
            guard case .playable(let id) = dataSource.itemIdentifier(for: indexPath) else { return nil }
            return playables[id]
        }

        private func isPlayable(at indexPath: IndexPath) -> Bool {
            playable(at: indexPath) != nil
        }

        func collectionView(
            _ collectionView: UICollectionView,
            targetIndexPathForMoveOfItemFromOriginalIndexPath originalIndexPath: IndexPath,
            atCurrentIndexPath currentIndexPath: IndexPath,
            toProposedIndexPath proposedIndexPath: IndexPath
        ) -> IndexPath {
            let queueSection = dataSource.index(for: .queue) ?? originalIndexPath.section
            guard proposedIndexPath.section == queueSection else { return IndexPath(item: 1, section: queueSection) }
            return IndexPath(item: max(proposedIndexPath.item, 1), section: queueSection)
        }
    }

    /// Hosted cells sit outside the SwiftUI view tree, so they get the environment handed over.
    private var environment: HostedCellEnvironment {
        HostedCellEnvironment(app: app, brandColor: brandColor)
    }
}

nonisolated enum NowPlayingSection: Hashable, Sendable { case player, queue }

nonisolated enum NowPlayingItem: Hashable, Sendable {
    case player
    case heading
    case playable(id: String)
}

private struct HostedCellEnvironment: ViewModifier {
    let app: AppModel
    let brandColor: Color

    func body(content: Content) -> some View {
        content
            .environment(app)
            .environment(\.brandColor, brandColor)
            .tint(.primary)
    }
}
