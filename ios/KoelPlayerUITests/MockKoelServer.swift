import Foundation
import Network

/// A stand-in Koel server on localhost, so UI tests run without a real one. It knows a small
/// fixed library and streams a short tone for every song.
final class MockKoelServer: @unchecked Sendable {
    static let songTitles = (1...40).map { String(format: "Song %02d", $0) }
    static let email = "tester@koel.test"
    static let password = "secret"
    static let episodeTitle = "Test Episode"
    static let podcastTitle = "Test Podcast"
    static let stationName = "Test Station"

    private let listener: NWListener
    private let queue = DispatchQueue(label: "MockKoelServer")
    private let audio: Data

    /// How many songs the library holds.
    var songCount = songTitles.count

    /// Older servers don't keep a list of saved equalizer presets.
    var keepsEqualizerPresets = false

    var streamsAudio = true

    var hasFavorites = true

    var requiresTwoFactor = false

    var canManageRadioStations = true

    var checksLoginSlowly = false

    var rejectsSession = false

    var failsWithServerError = false

    private(set) var twoFactorCode: String?

    private var requests: [String] = []

    /// Paths with their query, in the order they arrived.
    var requestedPaths: [String] { queue.sync { requests } }

    func forgetRequests() {
        queue.sync { requests = [] }
    }

    private(set) var port: UInt16 = 0
    var host: String { "http://127.0.0.1:\(port)" }

    init() throws {
        listener = try NWListener(using: .tcp, on: .any)
        let audioUrl = try bundledResource("tone", withExtension: "mp3")
        audio = try Data(contentsOf: audioUrl)
    }

    func start() throws {
        let ready = DispatchSemaphore(value: 0)
        listener.stateUpdateHandler = { [weak self] state in
            if case .ready = state {
                self?.port = self?.listener.port?.rawValue ?? 0
                ready.signal()
            }
        }
        listener.newConnectionHandler = { [weak self] connection in
            self?.serve(connection)
        }
        listener.start(queue: queue)
        guard ready.wait(timeout: .now() + 5) == .success else {
            throw MockServerError.didNotStart
        }
    }

    func stop() {
        listener.cancel()
    }

    // MARK: HTTP

    private func serve(_ connection: NWConnection) {
        connection.start(queue: queue)
        receiveRequest(on: connection, buffer: Data())
    }

    private func receiveRequest(on connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] chunk, _, isComplete, error in
            guard let self, error == nil else { connection.cancel(); return }
            let data = buffer + (chunk ?? Data())

            guard let request = Request(data) else {
                if isComplete { connection.cancel() } else { self.receiveRequest(on: connection, buffer: data) }
                return
            }

