//
//  Network.swift
//  FetchingData
//
//  Created by Lam Le V. on 2/13/20.
//  Copyright © 2020 Lam Le V. All rights reserved.
//

import Foundation
import Combine

typealias NetworkPublisher<T> = AnyPublisher<T, Network<T>.Error>

final class Network<T> {

    enum Error: Swift.Error {
        case jsonFailure
        case invalidResponse
        case unknown

        var localizedDescription: String {
            switch self {
            case .jsonFailure:
                return "JSON Failure"
            case .invalidResponse:
                return "Invalid response"
            case .unknown:
                return "Unknown"
            }
        }
    }

    private let target: Target

    init(target: Target) {
        self.target = target
    }
}

extension Network where T: Codable {

    func request() -> NetworkPublisher<T> {
        var request = URLRequest(url: URL(string: target.path)!)
        request.timeoutInterval = 60 // Set time out
        request.allHTTPHeaderFields = target.headers
        request.httpMethod = target.method.rawValue
        if target.method == .post {
            request.httpBody = target.parameter?.data()
        }

        return URLSession.shared.dataTaskPublisher(for: request).tryMap { (data, response) -> Data in
            // Handle api error
            guard let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200 else {
                    throw Error.invalidResponse
            }
            return data
        }
        .decode(type: T.self, decoder: JSONDecoder())
        .mapError({ error -> Network.Error in
            if let error = error as? Network.Error {
                return error
            }
            return .unknown
        })
        .eraseToAnyPublisher()
    }
}
