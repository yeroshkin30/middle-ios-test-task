import Testing
import Foundation
@testable import TransactionsTestTask

@Suite("BitcoinRateService Tests")
struct BitcoinRateServiceTests {

    // MARK: - Test Data

    static let mockBitcoinData = BitcoinData(
        id: "bitcoin",
        rank: "1",
        symbol: "BTC",
        name: "Bitcoin",
        supply: "19000000.0000000000000000",
        maxSupply: "21000000.0000000000000000",
        marketCapUsd: "800000000000.0000000000000000",
        volumeUsd24Hr: "20000000000.0000000000000000",
        priceUsd: "42000.0000000000000000",
        changePercent24Hr: "2.5000000000000000",
        vwap24Hr: "41500.0000000000000000",
        explorer: "https://blockchain.info/"
    )

    /// Mock actor to simulate data management and analytics tracking.
    actor BitcoinDataManager {
        private var savedData: BitcoinData?
        private var trackedEvents: [AnalyticEventData] = []

        func updateSavedData(_ data: BitcoinData) {
            savedData = data
        }

        func getSavedData() -> BitcoinData? {
            savedData
        }

        func trackEvent(_ event: AnalyticEventData) {
            trackedEvents.append(event)
        }

        func getTrackedEvents() -> [AnalyticEventData] {
            trackedEvents
        }
    }

    actor Counter {
        private var count: Int = 0

        func increment() {
            count += 1
        }

        func getCount() -> Int {
            count
        }
    }

    // MARK: - Dependency Creation Helpers
    
    private func createMockDependencies(
        fetchResult: Result<BitcoinData, Error> = .success(mockBitcoinData),
        cachedData: BitcoinData? = nil,
        shouldTrackEvent: Bool = true,
        shouldSaveData: Bool = true
    ) -> BitcoinRateService.Dependency {
        let manager = BitcoinDataManager()
        
        return BitcoinRateService.Dependency(
            fetchBitcoinRate: {
                switch fetchResult {
                case .success(let data):
                    return data
                case .failure(let error):
                    throw error
                }
            },
            trackEvent: { event in
                if shouldTrackEvent {
                    Task {
                        await manager.trackEvent(event)
                    }
                }
            },
            saveBitcoinData: { data in
                if shouldSaveData {
                    await manager.updateSavedData(data)
                }
            },
            loadCachedBitcoinData: {
                return cachedData
            }
        )
    }
    
    // MARK: - Stream Tests
    
    @Test("getBitcoinDataStream returns cached data immediately")
    func streamWithCachedDataTest() async throws {
        let cachedData = Self.mockBitcoinData
        let dependencies = createMockDependencies(cachedData: cachedData)
        let service = BitcoinRateService(dependency: dependencies)
        
        let stream = await service.getBitcoinDataStream()
        var iterator = stream.makeAsyncIterator()
        
        let firstValue = try await iterator.next()
        #expect(firstValue?.id == cachedData.id)
        #expect(firstValue?.priceUsd == cachedData.priceUsd)
    }
    
    @Test("getBitcoinDataStream handles no cached data")
    func streamWithoutCachedDataTest() async throws {
        let dependencies = createMockDependencies(cachedData: nil)
        let service = BitcoinRateService(dependency: dependencies)
        
        let stream = await service.getBitcoinDataStream()
        var iterator = stream.makeAsyncIterator()
        
        // Should not immediately yield any value when no cached data
        let task = Task {
            try await iterator.next()
        }
        
        // Give it a brief moment to potentially yield cached data
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        if !task.isCancelled {
            task.cancel()
        }
    }
    
    @Test("Multiple subscribers can receive data")
    func multipleSubscribersTest() async throws {
        let dependencies = createMockDependencies(cachedData: Self.mockBitcoinData)
        let service = BitcoinRateService(dependency: dependencies)
        
        let stream1 = await service.getBitcoinDataStream()
        let stream2 = await service.getBitcoinDataStream()
        
        var iterator1 = stream1.makeAsyncIterator()
        var iterator2 = stream2.makeAsyncIterator()
        
        let value1 = try await iterator1.next()
        let value2 = try await iterator2.next()
        
        #expect(value1?.id == Self.mockBitcoinData.id)
        #expect(value2?.id == Self.mockBitcoinData.id)
        #expect(value1?.priceUsd == value2?.priceUsd)
    }
    
