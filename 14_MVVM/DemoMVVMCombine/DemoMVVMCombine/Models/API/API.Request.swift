//
//  API.Request.swift
//  DemoMVVMCombine
//
//  Created by Le Phuong Tien on 2/19/20.
//  Copyright © 2020 Fx Studio. All rights reserved.
//

import Foundation
import Combine

extension API {
  static func request(url: URL) -> AnyPublisher<Data, Error> {
    return URLSession.shared
    .dataTaskPublisher(for: url)
    .receive(on: DispatchQueue.main)
    .tryMap { data, response -> Data in
      guard let httpResponse = response as? HTTPURLResponse,
        httpResponse.statusCode == 200 else {
          throw API.APIError.invalidResponse
      }
      return data
    }.eraseToAnyPublisher()
  }
}
