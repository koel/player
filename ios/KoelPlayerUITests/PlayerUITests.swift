import XCTest

/// Long-press menus, the queue and the playback settings, against `MockKoelServer`.
final class PlayerUITests: XCTestCase {
    private var app: XCUIApplication!
    private var server: MockKoelServer!

    override func setUpWithError() throws {
        continueAfterFailure = false
        server = try MockKoelServer()
        if name.contains("LargeQueue") { server.songCount = 2000 }
        if name.contains("SavedPresets") { server.keepsEqualizerPresets = true }
        if name.contains("NoFavorites") { server.hasFavorites = false }
        if name.contains("CannotManageRadio") { server.canManageRadioStations = false }
        try server.start()
        app = XCUIApplication()
        launchLoggedIn(app, to: server)
    }

    override func tearDown() {
        server?.stop()
    }

    func testLongPressingASongShowsItsMenu() {
        openLibraryList(app, named: "Songs")
        let song = app.cells.element(boundBy: 2)
        XCTAssertTrue(song.waitForExistence(timeout: 15))

        song.press(forDuration: 1.2)

        XCTAssertTrue(app.buttons["Play Next"].waitForExistence(timeout: 5), "The long-press menu never appeared")
        XCTAssertTrue(app.buttons["Go to Album"].exists)
        attachScreenshot(of: app, named: "Song menu")
    }

    func testTheLibraryShowsTheAlbumsAddedLast() {
        selectRoot(ofTab: "Library", in: app)
        let album = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Test Album")).firstMatch
        XCTAssertTrue(album.waitForExistence(timeout: 15), "Recently added never showed in the Library")
        for _ in 0..<5 where !album.isHittable { app.swipeUp(velocity: .slow) }

        album.tap()
        XCTAssertTrue(app.staticTexts[MockKoelServer.songTitles[0]].waitForExistence(timeout: 10), "Tapping the album didn't open it")
    }

    func testTheAlbumsAboutSectionStandsApartFromItsSongs() {
        selectRoot(ofTab: "Library", in: app)
        let album = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Test Album")).firstMatch
        XCTAssertTrue(album.waitForExistence(timeout: 15))
        for _ in 0..<5 where !album.isHittable { app.swipeUp(velocity: .slow) }
        album.tap()

        let about = app.staticTexts["About"]
        for _ in 0..<15 where !about.isHittable { app.swipeUp(velocity: .slow) }
        XCTAssertTrue(about.isHittable, "The album's About section never showed")
        let songRows = app.cells.containing(NSPredicate(format: "label BEGINSWITH %@", "Song ")).allElementsBoundByIndex
        let lastSongBottom = songRows.map { $0.frame.maxY }.filter { $0 <= about.frame.minY }.max() ?? 0
        XCTAssertGreaterThanOrEqual(about.frame.minY - lastSongBottom, 32, "About sits right under the last song")
    }

    func testAlbumsCanBeListed() {
        openLibraryList(app, named: "Albums")
        app.navigationBars.buttons["Sort"].tap()
        app.buttons["List"].firstMatch.tap()

        let row = app.collectionViews.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Test Album")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 15), "Albums never showed as a list")
        XCTAssertTrue(row.label.contains("Test Artist"), "The album row doesn't show its artist")
    }

    func testTheLibraryShowsTheMostPlayedSongs() {
        selectRoot(ofTab: "Library", in: app)
        let heading = app.staticTexts["Most played"]
        for _ in 0..<8 where !heading.exists { app.swipeUp(velocity: .slow) }
        XCTAssertTrue(heading.waitForExistence(timeout: 15), "Most played never showed in the Library")

        let song = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", MockKoelServer.songTitles[0])).firstMatch
        for _ in 0..<5 where !song.isHittable { app.swipeUp(velocity: .slow) }
        XCTAssertTrue(song.exists, "The most played song isn't listed")
    }

