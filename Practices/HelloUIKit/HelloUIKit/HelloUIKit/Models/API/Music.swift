//
//  Music.swift
//  HelloUIKit
//
//  Created by Le Phuong Tien on 3/11/20.
//  Copyright © 2020 Fx Studio. All rights reserved.
//

import Foundation

struct Music: Codable {
  var name: String
  var id: String
  var artistName: String
  var artworkUrl100: String
}

struct MusicResults: Codable {
  var results: [Music]
  var updated: String
}

struct FeedResults: Codable {
  var feed: MusicResults
}
