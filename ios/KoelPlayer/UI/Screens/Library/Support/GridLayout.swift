import CoreGraphics

/// Sizes square cards so they fill the width in as many columns as fit, never fewer than two.
struct GridLayout {
    let containerWidth: CGFloat
    var minimumCardSize: CGFloat = 150
    var spacing: CGFloat = 16
    var rowSpacing: CGFloat = 20
    var padding: CGFloat = 16

    var columnCount: Int {
        let available = containerWidth - padding * 2 + spacing
        return max(2, Int(available / (minimumCardSize + spacing)))
    }

    var cardSize: CGFloat {
        let columns = CGFloat(columnCount)
        return max(0, (containerWidth - padding * 2 - spacing * (columns - 1)) / columns)
    }
}