    func testPodcastsListTheNewEpisodesFirstThenAllPodcastsInLine() {
        openLibraryList(app, named: "Podcasts")

        XCTAssertTrue(app.staticTexts["New Episodes"].waitForExistence(timeout: 15), "Podcasts showed no New Episodes")
        let episode = app.staticTexts[MockKoelServer.episodeTitle]
        XCTAssertTrue(episode.exists, "The new episode isn't listed")
        let allPodcasts = app.staticTexts["All Podcasts"]
        XCTAssertTrue(allPodcasts.waitForExistence(timeout: 5), "The podcasts have no header")
        let podcast = app.staticTexts[MockKoelServer.podcastTitle]
        XCTAssertTrue(podcast.exists)
        XCTAssertLessThan(episode.frame.maxY, allPodcasts.frame.minY)
        XCTAssertLessThan(allPodcasts.frame.maxY, podcast.frame.minY)
        XCTAssertEqual(podcast.frame.minX, episode.frame.minX, accuracy: 1, "Podcast titles don't line up with episode titles")
    }

    func testOpeningPodcastsLeavesHomesSectionsAlone() {
        selectRoot(ofTab: "Home", in: app)
        XCTAssertTrue(app.staticTexts[MockKoelServer.songTitles[0]].firstMatch.waitForExistence(timeout: 15), "Home never loaded")
        server.forgetRequests()

        openLibraryList(app, named: "Podcasts")

        XCTAssertNotNil(firstRequest(startingWith: "/api/podcasts"), "Podcasts never loaded")
        XCTAssertTrue(app.staticTexts[MockKoelServer.episodeTitle].waitForExistence(timeout: 10), "The new episode isn't listed")
        XCTAssertFalse(server.requestedPaths.contains { $0.hasPrefix("/api/overview") }, "Opening Podcasts reloaded Home's overview")
    }

    func testASongFavoritedFromSearchOffersToUndoIt() {
        searchLibrary(for: "Album")
        let song = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", MockKoelServer.songTitles[0])).firstMatch
        XCTAssertTrue(song.waitForExistence(timeout: 15), "Search found no song")

        assertFavoritingFlipsTheMenu(of: song)
    }

    func testAnAlbumFavoritedFromSearchOffersToUndoIt() {
        searchLibrary(for: "Album")
        let album = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Test Album")).firstMatch
        XCTAssertTrue(album.waitForExistence(timeout: 15), "Search found no album")

        assertFavoritingFlipsTheMenu(of: album)
    }

    func testASubmittedSearchCanBeRunAgainFromRecentlySearched() {
        searchLibrary(for: "Album\n")
        let song = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", MockKoelServer.songTitles[0])).firstMatch
        XCTAssertTrue(song.waitForExistence(timeout: 15), "Search found no song")

        app.searchFields["Search your library"].buttons["Clear text"].tap()
        let recent = app.buttons["Album"]
        XCTAssertTrue(app.staticTexts["Recently Searched"].waitForExistence(timeout: 5), "Clearing the search showed no recent searches")
        recent.tap()

        XCTAssertTrue(song.waitForExistence(timeout: 15), "Tapping a recent search didn't run it again")
    }

    func testTappingASearchResultRemembersTheSearch() {
        searchLibrary(for: "Album")
        let song = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", MockKoelServer.songTitles[0])).firstMatch
        XCTAssertTrue(song.waitForExistence(timeout: 15), "Search found no song")

        app.buttons["Songs"].firstMatch.tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.searchFields["Search your library"].buttons["Clear text"].tap()

        XCTAssertTrue(app.buttons["Album"].waitForExistence(timeout: 5), "Tapping a result didn't remember the search")
    }

    func testSwipingAwayTheLastRecentSearchHidesRecentlySearched() {
        searchLibrary(for: "Album\n")
        app.searchFields["Search your library"].buttons["Clear text"].tap()
        let recent = app.buttons["Album"]
        XCTAssertTrue(recent.waitForExistence(timeout: 5), "Clearing the search showed no recent searches")

        recent.swipeLeft()
        let remove = app.buttons["Remove"]
        XCTAssertTrue(remove.waitForExistence(timeout: 5), "Swiping a recent search showed no Remove button")
        remove.tap()

        XCTAssertTrue(app.staticTexts["Recently Searched"].waitForNonExistence(timeout: 5), "Recently Searched stayed with nothing in it")
    }

