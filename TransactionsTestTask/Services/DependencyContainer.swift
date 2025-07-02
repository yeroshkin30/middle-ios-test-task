//
//  DependencyContainer.swift
//  TransactionsTestTask
//
//  Created by Oleh Yeroshkin on 02.07.2025.
//

import Foundation

actor DependencyContainer: Sendable {

    private let networkService: NetworkServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private let storageService: StorageServiceProtocol
    lazy var bitcoinRateService: BitcoinRateService = .init(dependency: createBitcoinServiceDependency())

    init(
        networkService: NetworkServiceProtocol = NetworkService(),
        analyticsService: AnalyticsServiceProtocol = AnalyticsService(),
        storageService: StorageServiceProtocol = StorageService()
    ) {
        self.networkService = networkService
        self.analyticsService = analyticsService
        self.storageService = storageService
    }

    private func createBitcoinServiceDependency() -> BitcoinRateService.Dependency {
        BitcoinRateService.Dependency(
            fetchBitcoinRate: {
                try await self.networkService.fetch(.bitcoinRateRequest()).data
            },
            trackEvent: { eventData in
                self.analyticsService.trackEvent(
                    name: eventData.name,
                    parameters: eventData.parameters
                )
            },
            saveBitcoinData: { bitcoinData in
                await self.storageService.saveBitcoinData(bitcoinData)
            },
            loadCachedBitcoinData: {
                await self.storageService.loadCachedBitcoinData()
            }
        )
    }
}
