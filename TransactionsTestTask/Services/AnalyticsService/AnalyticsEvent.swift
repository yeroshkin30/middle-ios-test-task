//
//  AnalyticsEvent.swift
//  TransactionsTestTask
//
//

import Foundation

struct AnalyticsEvent {
    
    let name: String
    let parameters: [String: String]
    let date: Date
}

extension AnalyticsEvent {
    static let bitcoinRateFetched = AnalyticsEvent(
        name: "bitcoin_rate_fetched",
        parameters: [:],
        date: Date()
    )
}
