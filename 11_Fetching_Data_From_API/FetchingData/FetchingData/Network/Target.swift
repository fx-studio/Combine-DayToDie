//
//  Target.swift
//  FetchingData
//
//  Created by Lam Le V. on 2/13/20.
//  Copyright © 2020 Lam Le V. All rights reserved.
//

import Foundation

public typealias Parameters = [String: Any]

enum HTTPMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}

protocol TargetType {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var parameter: Parameters? { get }
}

enum Target: TargetType {

    case developer

    var path: String {
        switch self {
        case .developer:
            return "http://developer.com"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .developer:
            return .get
        }
    }

    var headers: [String : String]? {
        switch self {
        case .developer:
            return nil
        }
    }

    var parameter: Parameters? {
        switch self {
        case .developer:
            return nil
        }
    }
}
