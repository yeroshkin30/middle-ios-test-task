//
//  BitcoinRateService.swift
//  TransactionsTestTask
//
//

import Foundation
import os

// This actor because we need to protect shared mutable state of `continuations` and `timerTask`.
actor BitcoinRateService {

    /// Object that contains dependencies for the BitcoinRateController.
    struct Dependency: Sendable {
        let fetchBitcoinRate: @Sendable () async throws -> BitcoinData
        let trackEvent: @Sendable (AnalyticEventData) -> Void
        let saveBitcoinData: @Sendable (BitcoinData) async -> Void
        let loadCachedBitcoinData: @Sendable () async -> BitcoinData?
    }

    // MARK: - Private Properties

    private let dependency: Dependency
    /// A set of continuations to manage multiple subscribers if any.
    private var continuations: Set<ContinuationBox> = []
    private var timerTask: Task<Void, Never>?
    private let logger = Logger(subsystem: "service", category: "bitcoinRateService")

    // MARK: - Initialization

    init(dependency: Dependency) {
        self.dependency = dependency
    }

    // MARK: - Public Methods

    /// Used to get a stream of Bitcoin data updates.
    func getBitcoinDataStream() -> AsyncThrowingStream<BitcoinData, Error> {
        defer { logger.info("Streams: \(self.continuations.count)") }
        return AsyncThrowingStream { continuation in
            let box = ContinuationBox(value: continuation)

            // Send initial cached data if available.
            // Could be a problem, since cached data can fire after real-time data.
            Task {
                if let cachedData = await self.dependency.loadCachedBitcoinData() {
                    self.logger.info("Initial cash data sended")
                    continuation.yield(cachedData)
                }
                self.continuations.insert(box)
            }

            continuation.onTermination = { _ in
                Task {
                    await self.removeContinuationBox(box)
                }
            }
        }
    }

    func startFetching(updateInterval: TimeInterval = 20) {
        guard timerTask == nil else {
            logger.warning("Bitcoin rate fetching is already in progress")
            return
        }

        logger.info("Starting to fetch Bitcoin rate every \(updateInterval) seconds")
        timerTask = Task {
            while !Task.isCancelled {
                do {
                    let bitcointData = try await self.fetchBitcoinRate()
                    for box in self.continuations {
                        box.value.yield(bitcointData)
                    }

                    // Wait for the specified interval before next fetch
                    try await Task.sleep(for: .seconds(updateInterval))
                } catch is CancellationError {
                    break
                } catch {
                    logger.error("Error fetching Bitcoin rate: \(error.localizedDescription)")
                    for box in self.continuations {
                        box.value.finish(throwing: error)
                    }
                    break
                }
            }
        }
    }

    func stopFetching() {
        timerTask?.cancel()
        timerTask = nil
        logger.info("Stop Bitcoin rate fetching")
    }
}

// MARK: - Private Methods

extension BitcoinRateService {

    private func fetchBitcoinRate() async throws -> BitcoinData {
        do {
            let bitcoinData = try await dependency.fetchBitcoinRate()
            logger.info("Fetched Bitcoin data: \(String(describing: bitcoinData.priceUsd))")
            dependency.trackEvent(
                AnalyticEventData(
                    name: "BitcoinRateFetched",
                    parameters: ["priceUsd": bitcoinData.priceUsd, "changePercent24Hr": bitcoinData.changePercent24Hr]
                )
            )
            await dependency.saveBitcoinData(bitcoinData)

            return bitcoinData
        } catch {
            if let bitcoinData = await dependency.loadCachedBitcoinData() {
                logger.info("Using cached Bitcoin data: \(String(describing: bitcoinData))")
                return bitcoinData
            } else {
                logger.error("Error fetching Bitcoin rate: \(error.localizedDescription)")
                throw error
            }
        }
    }

    private func removeContinuationBox(_ box: ContinuationBox) {
        continuations.remove(box)
        if continuations.isEmpty {
            stopFetching()
        }
    }
    /// A private class to wrap the continuation for hashability.
    private final class ContinuationBox: Hashable, Sendable {
        let value: AsyncThrowingStream<BitcoinData, Error>.Continuation

        init(value: AsyncThrowingStream<BitcoinData, Error>.Continuation) {
            self.value = value
        }

        static func == (lhs: BitcoinRateService.ContinuationBox, rhs: BitcoinRateService.ContinuationBox) -> Bool {
            lhs === rhs
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(ObjectIdentifier(self))
        }
    }
}

struct BitcoinResponse: Codable, Sendable {
    let data: BitcoinData
    let timestamp: Int
}

struct BitcoinData: Codable, Sendable {
    let id: String
    let rank: String
    let symbol: String
    let name: String
    let supply: String
    let maxSupply: String?
    let marketCapUsd: String
    let volumeUsd24Hr: String
    let priceUsd: String
    let changePercent24Hr: String
    let vwap24Hr: String
    let explorer: String?
}
