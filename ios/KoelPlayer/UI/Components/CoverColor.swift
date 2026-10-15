import CoreImage
import SwiftUI
import UIKit

/// The main color of a cover, used to tint a collection screen like Apple Music does.
enum CoverColor {
    private static let context = CIContext(options: [.workingColorSpace: NSNull()])

    static func of(_ url: String?) async -> Color? {
        guard let remote = url.flatMap(URL.init(string:)),
              let image = await ImagePipeline.shared.image(for: remote, pointSize: 40),
              let average = averageColor(of: image)
        else { return nil }
        return Color(uiColor: readable(average))
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

    /// Averages of real covers come out muddy and dark; lift them so text and icons stay legible on black.
    private static func readable(_ color: UIColor) -> UIColor {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return UIColor(hue: hue, saturation: min(saturation * 1.3, 0.85), brightness: max(brightness, 0.7), alpha: 1)
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
