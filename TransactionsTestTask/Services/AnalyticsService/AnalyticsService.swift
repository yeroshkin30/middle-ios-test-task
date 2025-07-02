//
//  AnalyticsService.swift
//  TransactionsTestTask
//
//

import Foundation
import os

/// Analytics Service is used for events logging
/// The list of reasonable events is up to you
/// It should be possible not only to track events but to get it from the service
/// The minimal needed filters are: event name and date range
/// The service should be covered by unit tests
protocol AnalyticsServiceProtocol: Sendable, AnyObject {

    func trackEvent(name: String, parameters: [String: String])
    func getAllEvents() -> [AnalyticsEvent]
}

final class AnalyticsService: @unchecked Sendable {

    private var events: [AnalyticsEvent] = []
    private let queue = DispatchQueue(label: "AnalyticsServiceQueue")
    private var logger: Logger?

    // MARK: - Init
    
    init() {
        self.logger = Logger(subsystem: "TransactionsTestTask", category: "AnalyticsService")
    }
}

extension AnalyticsService: AnalyticsServiceProtocol {
    
    func trackEvent(name: String, parameters: [String: String] = [:]) {
        let event = AnalyticsEvent(
            name: name,
            parameters: parameters,
            date: .now
        )

        queue.async {
            self.events.append(event)
            self.logger?.info("Tracked event: \(event.name) with parameters: \(event.parameters)")
        }
    }

    func getAllEvents() -> [AnalyticsEvent] {
        queue.sync {
            events
        }
    }
}

/// Assuming that the AnalyticsService would be in separate module, we create this
/// structure to represent the event data in current module.
struct AnalyticEventData: Sendable {
    let name: String
    let parameters: [String: String]
}
