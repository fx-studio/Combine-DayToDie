//
//  APIMusic.swift
//  HelloUIKit
//
//  Created by Le Phuong Tien on 3/11/20.
//  Copyright © 2020 Fx Studio. All rights reserved.
//

import Foundation
import Combine

struct APIMusic {
  
  //MARK: EndPoint
  enum EndPoint {
    static let baseURL = URL(string: "https://rss.itunes.apple.com/api/v1/us/apple-music")!
    
    case coming_soon(Int)
    
    var url: URL {
      switch self {
      case .coming_soon(let limit):
        return EndPoint.baseURL.appendingPathComponent("/coming-soon/all/\(limit)/aexplicit.json")
      }
    }
    
  }
  
  //MARK: Properties
  private let decoder = JSONDecoder()
  private let apiQueue = DispatchQueue(label: "API", qos: .default, attributes: .concurrent)
  
  //MARK: init
  init() { }
  
  //MARK: Public methods
  func comingSoon(limit: Int) -> AnyPublisher<FeedResults, APIError> {
    return URLSession.shared
      .dataTaskPublisher(for: EndPoint.coming_soon(limit).url)
      .subscribe(on: apiQueue)
      .tryMap { output in
          guard let response = output.response as? HTTPURLResponse, response.statusCode == 200 else {
            throw APIError.invalidResponse
          }
          return output.data
      }
      .decode(type: FeedResults.self, decoder: JSONDecoder())
      .mapError { error -> APIError in
            switch error {
            case is URLError:
              return .errorURL
            case is DecodingError:
              return .errorParsing
            default:
              return error as? APIError ?? .unknown
            }
          }
      .eraseToAnyPublisher()
  }
  
}