            connection.send(content: self.response(to: request), completion: .contentProcessed { _ in
                connection.cancel()
            })
        }
    }

    static let token = "api-token"

    private let tokens = ["token": MockKoelServer.token, "audio-token": MockKoelServer.token]

    private func response(to request: Request) -> Data {
        requests.append(request.path)
        let path = request.path.split(separator: "?").first.map(String.init) ?? request.path

        if path.hasPrefix("/play/") {
            guard streamsAudio else { return http(status: "404 Not Found", contentType: "application/json", body: Data("{}".utf8)) }
            return audioResponse(range: request.headers["range"])
        }

        if failsWithServerError {
            return http(status: "500 Internal Server Error", contentType: "application/json", body: Data("{}".utf8))
        }

        switch (request.method, path) {
        case ("POST", "/api/me"):
            return requiresTwoFactor ? json(["two_factor": true, "login_token": "login-token"]) : json(tokens)
        case ("POST", "/api/me/two-factor-challenge"):
            let body = (try? JSONSerialization.jsonObject(with: request.body)) as? [String: Any]
            twoFactorCode = body?["code"] as? String
            return json(tokens)
        case ("GET", "/api/me"):
            if checksLoginSlowly { Thread.sleep(forTimeInterval: 3) }
            if rejectsSession { return http(status: "401 Unauthorized", contentType: "application/json", body: Data("{}".utf8)) }
            return json(user)
        case ("GET", "/api/data"):
            return json([
                "current_version": "v8.0.0",
                "cdn_url": host,
                "song_count": songCount,
                "playlists": [],
                "playlist_folders": [],
                "transcoding": false,
                "use_last_fm": false,
            ])
        case ("GET", "/api/overview"):
            return json([
                "recently_played_songs": Array(songs.prefix(4)),
                "most_played_songs": Array(songs.prefix(3)),
                "recently_added_songs": Array(songs.prefix(6)),
                "recently_added_albums": [album],
                "recently_added_episodes": [[
                    "type": "episodes", "id": "episode-1", "title": Self.episodeTitle, "podcast_id": "podcast-1",
                    "podcast_title": Self.podcastTitle, "length": 30.0, "created_at": "2024-01-01T00:00:00Z",
                ]],
            ])
        case ("GET", "/api/podcasts"):
            return json([["type": "podcasts", "id": "podcast-1", "title": Self.podcastTitle, "author": "Test Host"]])
        case ("GET", "/api/search") where request.path.contains("q=Album"):
            return json(["songs": Array(songs.prefix(3)), "albums": [album]])
        case ("GET", "/api/search"):
            return json([
                "songs": [],
                "radio_stations": [[
                    "type": "radio-stations", "id": "station-1", "name": Self.stationName, "url": "https://radio.koel.test/stream",
                    "permissions": ["edit": true, "delete": true],
                ]],
            ])
        case ("GET", "/api/artists/artist-1"):
            return json(["type": "artists", "id": "artist-1", "name": "Test Artist", "image": ""])
        case ("GET", "/api/artists/artist-1/songs"):
            return json(songs)
        case ("GET", "/api/artists"):
            return json(["data": [["type": "artists", "id": "artist-1", "name": "Test Artist", "image": ""]], "links": ["next": NSNull()], "meta": ["current_page": 1]])
        case ("GET", "/api/albums"):
            return json(["data": [album], "links": ["next": NSNull()], "meta": ["current_page": 1]])
        case ("GET", "/api/albums/album-1"):
            return json(album)
        case ("GET", "/api/albums/album-1/information"):
            return json(["wiki": ["summary": "", "full": "Test Album is a test album."], "tracks": []])
        case ("GET", "/api/albums/album-1/songs"):
            return json(songs)
        case ("GET", "/api/songs"):
            return json(["data": songs, "links": ["next": NSNull()], "meta": ["current_page": 1]])
        case ("GET", "/api/queue/fetch"):
            return json(songs)
        case ("GET", "/api/songs/favorite"):
            return json(hasFavorites ? Array(songs.prefix(3)) : [])
        case ("GET", "/api/radio/stations"):
            return json([])
        case ("GET", "/api/songs/recently-played"):
            return json(Array(songs.prefix(4)))
        case ("POST", "/api/me/equalizer-presets"):
            var preset = (try? JSONSerialization.jsonObject(with: request.body)) as? [String: Any] ?? [:]
            preset["id"] = "custom-preset-1"
            return json(preset)
        case ("PUT", _), ("PATCH", "/api/me/preferences"), ("POST", "/api/interaction/play"), ("POST", "/api/interaction/like"), ("POST", "/api/favorites/toggle"):
            return json([:])
        case ("DELETE", _) where path.hasPrefix("/api/me/equalizer-presets/"):
            return json([:])
        default:
            return http(status: "404 Not Found", contentType: "application/json", body: Data("{}".utf8))
        }
    }

    private var user: [String: Any] {
        let preferences: [String: Any] = keepsEqualizerPresets ? ["equalizer_presets": []] : [:]
        let abilities = canManageRadioStations ? ["manage radio stations"] : []
        return ["type": "users", "id": "user-1", "name": "Tester", "email": Self.email, "avatar": "", "preferences": preferences, "abilities": abilities]
    }

    private var album: [String: Any] {
        ["type": "albums", "id": "album-1", "name": "Test Album", "artist_id": "artist-1", "artist_name": "Test Artist"]
    }

    private var songs: [[String: Any]] {
        (0..<songCount).map { index in
            [
                "type": "songs",
                "id": "song-\(index + 1)",
                "title": String(format: "Song %02d", index + 1),
                "lyrics": "",
                "album_id": "album-1",
                "album_name": "Test Album",
                "artist_id": "artist-1",
                "artist_name": "Test Artist",
                "album_artist_id": "artist-1",
                "album_artist_name": "Test Artist",
                "album_cover": "",
                "length": 30.0,
                "favorite": false,
                "liked": false,
                "play_count": 0,
                "track": index + 1,
                "disc": 1,
                "genre": "Test",
                "year": 2024,
                "created_at": "2024-01-01T00:00:00Z",
            ]
        }
    }

    private func json(_ object: Any) -> Data {
        let body = (try? JSONSerialization.data(withJSONObject: object)) ?? Data("{}".utf8)
        return http(status: "200 OK", contentType: "application/json", body: body)
    }

    /// AVPlayer asks for byte ranges, and won't play a stream that ignores them.
    private func audioResponse(range: String?) -> Data {
        guard let range, let bounds = Self.byteRange(range, length: audio.count) else {
            return http(status: "200 OK", contentType: "audio/mpeg", body: audio, extraHeaders: ["Accept-Ranges": "bytes"])
        }
        return http(
            status: "206 Partial Content",
            contentType: "audio/mpeg",
            body: audio.subdata(in: bounds.lowerBound..<(bounds.upperBound + 1)),
            extraHeaders: ["Accept-Ranges": "bytes", "Content-Range": "bytes \(bounds.lowerBound)-\(bounds.upperBound)/\(audio.count)"]
        )
    }

    private static func byteRange(_ header: String, length: Int) -> ClosedRange<Int>? {
        guard header.hasPrefix("bytes=") else { return nil }
        let parts = header.dropFirst("bytes=".count).split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 2, let start = Int(parts[0]), start < length else { return nil }
        let end = min(Int(parts[1]) ?? (length - 1), length - 1)
        return start...end
    }

    private func http(status: String, contentType: String, body: Data, extraHeaders: [String: String] = [:]) -> Data {
        var head = "HTTP/1.1 \(status)\r\nContent-Type: \(contentType)\r\nContent-Length: \(body.count)\r\nConnection: close\r\n"
        for (name, value) in extraHeaders { head += "\(name): \(value)\r\n" }
        head += "\r\n"
        return Data(head.utf8) + body
    }
}

