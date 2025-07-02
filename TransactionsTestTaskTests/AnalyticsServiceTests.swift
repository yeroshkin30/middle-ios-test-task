import Testing
import Foundation
@testable import TransactionsTestTask

@Suite("AnalyticsService Tests")
struct AnalyticsServiceTests {
    
    // MARK: - Basic Event Tracking Tests
    
    @Test("trackEvent adds event to storage")
    func trackEventTest() async throws {
        let service = AnalyticsService()
        let eventName = "test_event"
        let parameters = ["key1": "value1", "key2": "value2"]
        
        service.trackEvent(name: eventName, parameters: parameters)
        
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        let events = service.getAllEvents()
        #expect(events.count == 1)
        #expect(events.first?.name == eventName)
        #expect(events.first?.parameters == parameters)
    }
    
    @Test("trackEvent with empty parameters")
    func trackEventWithEmptyParametersTest() async throws {
        let service = AnalyticsService()
        
        service.trackEvent(name: "empty_params_event", parameters: [:])
        
        try await Task.sleep(nanoseconds: 50_000_000)
        
        let events = service.getAllEvents()
        #expect(events.count == 1)
        #expect(events.first?.name == "empty_params_event")
        #expect(events.first?.parameters.isEmpty == true)
    }
    
    @Test("trackEvent with default parameters")
    func trackEventWithDefaultParametersTest() async throws {
        let service = AnalyticsService()
        
        service.trackEvent(name: "default_params_event")
        
        try await Task.sleep(nanoseconds: 50_000_000)
        
        let events = service.getAllEvents()
        #expect(events.count == 1)
        #expect(events.first?.name == "default_params_event")
        #expect(events.first?.parameters.isEmpty == true)
    }
    
    // MARK: - Multiple Events Tests
    
    @Test("multiple events are tracked correctly")
    func multipleEventsTest() async throws {
        let service = AnalyticsService()
        
        service.trackEvent(name: "event1", parameters: ["param1": "value1"])
        service.trackEvent(name: "event2", parameters: ["param2": "value2"])
        service.trackEvent(name: "event3", parameters: ["param3": "value3"])
        
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        let events = service.getAllEvents()
        #expect(events.count == 3)
        
        let eventNames = events.map(\.name)
        #expect(eventNames.contains("event1"))
        #expect(eventNames.contains("event2"))
        #expect(eventNames.contains("event3"))
    }
    
    @Test("events maintain chronological order")
    func chronologicalOrderTest() async throws {
        let service = AnalyticsService()
        
        service.trackEvent(name: "first_event")
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        service.trackEvent(name: "second_event")
        try await Task.sleep(nanoseconds: 10_000_000)
        
        service.trackEvent(name: "third_event")
        try await Task.sleep(nanoseconds: 50_000_000)
        
        let events = service.getAllEvents()
        #expect(events.count == 3)
        #expect(events[0].name == "first_event")
        #expect(events[1].name == "second_event")
        #expect(events[2].name == "third_event")
        
        // Verify timestamps are in chronological order
        #expect(events[0].date <= events[1].date)
        #expect(events[1].date <= events[2].date)
    }

    // MARK: - Thread Safety Tests
    
    @Test("concurrent event tracking is thread-safe")
    func concurrentTrackingTest() async throws {
        let service = AnalyticsService()
        let eventCount = 100
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<eventCount {
                group.addTask {
                    service.trackEvent(name: "concurrent_event_\(i)", parameters: ["index": "\(i)"])
                }
            }
        }
        
        // Wait for all events to be processed
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        let events = service.getAllEvents()
        #expect(events.count == eventCount)
        
        // Verify all events were tracked
        for i in 0..<eventCount {
            let expectedName = "concurrent_event_\(i)"
            #expect(events.contains { $0.name == expectedName })
        }
    }
    
    @Test("concurrent reads are thread-safe")
    func concurrentReadsTest() async throws {
        let service = AnalyticsService()
        
        // Add some initial events
        for i in 0..<10 {
            service.trackEvent(name: "read_test_event_\(i)")
        }
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Perform concurrent reads
        let results = await withTaskGroup(of: [AnalyticsEvent].self, returning: [[AnalyticsEvent]].self) { group in
            for _ in 0..<20 {
                group.addTask {
                    service.getAllEvents()
                }
            }
            
            var allResults: [[AnalyticsEvent]] = []
            for await result in group {
                allResults.append(result)
            }
            return allResults
        }
        
        // All reads should return the same number of events
        let expectedCount = 10
        for result in results {
            #expect(result.count == expectedCount)
        }
    }

    // MARK: - Real-world Scenario Tests
    
    @Test("bitcoin rate tracking scenario")
    func bitcoinRateTrackingScenarioTest() async throws {
        let service = AnalyticsService()
        
        // Simulate bitcoin rate fetching events
        service.trackEvent(name: "BitcoinRateFetched", parameters: [
            "priceUsd": "42000.00",
            "changePercent24Hr": "2.5"
        ])
        
        service.trackEvent(name: "BitcoinRateFetched", parameters: [
            "priceUsd": "41800.00",
            "changePercent24Hr": "-0.5"
        ])
        
        service.trackEvent(name: "BitcoinRateError", parameters: [
            "error": "NetworkTimeout",
            "retryCount": "3"
        ])
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let events = service.getAllEvents()
        #expect(events.count == 3)
        
        let fetchEvents = events.filter { $0.name == "BitcoinRateFetched" }
        let errorEvents = events.filter { $0.name == "BitcoinRateError" }
        
        #expect(fetchEvents.count == 2)
        #expect(errorEvents.count == 1)
        #expect(fetchEvents[0].parameters["priceUsd"] == "42000.00")
        #expect(errorEvents[0].parameters["error"] == "NetworkTimeout")
    }
}
