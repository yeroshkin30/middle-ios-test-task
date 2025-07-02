//
//  NetworkService.swift
//  TransactionsTestTask
//
//  Created by Oleh Yeroshkin on 29.06.2025.
//

import Foundation
import os

protocol NetworkServiceProtocol: Sendable, AnyObject {
    func fetch<Response: Decodable>(
        _ networkRequest: NetworkRequest<Response>
    ) async throws -> Response
}

final class NetworkService: Sendable, NetworkServiceProtocol {
    private let urlSession: URLSession
    private let logger: Logger?
    private let apiToken: String

    init() {
        self.apiToken = APIToken.value
        self.urlSession = URLSession.shared
        self.logger = Logger(subsystem: "TransactionsTestTask", category: "NetworkService")
    }

    func fetch<Response>(
        _ networkRequest: NetworkRequest<Response>
    ) async throws -> Response where Response: Decodable {
        var urlRequest = networkRequest.urlRequest

        // Add API key as query parameter
        if var components = URLComponents(url: urlRequest.url!, resolvingAgainstBaseURL: false) {
            components.queryItems = (components.queryItems ?? []) + [
                URLQueryItem(name: "apiKey", value: apiToken)
            ]
            urlRequest.url = components.url
        }
        logger?.info("Fetching data with request: \(urlRequest)")

        let (data, response) = try await urlSession.data(for: urlRequest)
        let object = try await networkRequest.handler(data, response)

        return object
    }
}

enum NetworkError: Error {
    case invalidRespose
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidRespose:
            return "Invalid response received from server"
        }
    }
}

// For testing purposes, we save it directly in the code.
struct APIToken {
    static let value = "d0bf258abe1c9280f1790c174d24911a29ecbb56e5639a5e9ada0d7f958dce69"
}
