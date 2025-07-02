//
//  BitcoinRateViewModel.swift
//  TransactionsTestTask
//
//  Created by Oleh Yeroshkin on 02.07.2025.
//

import Foundation

@MainActor
final class BitcoinRateViewModel {
    struct Dependency {
        let startFetching: () async -> Void
        let stopFetching: () async -> Void
        let getBitcoinDataStream: () async -> AsyncThrowingStream<BitcoinData, Error>
    }

    enum FetchState {
        case bitcoinDataFetched(BitcoinData)
        case fetchingStateChanged(Bool)
    }

    var onEvent: ((FetchState) -> Void)?

    // MARK: - Private Properties

    private let dependency: Dependency
    private var isStreaming: Bool = false
    private var streamTask: Task<Void, Never>?

    // MARK: - Initializers

    init(dependency: Dependency) {
        self.dependency = dependency
    }

    // MARK: - Public Methods

    func startFetching() {
        if isStreaming == false {
            startObservation()
        }

        Task {
            await dependency.startFetching()
            onEvent?(.fetchingStateChanged(true))
        }
    }

    func stopFetching() {
        Task {
            await dependency.stopFetching()
            isStreaming = false
            streamTask?.cancel()
            onEvent?(.fetchingStateChanged(false))
        }
    }
}

// MARK: - Private Methods

private extension BitcoinRateViewModel {

    func startObservation() {
        streamTask = Task {
            let stream = await dependency.getBitcoinDataStream()
            isStreaming = true
            do {
                for try await bitcoinData in stream {
                    onEvent?(.bitcoinDataFetched(bitcoinData))
                }
            } catch {
                isStreaming = false
                onEvent?(.fetchingStateChanged(false))
            }
        }
    }
}
