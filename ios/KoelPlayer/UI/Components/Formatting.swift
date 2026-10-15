import Foundation

extension Double {
    /// "3:07" for songs, "1:02:03" for anything an hour or longer.
    var playbackTime: String {
        let duration = Duration.seconds(isFinite ? max(self, 0) : 0)
        return self >= 3600
            ? duration.formatted(.time(pattern: .hourMinuteSecond))
            : duration.formatted(.time(pattern: .minuteSecond))
    }

    /// "2 hr 5 min" for collection totals.
    var totalLength: String {
        Duration.seconds(self).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }
}

extension String {
    /// Koel sends ISO 8601 timestamps, with or without fractional seconds.
    var iso8601Date: Date? {
        (try? Date(self, strategy: .iso8601)) ?? (try? Date(self, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true)))
    }
}

extension Date {
    /// Recent dates read "3 days ago"; older ones (Flutter's 180-day cut-off) show the date.
    var episodeDateLabel: String {
        Date.now.timeIntervalSince(self) > 180 * 24 * 3600
            ? formatted(date: .abbreviated, time: .omitted)
            : formatted(.relative(presentation: .named))
    }
}

extension Int {
    func pluralized(_ singular: String, _ plural: String? = nil) -> String {
        "\(self) \(self == 1 ? singular : plural ?? singular + "s")"
    }
}
