import Foundation

/// Keeps downloaded songs out of iCloud Backup. The shared core stores each account's downloads in a
/// Documents subfolder named by a SHA-256 hex digest, the same path the Flutter app used.
enum DownloadsBackupExclusion {
    static func apply(in documents: URL) {
        let folders = (try? FileManager.default.contentsOfDirectory(at: documents, includingPropertiesForKeys: [.isDirectoryKey])) ?? []
        for var folder in folders where isDownloadsFolder(folder) {
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? folder.setResourceValues(values)
        }
    }

    private static func isDownloadsFolder(_ url: URL) -> Bool {
        let name = url.lastPathComponent
        let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
        return isDirectory && name.count == 64 && name.allSatisfy(\.isHexDigit)
    }
}
