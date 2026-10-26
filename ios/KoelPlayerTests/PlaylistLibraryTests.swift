import Foundation
@testable import KoelPlayer
@preconcurrency import Shared
import Testing

struct PlaylistLibraryTests {
    private func playlist(_ id: String, _ name: String, folderId: String? = nil, isSmart: Bool = false) -> Playlist {
        Playlist(
            id: id,
            name: name,
            isSmart: isSmart,
            folderId: folderId,
            description: nil,
            cover: nil,
            rules: nil,
            permissions: Permissions(edit: true, delete: true)
        )
    }

    @Test func groupsPlaylistsIntoFoldersSortedByName() {
        let library = PlaylistLibrary(
            playlists: [
                playlist("1", "Workout", folderId: "f2"),
                playlist("2", "chill", folderId: "f1"),
                playlist("3", "Ambient", folderId: "f1"),
                playlist("4", "Road Trip"),
                playlist("5", "Focus"),
            ],
            folders: [PlaylistFolder(id: "f2", name: "Sports"), PlaylistFolder(id: "f1", name: "Moods")]
        )

        #expect(library.folderGroups.map(\.folder.name) == ["Moods", "Sports"])
        #expect(library.folderGroups[0].playlists.map(\.name) == ["Ambient", "chill"])
        #expect(library.folderGroups[1].playlists.map(\.name) == ["Workout"])
        #expect(library.rootPlaylists.map(\.name) == ["Focus", "Road Trip"])
    }

    @Test func keepsEmptyFoldersAndShowsOrphanedPlaylistsAtTheRoot() {
        let library = PlaylistLibrary(
            playlists: [playlist("1", "Lost", folderId: "gone")],
            folders: [PlaylistFolder(id: "f1", name: "Empty")]
        )

        #expect(library.folderGroups.map(\.playlists.count) == [0])
        #expect(library.rootPlaylists.map(\.name) == ["Lost"])
    }

    @Test func draftRequiresANameAndTrimsInput() {
        var draft = PlaylistDraft()
        draft.name = "   "
        #expect(!draft.isValid)

        draft.name = "  Late Night "
        draft.description = " Mellow tunes\n"
        #expect(draft.isValid)
        #expect(draft.trimmedName == "Late Night")
        #expect(draft.trimmedDescription == "Mellow tunes")
    }

    @Test func draftStartsFromTheEditedPlaylist() {
        let draft = PlaylistDraft(playlist: playlist("1", "Jazz", folderId: "f1"))

        #expect(draft.name == "Jazz")
        #expect(draft.description.isEmpty)
        #expect(draft.folderId == "f1")
    }

    @Test func customOrderIsTheDefaultSortOnlyWhenTheServerSupportsIt() {
        let fields = PlayableSortField.shared

        #expect(SortOptions.playlistSongs(supportsCustomOrder: true).first?.field == fields.POSITION)
        #expect(SortOptions.playlistSongs(supportsCustomOrder: false).first?.field == fields.TITLE)
    }

    @Test func aRememberedCustomOrderFallsBackWhereTheServerDoesNotOfferIt() {
        let fields = PlayableSortField.shared
        let key = "test.\(UUID().uuidString)"
        let fallback = SortSetting(field: fields.TITLE, order: .asc)
        SortSetting(field: fields.POSITION, order: .desc).remember(for: key)

        #expect(SortSetting.remembered(for: key, among: SortOptions.playlistSongs(supportsCustomOrder: false), default: fallback) == fallback)
        #expect(SortSetting.remembered(for: key, among: SortOptions.playlistSongs(supportsCustomOrder: true), default: fallback).field == fields.POSITION)
    }
}