    // MARK: - Fetching Tests
    
    @Test("startFetching begins periodic updates")
    func startFetchingTest() async throws {
        let dependencies = createMockDependencies()
        let service = BitcoinRateService(dependency: dependencies)
        
        await service.startFetching(updateInterval: 0.1)

        try await Task.sleep(for: .seconds(0.5))

        await service.stopFetching()
    }
    
    @Test("stopFetching cancels updates")
    func stopFetchingTest() async throws {
        let counter = Counter()
        let dependencies = BitcoinRateService.Dependency(
            fetchBitcoinRate: {
                await counter.increment()
                return Self.mockBitcoinData
            },
            trackEvent: { _ in },
            saveBitcoinData: { _ in },
            loadCachedBitcoinData: { nil }
        )
        let service = BitcoinRateService(dependency: dependencies)
        
        await service.startFetching(updateInterval: 0.1)
        
        // Allow one fetch to occur
        try await Task.sleep(for: .seconds(0.15))
        let fetchCountAfterStart = await counter.getCount()

        await service.stopFetching()
        
        // Wait to ensure no more fetches occur after stopping
        try await Task.sleep(for: .seconds(0.2))
        let fetchCountAfterStop = await counter.getCount()

        #expect(fetchCountAfterStart > 0, "Fetching should have started")
        #expect(fetchCountAfterStop == fetchCountAfterStart, "No additional fetches should occur after stopping")
    }
    
    @Test("startFetching prevents multiple concurrent tasks")
    func preventMultipleFetchingTasksTest() async throws {
        let dependencies = createMockDependencies()
        let service = BitcoinRateService(dependency: dependencies)
        
        await service.startFetching(updateInterval: 1.0)
        await service.startFetching(updateInterval: 0.5)

        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        await service.stopFetching()
    }
    
    // MARK: - Error Handling Tests
    
    @Test("fetchBitcoinRate handles network errors with cached fallback")
    func networkErrorWithCacheTest() async throws {
        enum TestError: Error {
            case networkFailure
        }
        
        let cachedData = Self.mockBitcoinData
        let dependencies = createMockDependencies(
            fetchResult: .failure(TestError.networkFailure),
            cachedData: cachedData
        )
        let service = BitcoinRateService(dependency: dependencies)
        
        let stream = await service.getBitcoinDataStream()
        var iterator = stream.makeAsyncIterator()
        
        // Should receive cached data even when network fails
        let receivedData = try await iterator.next()
        #expect(receivedData?.id == cachedData.id)
    }
    
    @Test("fetchBitcoinRate handles network errors without cache")
    func networkErrorWithoutCacheTest() async throws {
        enum TestError: Error {
            case networkFailure
        }
        
        let dependencies = createMockDependencies(
            fetchResult: .failure(TestError.networkFailure),
            cachedData: nil
        )
        let service = BitcoinRateService(dependency: dependencies)
        
        let stream = await service.getBitcoinDataStream()
        var iterator = stream.makeAsyncIterator()
        await service.startFetching()

        do {
            _ = try await iterator.next()
            #expect(Bool(false), "Should throw error when no cache available")
        } catch {
            #expect(error is TestError)
        }
    }
    
    // MARK: - Data Persistence Tests
    
    @Test("Successful fetch triggers data saving")
    func dataSavingTest() async throws {
        let manager = BitcoinDataManager()

        let dependencies = BitcoinRateService.Dependency(
            fetchBitcoinRate: { Self.mockBitcoinData },
            trackEvent: { _ in },
            saveBitcoinData: { data in
                Task {
                    await manager.updateSavedData(data)
                }
            },
            loadCachedBitcoinData: { nil }
        )
        
        let service = BitcoinRateService(dependency: dependencies)
        await service.startFetching(updateInterval: 0.5)

        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        await service.stopFetching()
        
        #expect(await manager.getSavedData()?.id == Self.mockBitcoinData.id)
    }
    
    // MARK: - Analytics Tests
    
