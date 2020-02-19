//
//  MusicCell.swift
//  DemoMVVMCombine
//
//  Created by Le Phuong Tien on 2/19/20.
//  Copyright © 2020 Fx Studio. All rights reserved.
//

import UIKit
import Combine

class MusicCell: UITableViewCell {
  
  //MARK: - Properties
  // Outlets
  @IBOutlet weak var thumbnailImageView: UIImageView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var artistNameLabel: UILabel!
  
  // ViewModel
  var viewModel: MusicCellViewModel? {
    didSet {
      self.bindingToView()
    }
  }
  
  var subscriptions = [AnyCancellable]()
    
  //MARK: - Lifecycle
  override func awakeFromNib() {
    super.awakeFromNib()
  }
  
  func bindingToView() {    
    subscriptions = []
    
    viewModel?.$music
      .sink { music in
        self.nameLabel.text = music.name
        self.artistNameLabel.text = music.artistName
    }
    .store(in: &subscriptions)
    
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }
  
}
