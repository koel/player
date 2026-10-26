import SwiftUI

/// Album covers, artist photos, podcast and station logos. Falls back to `fallbackSymbol` when there
/// is no image at all, otherwise to Koel's default image.
struct Artwork: View {
    let url: String?
    var size: CGFloat
    var cornerRadius: CGFloat = 8
    var isCircle = false
    var fallbackSymbol: String?

    private var shape: AnyShape {
        isCircle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    var body: some View {
        Group {
            if let fallbackSymbol, url.flatMap(URL.init(string:)) == nil {
                Image(systemName: fallbackSymbol)
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(.secondary)
                    .frame(width: size, height: size)
                    .background(.quaternary, in: shape)
            } else {
                ArtworkImage(url: url, pointSize: size)
                    .frame(width: size, height: size)
                    .clipShape(shape)
            }
        }
        .accessibilityHidden(true)
    }
}

/// The image behind `Artwork`, filling whatever frame it is given.
struct ArtworkImage: View {
    let url: String?
    let pointSize: CGFloat

    @State private var image: UIImage?

    private var remoteUrl: URL? {
        url.flatMap(URL.init(string:))
    }

    var body: some View {
        Group {
            if let image = image ?? remoteUrl.flatMap({ ImagePipeline.shared.cached($0, pointSize: pointSize) }) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image("default-image").resizable().scaledToFill()
            }
        }
        .task(id: url) {
            guard let remoteUrl else { image = nil; return }
            image = await ImagePipeline.shared.image(for: remoteUrl, pointSize: pointSize)
        }
    }
}
