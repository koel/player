@testable import KoelPlayer
@preconcurrency import Shared
import Testing

struct PodcastAndRadioFormTests {
    @Test(arguments: [
        ("https://feeds.example.com/show.xml", true),
        ("  http://radio.example.com:8000/stream ", true),
        ("feeds.example.com/show.xml", false),
        ("ftp://example.com/feed", false),
        ("https://", false),
        ("", false),
    ])
    func acceptsOnlyAbsoluteWebURLs(input: String, isValid: Bool) {
        #expect(input.isWebURL == isValid)
    }

    @Test func explainsADuplicateSubscription() {
        #expect(PodcastActions.addFailureMessage(httpStatus: 409) == "You are already subscribed to this podcast.")
        #expect(PodcastActions.addFailureMessage(httpStatus: 500) == "Something wrong happened. Please try again.")
        #expect(PodcastActions.addFailureMessage(httpStatus: nil) == "Something wrong happened. Please try again.")
    }

    @Test func stationDraftNeedsANameAndAStreamURL() {
        var draft = RadioStationDraft()
        draft.name = "Jazz FM"
        draft.url = "not a url"
        #expect(!draft.isValid)

        draft.url = " https://jazz.example.com/live "
        #expect(draft.isValid)
        #expect(draft.trimmedURL == "https://jazz.example.com/live")

        draft.name = " "
        #expect(!draft.isValid)
    }

    @Test func stationDraftStartsFromTheEditedStation() {
        let station = RadioStation(
            id: "1",
            name: "Jazz FM",
            url: "https://jazz.example.com/live",
            logo: nil,
            description: "Smooth",
            isPublic: true,
            favorite: false,
            permissions: Permissions(edit: true, delete: true)
        )

        let draft = RadioStationDraft(station: station)

        #expect(draft.name == "Jazz FM")
        #expect(draft.url == "https://jazz.example.com/live")
        #expect(draft.description == "Smooth")
        #expect(draft.isPublic)
    }
}
