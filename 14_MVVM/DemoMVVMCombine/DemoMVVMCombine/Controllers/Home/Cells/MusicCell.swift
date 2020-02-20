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

  // publisher
  var downloadPublisher = PassthroughSubject<Void, Never>()
  
  //MARK: - Lifecycle
  override func awakeFromNib() {
    super.awakeFromNib()
  }
  
  func bindingToView() {
    
    self.nameLabel.text = viewModel?.music.name
    self.artistNameLabel.text = viewModel?.music.artistName
    
    if let image = viewModel?.music.thumbnailImage {
      self.thumbnailImageView.image = image
    } else {
      self.thumbnailImageView.image = nil
            
      // publisher
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
        self.downloadPublisher.send()
      })
      
    }
    
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }
  
}
