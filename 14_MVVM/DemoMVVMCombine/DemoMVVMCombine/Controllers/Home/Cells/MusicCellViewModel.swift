//
//  MusicCellViewModel.swift
//  DemoMVVMCombine
//
//  Created by Le Phuong Tien on 2/19/20.
//  Copyright © 2020 Fx Studio. All rights reserved.
//

import Foundation
import Combine

final class MusicCellViewModel {
  @Published var music: Music
  
  init(music: Music) {
    self.music = music
  }
}
