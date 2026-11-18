import PlayerCore
import Testing

struct PlaybackTimeTests {
    @Test(arguments: [
        (0.0, "0:00"),
        (0.9, "0:00"),
        (59.9, "0:59"),
        (60, "1:00"),
        (3599, "59:59"),
        (3600, "60:00"),
        (-5, "0:00"),
    ])
    func showsWholeMinutesAndSeconds(seconds: Double, expected: String) {
        #expect(PlaybackTime.format(seconds) == expected)
    }

    @Test func showsZeroForNonFiniteValues() {
        #expect(PlaybackTime.format(.nan) == "0:00")
        #expect(PlaybackTime.format(.infinity) == "0:00")
        #expect(PlaybackTime.format(-.infinity) == "0:00")
    }
}