    private func searchLibrary(for keywords: String) {
        let searchField = app.searchFields["Search your library"]
        for _ in 0..<5 where !searchField.waitForExistence(timeout: 2) {
            app.tabBars.buttons["Search"].tap()
        }
        searchField.tap()
        searchField.typeText(keywords)
    }

    private func assertFavoritingFlipsTheMenu(of element: XCUIElement) {
        element.press(forDuration: 1.2)
        let favorite = app.buttons["Favorite"]
        XCTAssertTrue(favorite.waitForExistence(timeout: 5), "The menu offered no Favorite")
        favorite.tap()
        XCTAssertTrue(favorite.waitForNonExistence(timeout: 5), "The menu never closed")

        element.press(forDuration: 1.2)

        XCTAssertTrue(app.buttons["Undo Favorite"].waitForExistence(timeout: 5), "The menu still offered Favorite after favoriting")
    }

    func testAStationFoundBySearchOpensItsEditForm() {
        let searchField = app.searchFields["Search your library"]
        for _ in 0..<5 where !searchField.waitForExistence(timeout: 2) {
            app.tabBars.buttons["Search"].tap()
        }
        searchField.tap()
        searchField.typeText("Test")

        let station = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", MockKoelServer.stationName)).firstMatch
        XCTAssertTrue(station.waitForExistence(timeout: 15), "Search found no station")
        station.press(forDuration: 1)
        app.buttons["Edit…"].tap()

        XCTAssertTrue(app.navigationBars["Edit Station"].waitForExistence(timeout: 5), "The Edit Station form never opened")
        XCTAssertEqual(app.textFields["Station Name"].value as? String, MockKoelServer.stationName)
    }

    func testTheLibrarysRadioCanAddAStation() {
        openLibraryList(app, named: "Radio")

        app.navigationBars.buttons["New Station"].tap()
        XCTAssertTrue(app.navigationBars["New Station"].waitForExistence(timeout: 5), "The New Station form never opened")
    }

    func testAUserWhoCannotManageRadioCannotAddAStation() {
        openLibraryList(app, named: "Radio")
        XCTAssertTrue(app.staticTexts["No radio stations"].waitForExistence(timeout: 15), "Radio never showed its empty state")

        XCTAssertFalse(app.navigationBars.buttons["New Station"].exists, "Radio offered New Station to a user who can't manage stations")
        XCTAssertFalse(app.buttons["Add a Station"].exists, "Radio offered Add a Station to a user who can't manage stations")
    }

    func testTheEndOfAListStaysClearOfTheTabBar() throws {
        openLibraryList(app, named: "Songs")
        let lastSong = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", MockKoelServer.songTitles.last!)).firstMatch
        for _ in 0..<10 where !lastSong.isHittable { app.swipeUp(velocity: .fast) }
        sleep(1)

        let gap = app.tabBars.firstMatch.frame.minY - lastSong.frame.maxY
        XCTAssertGreaterThanOrEqual(gap.rounded(), 16, "The last song sits against the tab bar")
    }

    func testSongsAndFavoritesSpaceTheirPlayButtonsTheSame() {
        XCTAssertEqual(gapBelowPlayButtons(inList: "Songs"), gapBelowPlayButtons(inList: "Favorites"))
    }

    private func gapBelowPlayButtons(inList name: String) -> CGFloat {
        openLibraryList(app, named: name)
        let play = app.collectionViews.buttons["Play"].firstMatch
        let firstSong = app.collectionViews.buttons.matching(NSPredicate(format: "label CONTAINS %@", MockKoelServer.songTitles[0])).firstMatch
        XCTAssertTrue(firstSong.waitForExistence(timeout: 15), "\(name) never showed its songs")
        return firstSong.frame.minY - play.frame.maxY
    }

    func testNoFavoritesMeansNoFilterField() {
        openLibraryList(app, named: "Favorites")
        XCTAssertTrue(app.staticTexts["No favorites"].waitForExistence(timeout: 15), "Favorites never showed its empty state")

        app.collectionViews.firstMatch.swipeDown()

        XCTAssertFalse(app.searchFields.firstMatch.exists, "An empty Favorites still offered a filter field")
    }

