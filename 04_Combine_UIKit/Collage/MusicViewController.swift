//
//  MusicViewController.swift
//  Collage
//
//  Created by Le Phuong Tien on 2/11/20.
//  Copyright © 2020 Razeware LLC. All rights reserved.
//

import UIKit
import Combine

class MusicViewController: UIViewController {
  
  // Outlets
  @IBOutlet weak var tableView: UITableView!
  
  // Properties
  var musics: [Music] = [] {
    didSet {
      self.tableView.reloadData()
    }
  }
  
  private let ituneURL = "https://rss.itunes.apple.com/api/v1/us/apple-music/coming-soon/all/100/aexplicit.json"
  private var subscriptions = Set<AnyCancellable>()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // register
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    
    // fetch api
//    fetchData()
//      .receive(on: DispatchQueue.main)
//      .catch{ _ in Empty() }
//      .assign(to: \.musics, on: self)
//      .store(in: &subscriptions)
    
    fetchData()
      .receive(on: DispatchQueue.main)
      .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
          print("❌ :  \(error.localizedDescription)")
        }
        }) { musics in
          self.musics = musics
        }
      .store(in: &subscriptions)
  }
  
  // Fetching Data
  func fetchData() -> AnyPublisher<[Music], Error> {
    let url = URL(string: ituneURL)!
    
    return URLSession.shared
      .dataTaskPublisher(for: url)
      .map(\.data)
      .decode(type: FeedResults.self, decoder: JSONDecoder())
      .mapError { $0 as Error }
      .map { $0.feed.results }
      .eraseToAnyPublisher()
  }
  
}

//MARK: Tablebiew delegate & datasource
extension MusicViewController: UITableViewDelegate, UITableViewDataSource {
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
