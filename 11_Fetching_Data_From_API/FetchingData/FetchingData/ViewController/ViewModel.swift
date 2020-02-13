//
//  ViewModel.swift
//  FetchingData
//
//  Created by Lam Le V. on 2/12/20.
//  Copyright © 2020 Lam Le V. All rights reserved.
//

import Foundation
import Combine

final class ViewModel {

    enum Error: Swift.Error {
        case jsonFailure
        case invalidResponse

        var localizedDescription: String {
            switch self {
            case .jsonFailure:
                return "JSON Failure"
            case .invalidResponse:
                return "Invalid response"
            }
        }
    }

    let fetchDevelopers = Network<[String: [Developer]]>(target: .developer)
        .request()
        .tryMap({ (value) -> [Developer] in
            guard let developers = value["developers"] else {
                throw Error.invalidResponse
            }
            return developers
        })
}

extension ViewModel {
    private struct Config {
        static let path = "https://developer.com"
    }
}

struct Developer: Codable {
    var name: String
    var id: Int
}
