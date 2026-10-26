package phanan.koel.shared.models

data class CurvePoint(val x: Double, val y: Double)

/** One cubic Bézier piece of the curve, from the previous segment's end. */
data class CurveSegment(val control1: CurvePoint, val control2: CurvePoint, val end: CurvePoint)

/** The line Koel web draws through the band handles: smooth, and running on a little past the outer bands. */
data class EqualizerCurve(val start: CurvePoint, val segments: List<CurveSegment>) {
    companion object {
        /** How far the curve runs past the first and last band before fading out. */
        const val OVERHANG = 15.0

        /** A Catmull-Rom spline through [handles], left to right, as cubic Béziers. Null with fewer than two handles. */
        fun through(handles: List<CurvePoint>): EqualizerCurve? {
            if (handles.size < 2) return null

            val first = handles.first()
            val second = handles[1]
            val secondLast = handles[handles.size - 2]
            val last = handles.last()
            val points = listOf(
                CurvePoint(first.x - OVERHANG, first.y + (first.y - second.y) / (second.x - first.x) * OVERHANG),
            ) + handles + CurvePoint(last.x + OVERHANG, last.y + (last.y - secondLast.y) / (last.x - secondLast.x) * OVERHANG)

            val segments = (0 until points.lastIndex).map { i ->
                val before = points[maxOf(i - 1, 0)]
                val from = points[i]
                val to = points[i + 1]
                val after = points[minOf(i + 2, points.lastIndex)]
                CurveSegment(
                    control1 = CurvePoint(from.x + (to.x - before.x) / 6, from.y + (to.y - before.y) / 6),
                    control2 = CurvePoint(to.x - (after.x - from.x) / 6, to.y - (after.y - from.y) / 6),
                    end = to,
                )
            }
            return EqualizerCurve(points.first(), segments)
        }
    }
}
