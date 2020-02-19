//
//  API.Music.swift
//  DemoMVVMCombine
//
//  Created by Le Phuong Tien on 2/19/20.
//  Copyright © 2020 Fx Studio. All rights reserved.
//

import Foundation
import Combine

extension API.Music {

  //MARK: - Endpoint
  enum EndPoint {
    //case
    case newMusisc(limit: Int)
    
    var url: URL? {
      switch self {
      case .newMusisc(let limit):
        let urlString = API.Config.baseURL + "api/v1/us/apple-music/coming-soon/all/\(limit)/explicit.json"
        return URL(string: urlString)
      }
    }
  }
  
  struct MusicResponse: Codable {
    var feed: MusicResults
    
    struct MusicResults: Codable {
      var results: [Music]
      var updated: String
    }
  }
  
  //MARK: - Domains
  static func getNewMusic(limit: Int = 10) -> AnyPublisher<MusicResponse, API.APIError> {
    guard let url = EndPoint.newMusisc(limit: limit).url else {
      return Fail(error: API.APIError.errorURL).eraseToAnyPublisher()
    }
    
    return API.request(url: url)
      .decode(type: MusicResponse.self, decoder: JSONDecoder())
      .mapError { error -> API.APIError in
        switch error {
        case is URLError:
          return .errorURL
        case is DecodingError:
          return .errorParsing
        default:
          return error as? API.APIError ?? .unknown
        }
      }
      .eraseToAnyPublisher()
  }
  
}
