import Darwin
import Dispatch

/**
 Registry is a registry of all instruments.
 */
class Registry {
    var semaphore = DispatchSemaphore(value: 1)
    var instruments: [String: Instrument] = [:]

    /**
     Register a new instrument using the given name.
     
     - parameters:
         - name: Name of the instrument
         - instrument: The instrument itself.
     */
    public func register(name: String, instrument: Instrument) {
        semaphore.wait()
        defer { semaphore.signal() }

        instruments[name] = instrument
    }

    /**
     Returns a snapshot of all instruments in the Registry.
     
     - returns: a dictionary of all the instruments and their name.
     */
    public func snapshot() -> [String: Instrument] {
        semaphore.wait()
        defer {
            instruments.removeAll()
            semaphore.signal()
        }
        return instruments
    }

    /**
     Returns the size of the registry.
     
     - returns: current size of the registry.
     */
    public func count() -> Int {
        return instruments.count
    }
}
