//
//  Music.swift
//  DemoMVVMCombine
//
//  Created by Le Phuong Tien on 2/19/20.
//  Copyright © 2020 Fx Studio. All rights reserved.
//

import Foundation
import Combine
import UIKit

class Music: Decodable {
  var name: String
  var id: String
  var artistName: String
  var artworkUrl100: String
  
  var thumbnailImage: UIImage?
  
  private enum CodingKeys: String, CodingKey {
    case name
    case id
    case artistName
    case artworkUrl100
  }
  
  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    self.name = try container.decode(String.self, forKey: .name)
    self.id = try container.decode(String.self, forKey: .id)
    self.artworkUrl100 = try container.decode(String.self, forKey: .artworkUrl100)
    self.artistName = try container.decode(String.self, forKey: .artistName)
    
  }
  
}