    @Test("Successful fetch triggers analytics event")
    func analyticsTrackingTest() async throws {
        let manager = BitcoinDataManager()

        let dependencies = BitcoinRateService.Dependency(
            fetchBitcoinRate: { Self.mockBitcoinData },
            trackEvent: { event in
                Task {
                    await manager.trackEvent(event)
                }
            },
            saveBitcoinData: { _ in },
            loadCachedBitcoinData: { nil }
        )
        
        let service = BitcoinRateService(dependency: dependencies)
        await service.startFetching(updateInterval: 0.1)
        
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        await service.stopFetching()
        
        #expect(await manager.getTrackedEvents().isEmpty == false)
        #expect(await manager.getTrackedEvents().first?.name == "BitcoinRateFetched")
    }
    
    // MARK: - Integration Tests

    @Test("Complete flow: fetch, cache, stream, analytics")
    func integrationTest() async throws {
        let manager = BitcoinDataManager()

        let dependencies = BitcoinRateService.Dependency(
            fetchBitcoinRate: { Self.mockBitcoinData },
            trackEvent: { event in
                Task {
                    await manager.trackEvent(event)
                }
            },
            saveBitcoinData: { data in
                await manager.updateSavedData(data)
            },
            loadCachedBitcoinData: {
                await manager.getSavedData()
            }
        )
        
        let service = BitcoinRateService(dependency: dependencies)
        
        let stream = await service.getBitcoinDataStream()
        var iterator = stream.makeAsyncIterator()
        
        await service.startFetching(updateInterval: 0.5)

        let receivedData = try await iterator.next()
        await service.stopFetching()
        
        // Verify all components worked
        #expect(receivedData?.id == Self.mockBitcoinData.id)
        #expect(await manager.getSavedData()?.id == Self.mockBitcoinData.id)
        #expect(await manager.getTrackedEvents().isEmpty == false)
    }
    
    @Test("Stream persists after stopFetching and receives values after restart")
    func streamPersistsAfterStopAndRestartTest() async throws {
        let counter = Counter()
        let dependencies = BitcoinRateService.Dependency(
            fetchBitcoinRate: {
                await counter.increment()
                return Self.mockBitcoinData
            },
            trackEvent: { _ in },
            saveBitcoinData: { _ in },
            loadCachedBitcoinData: { nil }
        )
        let service = BitcoinRateService(dependency: dependencies)
        
        // Create stream before starting fetching
        let stream = await service.getBitcoinDataStream()
        var iterator = stream.makeAsyncIterator()
        
        // Start fetching
        await service.startFetching(updateInterval: 0.1)
        
        // Wait for first value
        let firstValue = try await iterator.next()
        #expect(firstValue?.id == Self.mockBitcoinData.id)
        
        // Stop fetching
        await service.stopFetching()
        
        // Wait to ensure no more fetches occur
        try await Task.sleep(for: .seconds(0.2))
        
        // Stream should still be active (not terminated)
        // Restart fetching
        await service.startFetching(updateInterval: 0.1)
        
        // Stream should receive new values after restart
        let secondValue = try await iterator.next()
        #expect(secondValue?.id == Self.mockBitcoinData.id)
        
        await service.stopFetching()
        
        // Verify that fetching actually happened multiple times
        #expect(await counter.getCount() > 1, "Fetching should have occurred multiple times")
    }
    
    // MARK: - Concurrent Access Tests
    
    @Test("Service handles concurrent stream access safely")
    func concurrentStreamAccessTest() async throws {
        let dependencies = createMockDependencies(cachedData: Self.mockBitcoinData)
        let service = BitcoinRateService(dependency: dependencies)
        
        // Create multiple concurrent streams
        let tasks = (0..<5).map { _ in
            Task {
                let stream = await service.getBitcoinDataStream()
                var iterator = stream.makeAsyncIterator()
                return try await iterator.next()
            }
        }
        
        let results = try await withThrowingTaskGroup(of: BitcoinData?.self) { group in
            for task in tasks {
                group.addTask { try await task.value }
            }
            
            var results: [BitcoinData?] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
        
        // All results should be the same data
        for result in results {
            #expect(result?.id == Self.mockBitcoinData.id)
        }	
    }
}
