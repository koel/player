import Shared
import Testing

struct SharedInteropTests {
    @Test func callsKotlinFromSwift() {
        #expect(DurationFormatKt.formatMs(seconds: 252.73) == "04:12")
        #expect(DurationFormatKt.formatHms(seconds: 3601.9) == "01:00:01")
    }
}
