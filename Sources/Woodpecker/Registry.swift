import Dispatch
import Foundation


// Registry is a registry of all instruments.
class Registry {
    var semaphore = DispatchSemaphore(value: 1)
    var instruments: [String: Instrument] = [:]

    public func register(name: String, instrument: Instrument) {
        semaphore.wait()
        defer { semaphore.signal() }

        instruments[name] = instrument
    }

    // Take a snapshot.
    public func snapshot() -> [String: Instrument] {
        semaphore.wait()
        defer {
            instruments.removeAll()
            semaphore.signal()
        }
        
        return instruments
    }

    // Returns the size of the registry.
    public func count() -> Int {
        return instruments.count
    }
}
