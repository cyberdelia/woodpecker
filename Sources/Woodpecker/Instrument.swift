import Atomics
import Darwin
import Dispatch

#if os(Linux)
    import let CDispatch.NSEC_PER_SEC
#endif

/**
 Instrument represents a generic instrument.
 */
protocol Instrument {}

/**
 Discrete represents an instrument returning a discrete Int64 value.
 */
protocol Discrete: Instrument {
    /**
     Returns the observed value for this time interval.
      
     - Important: Calling method will reset the instrument
     - returns: The observed value for this time interval
     */
    func snapshot() -> Int64
}

/**
 Sample represents an instruments returning a sample of values.
 */
protocol Sample: Instrument {
    /**
     Returns the observed values for this time interval.
     
     - Important: Calling this method will reset the instrument
     - returns: The observed values for this time interval
     */
    func snapshot() -> [Int64]
}

/**
 Counter holds a counter that can be incremented or decremented.
 */
class Counter: Discrete {
    var count = AtomicInt64()

    /**
     Returns an new Counter starting at the zero value.
     */
    init() {
        count.initialize(0)
    }

    /**
     Returns an new Counter starting at the given value.
     
     - parameters:
         - value: The starting value of the counter.
     */
    init(_ value: Int64) {
        count.initialize(value)
    }

    /**
     Increments the counter by one.
     */
    func increment() {
        count.increment()
    }

    /**
     Increments the counter by the given value.
     
     - parameters:
         - by: The value to which increment or decrement the counter.
     */
    func increment(_ by: Int64) {
        count.add(by)
    }

    func snapshot() -> Int64 {
        return count.swap(0)
    }
}

class Gauge: Discrete {
    var value = AtomicInt64()

    init(_ value: Int64 = 0) {
        self.value.initialize(value)
    }

    func record(_ value: Int64) {
        self.value.store(value)
    }

    func snapshot() -> Int64 {
        return value.load()
    }
}

let rateScale = Int64(NSEC_PER_SEC)

class Rate: Discrete {
    var time = AtomicUInt64()
    var count = Counter()
    var semaphore = DispatchSemaphore(value: 1)

    init() {
        time.initialize(DispatchTime.now().uptimeNanoseconds)
    }

    init(time: DispatchTime) {
        self.time.initialize(time.uptimeNanoseconds)
    }

    func record(_ value: Int64) {
        count.increment(value)
    }

    func snapshot() -> Int64 {
        semaphore.wait()
        defer { semaphore.signal() }
        let now = DispatchTime.now().uptimeNanoseconds
        let t = time.swap(now)
        let c = count.snapshot()
        return c / rateScale / Int64(now - t)
    }
}

class Derive: Discrete {
    var rate = Rate()
    var value = AtomicInt64()

    init(_ value: Int64) {
        self.rate = Rate()
        self.value.initialize(value)
    }

    init(value: Int64, time: DispatchTime) {
        self.rate = Rate(time: time)
        self.value.initialize(value)
    }

    func record(_ value: Int64) {
        let previous = self.value.swap(value)
        rate.record(value - previous)
    }

    func snapshot() -> Int64 {
        return rate.snapshot()
    }
}

let defaultReservoirSize: Int = 1024

class Reservoir: Sample {
    var semaphore = DispatchSemaphore(value: 1)
    var size = AtomicInt()
    var values: [Int64]

    init(_ length: Int = defaultReservoirSize) {
        size.initialize(0)
        values = Array(repeating: 0, count: length)
    }

    func record(_ value: Int64) {
        semaphore.wait()
        defer { semaphore.signal() }
        size.increment()
        let l = size.value
        if l <= values.count {
            // Reservoir is not full
            values[l-1] = value
        } else {
            // Reservoir is full
            let k = nextIndex(l)
            if k < values.count {
                values[Int(k)] = value
            }
        }
    }

    func snapshot() -> [Int64] {
        semaphore.wait()
        defer { semaphore.signal() }
        let l = size.swap(0)
        let v = values[0..<min(l, values.count)]
        return v.sorted()
    }

    private func nextIndex(_ upper: Int) -> Int {
        #if os(Linux)
            srandom(UInt32(time(nil)))
            return Int(random() % upper)
        #else
            return Int(arc4random_uniform(UInt32(upper)))
        #endif
    }
}

class Timing: Reservoir {
    func since(_ time: DispatchTime) {
        record(Int64(DispatchTime.now().uptimeNanoseconds - time.uptimeNanoseconds))
    }

    func time(_ closure: () -> Void) {
        let t = DispatchTime.now()
        closure()
        since(t)
    }
}
