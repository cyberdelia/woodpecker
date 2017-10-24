import XCTest
import Dispatch

#if os(Linux)
    import let CDispatch.NSEC_PER_MSEC
#endif

@testable import Woodpecker

class InstrumentTests: XCTestCase {
    public static var allTests = [
        ("testCounter", testCounter),
        ("testCounter", testCounter),
        ("testRate", testRate),
        ("testDerive", testDerive),
        ("testSingleReservoir", testSingleReservoir),
        ("testFullReservoir", testFullReservoir),
        ("testReservoirOverflow", testReservoirOverflow),
        ("testTiming", testTiming)
    ]

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testCounter() {
        let counter = Counter()
        for i in 1...10 {
            counter.increment(Int64(i))
        }
        XCTAssertEqual(55, counter.snapshot())
        XCTAssertEqual(0, counter.snapshot())
    }

    func testGauge() {
        let gauge = Gauge(1)
        gauge.record(2)
        XCTAssertEqual(2, gauge.snapshot())
    }

    func testRate() {
        let rate = Rate()
        let n = 10000
        let t0 = DispatchTime.now()
        let t = Int64((n * (n + 1)) / 2)
        for i in 0..<n {
            rate.record(Int64(i))
        }
        expectedRate(total: t, rate: rate)
        Thread.sleep(forTimeInterval: 0.100)
        expectedRate(total: t, rate: rate)
        let snapshot = rate.snapshot()
        let t1 = DispatchTime.now()
        let m = t / Int64(t1.uptimeNanoseconds - t0.uptimeNanoseconds) * rateScale
        XCTAssertEqual(rate.snapshot(), 0)
        XCTAssertEqual(Double(snapshot), Double(m), accuracy: Double(m)/1000)
    }

    func calculateRate(count: Int64, time: UInt64) -> Int64 {
        let now = DispatchTime.now().uptimeNanoseconds
        return count / rateScale / Int64(now - time)
    }

    func expectedRate(total: Int64, rate: Rate) {
        let e = calculateRate(count: total, time: rate.time.value)
        let v = calculateRate(count: rate.count.count.value, time: rate.time.value)
        XCTAssertEqual(Double(e), Double(v), accuracy: Double(e)/20)
    }

    func testDerive() {
        let derive = Derive(10)
        Thread.sleep(forTimeInterval: 0.05)
        derive.record(15)
        XCTAssertEqual(derive.value.value, 15)
    }

    func testSingleReservoir() {
        let reservoir = Reservoir(3)
        reservoir.record(1)
        let snapshot = reservoir.snapshot()
        XCTAssertEqual([1], snapshot)
    }

    func testFullReservoir() {
        let reservoir = Reservoir(3)
        reservoir.record(1)
        reservoir.record(-10)
        reservoir.record(23)
        let snapshot = reservoir.snapshot()
        XCTAssertEqual([-10, 1, 23], snapshot)
    }

    func testReservoirOverflow() {
        let reservoir = Reservoir(3)
        reservoir.record(1)
        reservoir.record(-10)
        reservoir.record(23)
        reservoir.record(18)
        let snapshot = reservoir.snapshot()
        XCTAssertEqual(3, snapshot.count)
    }

    func testTiming() {
        let timer = Timing()
        timer.time { Thread.sleep(forTimeInterval: 0.05) }
        let snapshot = timer.snapshot()[0]
        XCTAssertEqual(Double(snapshot), Double(50 * Int64(NSEC_PER_MSEC)), accuracy: 10.0 * Double(NSEC_PER_MSEC))
    }
}