    func testFilteringFavoritesToNothingShowsNoResults() {
        openLibraryList(app, named: "Favorites")
        let firstSong = app.collectionViews.buttons.matching(NSPredicate(format: "label CONTAINS %@", MockKoelServer.songTitles[0])).firstMatch
        XCTAssertTrue(firstSong.waitForExistence(timeout: 15), "Favorites never showed its songs")

        filter(with: "zzzz")

        let noResults = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "No Results")).firstMatch
        XCTAssertTrue(noResults.waitForExistence(timeout: 5), "Filtering Favorites to nothing showed no No Results state")
    }

    func testDownloadsRememberTheirSort() {
        openLibraryList(app, named: "Songs")
        let download = app.collectionViews.buttons["Download"].firstMatch
        XCTAssertTrue(download.waitForExistence(timeout: 15), "Songs have no Download button")
        download.tap()
        XCTAssertTrue(app.collectionViews.images["Downloaded"].firstMatch.waitForExistence(timeout: 15), "The first song never downloaded")
        app.collectionViews.buttons["Download"].firstMatch.tap()
        let bothDownloaded = NSPredicate(format: "count >= 2")
        wait(for: [expectation(for: bothDownloaded, evaluatedWith: app.collectionViews.images.matching(identifier: "Downloaded"))], timeout: 15)

        openLibraryList(app, named: "Downloaded")
        XCTAssertTrue(songRow(1).waitForExistence(timeout: 10), "Downloaded never showed the songs")
        let wasFirstSongOnTop = songRow(1).frame.minY < songRow(2).frame.minY
        app.navigationBars.buttons["Sort"].tap()
        app.buttons["Title"].firstMatch.tap()
        XCTAssertEqual(songRow(1).frame.minY > songRow(2).frame.minY, wasFirstSongOnTop, "Picking Title again didn't flip the order")

        openLibraryList(app, named: "Downloaded")
        XCTAssertTrue(songRow(1).waitForExistence(timeout: 10))
        XCTAssertEqual(songRow(1).frame.minY > songRow(2).frame.minY, wasFirstSongOnTop, "Downloaded forgot its sort")

        app.navigationBars.buttons["Remove all"].tap()
        app.buttons["Remove all downloads"].firstMatch.tap()
    }

    func testListsLoadInTheirSavedSortAfterARelaunch() {
        let savedSorts = [
            (list: "Songs", option: "Artist", request: "/api/songs?", sort: "sort=artist_name"),
            (list: "Albums", option: "Year", request: "/api/albums?", sort: "sort=year"),
            (list: "Artists", option: "Recently added", request: "/api/artists?", sort: "sort=created_at"),
        ]
        for saved in savedSorts {
            openLibraryList(app, named: saved.list)
            pickSort(saved.option)
        }

        app.terminate()
        server.forgetRequests()
        launchLoggedIn(app, to: server)

        for saved in savedSorts {
            openLibraryList(app, named: saved.list)
            let firstLoad = firstRequest(startingWith: saved.request)
            XCTAssertTrue(firstLoad?.contains(saved.sort) == true, "\(saved.list) first loaded with \(firstLoad ?? "no request")")
        }

        for (list, defaultOption) in [("Songs", "Title"), ("Albums", "Name"), ("Artists", "Name")] {
            openLibraryList(app, named: list)
            pickSort(defaultOption)
        }
    }

    private func pickSort(_ option: String) {
        let sort = app.navigationBars.buttons["Sort"]
        XCTAssertTrue(sort.waitForExistence(timeout: 10), "No Sort button")
        sort.tap()
        app.buttons[option].firstMatch.tap()
    }

    private func firstRequest(startingWith prefix: String) -> String? {
        let deadline = Date().addingTimeInterval(10)
        while Date() < deadline {
            if let request = server.requestedPaths.first(where: { $0.hasPrefix(prefix) }) { return request }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return nil
    }

    private func songRow(_ number: Int) -> XCUIElement {
        app.collectionViews.buttons.matching(NSPredicate(format: "label CONTAINS %@", MockKoelServer.songTitles[number - 1])).firstMatch
    }

    /// The filter field hides until the list is pulled down.
    private func filter(with text: String) {
        let field = app.searchFields.firstMatch
        for _ in 0..<3 where !field.isHittable {
            app.collectionViews.firstMatch.swipeDown()
        }
        field.tap()
        field.typeText(text)
    }

    func testScrollingALargeQueueWhilePlaying() {
        openLibraryList(app, named: "Songs")
        let play = app.collectionViews.buttons["Play"].firstMatch
        XCTAssertTrue(play.waitForExistence(timeout: 15))
        play.tap()
        XCTAssertTrue(app.buttons["Pause"].firstMatch.waitForExistence(timeout: 20), "Playback never started")
        openNowPlayingFromTheMiniPlayer()
        XCTAssertTrue(app.staticTexts["Queued"].waitForExistence(timeout: 10), "Now Playing never showed the queue")

        let options = XCTMeasureOptions()
        options.invocationOptions = [.manuallyStop]
        measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric], options: options) {
            app.swipeUp(velocity: .fast)
            stopMeasuring()
            app.swipeDown(velocity: .fast)
        }
    }

    func testLongPressingAnAlbumOnTheArtistScreenShowsItsMenu() {
        openLibraryList(app, named: "Songs")
        let song = app.cells.element(boundBy: 2)
        XCTAssertTrue(song.waitForExistence(timeout: 15))
        song.press(forDuration: 1.2)
        app.buttons["Go to Artist"].firstMatch.tap()
        let album = app.scrollViews.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Test Album")).firstMatch
        XCTAssertTrue(album.waitForExistence(timeout: 15), "The artist screen never showed its albums")

        album.press(forDuration: 1.2)

        XCTAssertTrue(app.buttons["Play Next"].waitForExistence(timeout: 5), "The album's menu never loaded")
    }

    func testSwipingAQueuedSongRemovesIt() throws {
        openTheQueue()

        let queued = try XCTUnwrap(visibleQueuedRow(after: 1), "No queued song on screen")
        let title = queued.staticTexts.firstMatch.label
        let rowsWithTitle = app.cells.containing(.staticText, identifier: title)
        let countBefore = rowsWithTitle.count
        queued.swipeLeft()
        let remove = app.buttons["Remove"]
        XCTAssertTrue(remove.waitForExistence(timeout: 5), "Swiping a queued song showed no Remove button")
        remove.tap()

        let removed = expectation(for: NSPredicate(format: "count < %d", countBefore), evaluatedWith: rowsWithTitle)
        wait(for: [removed], timeout: 5)
    }

    func testLongPressingAQueuedSongShowsItsMenu() throws {
        openTheQueue()
        let queued = try XCTUnwrap(visibleQueuedRow(), "No queued song on screen")

        XCTAssertFalse(queued.buttons["More"].exists, "Queued songs shouldn't have a More button")
        XCTAssertFalse(queued.buttons["Download"].exists, "Queued songs shouldn't have a Download button")
        queued.press(forDuration: 1.2)

        XCTAssertTrue(app.buttons["Go to Album"].waitForExistence(timeout: 5), "Long-pressing a queued song didn't show its menu")
    }

    func testGoingToAQueuedSongsAlbumClosesNowPlaying() throws {
        openTheQueue()
        let queued = try XCTUnwrap(visibleQueuedRow(), "No queued song on screen")
        queued.press(forDuration: 1.2)

        app.buttons["Go to Album"].firstMatch.tap()

        XCTAssertTrue(app.staticTexts["Queued"].waitForNonExistence(timeout: 5), "Now Playing stayed open over the album")
        XCTAssertTrue(app.staticTexts["Test Album"].firstMatch.waitForExistence(timeout: 10), "The album never showed")
    }

    func testDraggingAQueuedSongsHandleReordersTheQueue() {
        openTheQueue()
        let handle = app.buttons["Reorder Song 02"]
        let target = app.buttons["Reorder Song 05"]
        XCTAssertTrue(handle.waitForExistence(timeout: 5), "Queued songs have no drag handle")

        handle.press(forDuration: 0.3, thenDragTo: target)

        let movedBelow = NSPredicate { _, _ in handle.frame.minY > self.app.buttons["Reorder Song 04"].frame.minY }
        wait(for: [expectation(for: movedBelow, evaluatedWith: nil)], timeout: 5)
        sleep(1)
        XCTAssertGreaterThan(handle.frame.minY, app.buttons["Reorder Song 04"].frame.minY, "The player put the song back")
        XCTAssertLessThan(handle.frame.minY, app.buttons["Reorder Song 06"].frame.minY, "The player moved the song to the wrong place")
    }

    func testNowPlayingFitsItsControlsOnScreen() {
        openNowPlaying()
        attachScreenshot(of: app, named: "Now Playing")

        let playerBottomPadding: CGFloat = 12
        let player = app.cells.firstMatch.frame
        let bottomBar = app.buttons["AirPlay"].frame
        XCTAssertLessThanOrEqual(bottomBar.maxY, player.maxY - playerBottomPadding + 0.5, "The player's controls run past its bottom")
    }

    func testNowPlayingPutsThePlaybackSettingsFirstAndTheLyricsAfterAirPlay() {
        openNowPlaying()

        let order = ["Playback settings", "AirPlay", "Lyrics and Details"]
            .sorted { app.buttons[$0].firstMatch.frame.minX < app.buttons[$1].firstMatch.frame.minX }
        XCTAssertEqual(order, ["Playback settings", "AirPlay", "Lyrics and Details"])
    }

    func testTheDetailsSheetShowsTheSongOnTheLeftAndSwitchesTabs() {
        openNowPlaying()

        app.buttons["Lyrics and Details"].firstMatch.tap()

        let header = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@ AND label ENDSWITH %@", "Song ", ", Test Artist")).firstMatch
        XCTAssertTrue(header.waitForExistence(timeout: 5), "The details sheet shows no title and artist")
        XCTAssertLessThan(header.frame.minX, app.windows.firstMatch.frame.width / 4, "The details header isn't on the left")

        let albumTab = app.buttons["Album"].firstMatch
        albumTab.tap()
        XCTAssertTrue(albumTab.isSelected, "Tapping a details tab didn't select it")
        XCTAssertFalse(app.buttons["Lyrics"].firstMatch.isSelected, "Two details tabs are selected")
    }

    func testPickingAnEqualizerPresetInNowPlayingMovesTheBands() {
        openNowPlaying()
        app.buttons["Playback settings"].tap()
        let lowestBand = app.sliders["60 Hz"]
        XCTAssertTrue(lowestBand.waitForExistence(timeout: 5), "Now Playing's Playback Settings button showed no equalizer")

        presetPicker.tap()
        app.buttons["Rock"].firstMatch.tap()

        XCTAssertEqual(lowestBand.value as? String, "+8 dB")
        XCTAssertEqual(app.sliders["Preamp"].value as? String, "-10 dB")
    }

    func testASongThatWontPlayShowsABriefError() throws {
        openNowPlaying()
        server.streamsAudio = false
        let next = app.buttons.matching(identifier: "Next").allElementsBoundByIndex.first { $0.isHittable }
        try XCTUnwrap(next, "Now Playing has no Next button").tap()

        let error = app.staticTexts["Couldn't play this item"]
        XCTAssertTrue(error.waitForExistence(timeout: 20), "Now Playing showed no error")
        XCTAssertTrue(error.waitForNonExistence(timeout: 5), "The error stayed on screen")
    }

    func testThePlaybackSettingsFromTheProfileMenuCantSavePresetsOnOlderServers() {
        openPlaybackSettingsFromTheProfileMenu()
        app.sliders["60 Hz"].swipeUp()

        XCTAssertTrue(app.sliders["Crossfade"].exists)
        XCTAssertFalse(app.buttons["Save as…"].exists, "A server without saved presets offered to save one")
    }

    func testSavedPresetsCanBeSavedAndRemoved() {
        openPlaybackSettingsFromTheProfileMenu()
        presetPicker.tap()
        app.buttons["Rock"].firstMatch.tap()
        let save = app.buttons["Save as…"]
        XCTAssertFalse(save.exists, "Offered to save a setting that is already a preset")

        app.sliders["60 Hz"].swipeUp()
        XCTAssertTrue(save.waitForExistence(timeout: 5), "A server with saved presets didn't offer to save a changed setting")

        save.tap()
        app.textFields["Preset Name"].typeText("Mine")
        app.buttons["Save"].tap()

        let remove = app.buttons["Remove"]
        XCTAssertTrue(remove.waitForExistence(timeout: 5), "The saved preset didn't become the current one")
        XCTAssertFalse(save.exists, "Offered to save the preset that was just saved")
        remove.tap()
        app.buttons["Remove Preset"].firstMatch.tap()
        XCTAssertTrue(remove.waitForNonExistence(timeout: 5), "Removing the preset didn't take")
    }

    private func openPlaybackSettingsFromTheProfileMenu() {
        select(tab: "Home", in: app)
        let playbackSettings = app.buttons["Playback settings"].firstMatch
        for _ in 0..<3 where !playbackSettings.waitForExistence(timeout: 2) {
            app.buttons["Profile"].firstMatch.tap()
        }
        playbackSettings.tap()
        XCTAssertTrue(app.sliders["60 Hz"].waitForExistence(timeout: 5), "The profile menu's Playback Settings showed no equalizer")
    }

    private var presetPicker: XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Preset")).firstMatch
    }

    private func openNowPlaying() {
        openLibraryList(app, named: "Songs")
        let play = app.collectionViews.buttons["Play"].firstMatch
        XCTAssertTrue(play.waitForExistence(timeout: 15))
        play.tap()
        XCTAssertTrue(app.buttons["Pause"].firstMatch.waitForExistence(timeout: 20), "Playback never started")

        app.buttons["Pause"].firstMatch.tap()
        openNowPlayingFromTheMiniPlayer()
        XCTAssertTrue(app.staticTexts["Queued"].waitForExistence(timeout: 10), "Now Playing never showed the queue")
    }

    private func openTheQueue() {
        openNowPlaying()
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
            .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)))
    }

    /// A queue row fully on screen, below the "Queued" heading and clear of the home indicator.
    private func visibleQueuedRow(after skipped: Int = 0) -> XCUIElement? {
        let headingBottom = app.staticTexts["Queued"].frame.maxY
        let screenBottom = app.windows.firstMatch.frame.maxY * 0.9
        return app.cells.allElementsBoundByIndex.filter { cell in
            cell.frame.minY > headingBottom && cell.frame.maxY < screenBottom
        }.dropFirst(skipped).first
    }

    func testAFlickCarriesAShelfPastMoreThanOneCard() {
        selectRoot(ofTab: "Home", in: app)
        let shelfTitle = app.staticTexts["New Songs"]
        XCTAssertTrue(shelfTitle.waitForExistence(timeout: 15), "New Songs never showed")
        for _ in 0..<8 where !shelfTitle.isHittable || shelfTitle.frame.minY > app.frame.height * 0.5 { app.swipeUp(velocity: .slow) }

        let shelf = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: app.frame.width * 0.9, dy: shelfTitle.frame.maxY + 80))
        shelf.press(forDuration: 0.01, thenDragTo: shelf.withOffset(CGVector(dx: -app.frame.width * 0.6, dy: 0)), withVelocity: .fast, thenHoldForDuration: 0)

        let shelfCards = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Song ")).allElementsBoundByIndex.filter { $0.frame.minY > shelfTitle.frame.maxY }
        let cardsScrolledPast = shelfCards.filter { $0.frame.maxX < 0 }.count
        XCTAssertGreaterThan(cardsScrolledPast, 1, "The flick stopped after one card")
    }

    private func openNowPlayingFromTheMiniPlayer() {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.873)).tap()
    }
}
