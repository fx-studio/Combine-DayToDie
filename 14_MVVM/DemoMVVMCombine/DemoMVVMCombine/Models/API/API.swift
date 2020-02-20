//
//  API.swift
//  DemoMVVMCombine
//
//  Created by Le Phuong Tien on 2/19/20.
//  Copyright © 2020 Fx Studio. All rights reserved.
//

import Foundation
import Combine

struct API {
  
  //MARK: - Error
  enum APIError: Error {
    case error(String)
    case errorURL
    case invalidResponse
    case errorParsing
    case unknown
    
    var localizedDescription: String {
      switch self {
      case .error(let string):
        return string
      case .errorURL:
        return "URL String is error."
      case .invalidResponse:
        return "Invalid response"
      case .errorParsing:
        return "Failed parsing response from server"
      case .unknown:
        return "An unknown error occurred"
      }
    }
  }
  
  //MARK: - Config
  struct Config {
    static let baseURL = "https://rss.itunes.apple.com/"
  }
  
  //MARK: - Logic API
  struct Downloader { }
  
  //MARK: - Business API
  struct Music { }
}
