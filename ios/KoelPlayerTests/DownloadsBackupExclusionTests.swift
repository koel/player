import Foundation
@testable import KoelPlayer
import Testing

struct DownloadsBackupExclusionTests {
    @Test func keepsOnlyTheDownloadsFoldersOutOfBackup() throws {
        let documents = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: documents) }
        let downloads = documents.appending(path: String(repeating: "ab12", count: 16))
        let otherFolder = documents.appending(path: "Other")
        let storage = documents.appending(path: "Downloads.gs")
        try FileManager.default.createDirectory(at: downloads, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: otherFolder, withIntermediateDirectories: true)
        try Data().write(to: storage)

        DownloadsBackupExclusion.apply(in: documents)

        #expect(try isExcludedFromBackup(downloads))
        #expect(try !isExcludedFromBackup(otherFolder))
        #expect(try !isExcludedFromBackup(storage))
    }

    private func isExcludedFromBackup(_ url: URL) throws -> Bool {
        var fresh = url
        fresh.removeAllCachedResourceValues()
        return try fresh.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup ?? false
    }
}
