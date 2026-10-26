import CoreImage
import SwiftUI
import UIKit

/// The main color of a cover, used to tint a collection screen like Apple Music does.
enum CoverColor {
    private static let context = CIContext(options: [.workingColorSpace: NSNull()])

    /// SwiftUI doesn't animate tints inside List rows, so the change is stepped frame by frame.
    static func fade(from start: Color?, to end: Color?, apply: (Color?) -> Void) async {
        let neutral = Color(uiColor: .systemGray)
        let steps = 30
        for step in 1...steps {
            let progress = Double(step) / Double(steps)
            let eased = progress < 0.5 ? 2 * progress * progress : 1 - pow(2 - 2 * progress, 2) / 2
            apply((start ?? neutral).mix(with: end ?? neutral, by: eased))
            try? await Task.sleep(for: .seconds(0.8 / Double(steps)))
            if Task.isCancelled { return }
        }
        apply(end)
    }

    static func of(_ url: String?) async -> Color? {
        guard let remote = url.flatMap(URL.init(string:)),
              let image = await ImagePipeline.shared.image(for: remote, pointSize: 40),
              let average = averageColor(of: image)
        else { return nil }
        return legibleTint(from: average).map(Color.init(uiColor:))
    }

    private static func averageColor(of image: UIImage) -> UIColor? {
        guard let input = CIImage(image: image),
              let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: input, kCIInputExtentKey: CIVector(cgRect: input.extent)]),
              let output = filter.outputImage
        else { return nil }

        var pixel = [UInt8](repeating: 0, count: 4)
        context.render(output, toBitmap: &pixel, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        return UIColor(red: CGFloat(pixel[0]) / 255, green: CGFloat(pixel[1]) / 255, blue: CGFloat(pixel[2]) / 255, alpha: 1)
    }

    /// Luminance where the tint reads both as text on black and as a fill behind white glyphs
    /// (roughly 4.5:1 against each).
    private static let targetLuminance: CGFloat = 0.18

    /// Nearly gray covers would only produce a gray tint; leave those neutral.
    private static let minimumSaturation: CGFloat = 0.15

    static func legibleTint(from color: UIColor) -> UIColor? {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        guard saturation >= minimumSaturation else { return nil }

        let boostedSaturation = min(max(saturation * 1.2, 0.45), 0.9)
        var lower: CGFloat = 0, upper: CGFloat = 1
        for _ in 0..<16 {
            let middle = (lower + upper) / 2
            if luminance(of: UIColor(hue: hue, saturation: boostedSaturation, brightness: middle, alpha: 1)) < targetLuminance {
                lower = middle
            } else {
                upper = middle
            }
        }
        return UIColor(hue: hue, saturation: boostedSaturation, brightness: lower, alpha: 1)
    }

    static func luminance(of color: UIColor) -> CGFloat {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        func linear(_ channel: CGFloat) -> CGFloat {
            channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }
}

/// A wash of the cover color fading into the dark background from the top.
struct CoverBackground: View {
    let color: Color?

    var body: some View {
        LinearGradient(
            colors: [(color ?? .clear).opacity(0.45), .clear],
            startPoint: .top,
            endPoint: .center
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.4), value: color)
    }
}
