//
//  API.Downloader.swift
//  DemoMVVMCombine
//
//  Created by Le Phuong Tien on 2/20/20.
//  Copyright © 2020 Fx Studio. All rights reserved.
//

import Foundation
import Combine
import UIKit

extension API.Downloader {
  static func image(urlString: String) -> AnyPublisher<UIImage?, API.APIError> {
    guard let url = URL(string: urlString) else {
      return Fail(error: API.APIError.errorURL).eraseToAnyPublisher()
    }
    
    return API.request(url: url)
    .map { UIImage(data: $0) }
    .mapError { $0 as? API.APIError ?? .unknown }
    .eraseToAnyPublisher()
  }
}