private struct Request {
    let method: String
    let path: String
    let headers: [String: String]
    let body: Data

    /// Nil until the head and the whole body have arrived.
    init?(_ data: Data) {
        guard let headEnd = data.range(of: Data("\r\n\r\n".utf8)),
              let head = String(data: data[..<headEnd.lowerBound], encoding: .utf8)
        else { return nil }

        let lines = head.components(separatedBy: "\r\n")
        let requestLine = lines[0].split(separator: " ")
        guard requestLine.count >= 2 else { return nil }

        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            guard let colon = line.firstIndex(of: ":") else { continue }
            headers[line[..<colon].lowercased()] = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
        }

        let bodyLength = Int(headers["content-length"] ?? "") ?? 0
        guard data.count - headEnd.upperBound >= bodyLength else { return nil }

        method = String(requestLine[0])
        path = String(requestLine[1])
        self.headers = headers
        body = data.subdata(in: headEnd.upperBound..<(headEnd.upperBound + bodyLength))
    }
}

enum MockServerError: Error {
    case didNotStart
    case missingResource(String)
}

private func bundledResource(_ name: String, withExtension fileExtension: String) throws -> URL {
    guard let url = Bundle(for: MockKoelServer.self).url(forResource: name, withExtension: fileExtension) else {
        throw MockServerError.missingResource("\(name).\(fileExtension)")
    }
    return url
}
