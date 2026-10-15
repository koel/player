import ImageIO
import UIKit

/// Loads remote artwork with a memory cache (for smooth scrolling) on top of URLCache (for disk).
actor ImagePipeline {
    static let shared = ImagePipeline()

    // NSCache is thread-safe, which lets views read it synchronously while laying out.
    private nonisolated(unsafe) let memory = NSCache<NSString, UIImage>()
    private var inFlight: [String: Task<UIImage?, Never>] = [:]
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(memoryCapacity: 16 << 20, diskCapacity: 512 << 20)
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: configuration)
        memory.totalCostLimit = 96 << 20
    }

    nonisolated func cached(_ url: URL, pointSize: CGFloat) -> UIImage? {
        memory.object(forKey: Self.key(url, pointSize))
    }

    func image(for url: URL, pointSize: CGFloat) async -> UIImage? {
        let key = Self.key(url, pointSize) as String
        if let image = memory.object(forKey: key as NSString) { return image }
        if let task = inFlight[key] { return await task.value }

        let task = Task<UIImage?, Never> { [session] in
            guard let (data, _) = try? await session.data(from: url) else { return nil }
            return Self.downsample(data, pointSize: pointSize)
        }
        inFlight[key] = task
        let image = await task.value
        inFlight[key] = nil

        if let image {
            memory.setObject(image, forKey: key as NSString, cost: image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0)
        }
        return image
    }

    private static func key(_ url: URL, _ pointSize: CGFloat) -> NSString {
        "\(url.absoluteString)@\(Int(pointSize))" as NSString
    }

    private static func downsample(_ data: Data, pointSize: CGFloat) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let maxPixels = pointSize * 3
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixels,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: image)
    }
}
