//
//  NetworkRequest.swift
//  TransactionsTestTask
//
//  Created by Oleh Yeroshkin on 29.06.2025.
//

import Foundation

struct NetworkRequest<Response: Decodable> {
    typealias ResponseHandler = (Data, URLResponse) async throws -> Response

    let urlRequest: URLRequest
    let handler: ResponseHandler

    init(
        _ urlRequest: URLRequest,
        handler: @escaping ResponseHandler
    ) {
        self.urlRequest = urlRequest
        self.handler = handler
    }

    init(decodableRequest urlRequest: URLRequest, decoder: JSONDecoder = .init()) {
        self.init(urlRequest) { data, urlResponse in
            guard let httpResponse = urlResponse as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw NetworkError.invalidRespose
            }

            return try decoder.decode(Response.self, from: data)
        }
    }

    static func bitcoinRateRequest() throws -> NetworkRequest<BitcoinResponse> {
        guard let url = URL(string: "https://rest.coincap.io/v3/assets/bitcoin") else {
            throw NSError(
                domain: "NetworkRequestError",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL for Bitcoin rate request"]
            )
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        return NetworkRequest<BitcoinResponse>(decodableRequest: request)
    }
}
