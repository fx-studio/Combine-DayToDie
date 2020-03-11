//
//  MusicsViewController.swift
//  HelloUIKit
//
//  Created by Le Phuong Tien on 3/11/20.
//  Copyright © 2020 Fx Studio. All rights reserved.
//

import UIKit
import Combine

class MusicsViewController: UIViewController {
  
  // Outlets
  @IBOutlet weak var tableView: UITableView!
  
  // Properties
  var musics: [Music] = [] {
    didSet {
      self.tableView.reloadData()
    }
  }
      
  private var subscriptions = Set<AnyCancellable>()
  
  private var api = APIMusic()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Title
    title = "Musics"
    
    // TableView
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.delegate = self
    tableView.dataSource = self
    
    // fetch
    // sink
//    api.comingSoon(limit: 100)
//      .receive(on: DispatchQueue.main)
//      .sink(receiveCompletion: { completion in
//        switch completion {
//        case .finished:
//            break
//        case .failure(let error):
//            fatalError(error.localizedDescription)
//        }
//      }) { apiResult in
//        self.musics = apiResult.feed.results
//      }.store(in: &subscriptions)
    
    // assign
    api.comingSoon(limit: 100)
      .receive(on: DispatchQueue.main)
      .map { $0.feed.results }
      .catch{ _ in Empty() }
      .assign(to: \.musics, on: self)
      .store(in: &subscriptions)
  }
  
}

// UITableView Delegate & DataSource
extension MusicsViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    musics.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    
    let item = musics[indexPath.row]
    cell.textLabel?.text = item.name
    
    return cell
  }
}
