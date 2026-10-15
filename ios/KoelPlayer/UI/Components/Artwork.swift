import SwiftUI

/// Album covers, artist photos, podcast and station logos. Falls back to Koel's default image.
struct Artwork: View {
    let url: String?
    var size: CGFloat
    var cornerRadius: CGFloat = 8
    var isCircle = false

    @State private var image: UIImage?

    private var remoteUrl: URL? {
        url.flatMap(URL.init(string:))
    }

    var body: some View {
        Group {
            if let image = image ?? remoteUrl.flatMap({ ImagePipeline.shared.cached($0, pointSize: size) }) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image("default-image").resizable().scaledToFill()
            }
        }
        .frame(width: size, height: size)
        .clipShape(isCircle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)))
        .task(id: url) {
            guard let remoteUrl else { image = nil; return }
            image = await ImagePipeline.shared.image(for: remoteUrl, pointSize: size)
        }
        .accessibilityHidden(true)
    }
}
