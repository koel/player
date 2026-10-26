package phanan.koel.shared.models

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class EqualizerCurveTest {
    @Test
    fun passesThroughEveryHandle() {
        val handles = listOf(CurvePoint(0.0, 50.0), CurvePoint(20.0, 30.0), CurvePoint(40.0, 70.0))

        val curve = EqualizerCurve.through(handles)!!

        assertEquals(handles, curve.segments.map { it.end }.take(handles.size))
    }

    @Test
    fun runsOnPastTheOuterBandsAlongTheirSlope() {
        val curve = EqualizerCurve.through(listOf(CurvePoint(0.0, 50.0), CurvePoint(30.0, 20.0)))!!

        assertEquals(CurvePoint(-EqualizerCurve.OVERHANG, 65.0), curve.start)
        assertEquals(CurvePoint(30.0 + EqualizerCurve.OVERHANG, 5.0), curve.segments.last().end)
    }

    @Test
    fun aFlatSettingIsAStraightLine() {
        val curve = EqualizerCurve.through((0..9).map { CurvePoint(it * 10.0, 50.0) })!!

        curve.segments.forEach { segment ->
            assertEquals(50.0, segment.control1.y)
            assertEquals(50.0, segment.control2.y)
        }
    }

    @Test
    fun needsTwoHandles() {
        assertNull(EqualizerCurve.through(listOf(CurvePoint(0.0, 0.0))))
    }
}
