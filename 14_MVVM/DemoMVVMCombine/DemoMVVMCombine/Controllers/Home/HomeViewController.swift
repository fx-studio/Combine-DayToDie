//
//  HomeViewController.swift
//  DemoMVVMCombine
//
//  Created by Le Phuong Tien on 2/18/20.
//  Copyright © 2020 Fx Studio. All rights reserved.
//

import UIKit
import Combine

class HomeViewController: BaseViewController {
  
  //MARK: - Properties
  // ViewModel
  var viewModel = HomeViewModel()
  
  // Outlets
  @IBOutlet weak var tableView: UITableView!
  
  //MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  //MARK: - Config View
  //MARK: Setup
  override func setupData() {
    super.setupData()
    
    //fetchData
    self.viewModel.action.send(.fetchData)
  }
  
  override func setupUI() {
    super.setupUI()
    
    title = "Home"
    
    //tableview
    tableView.delegate = self
    tableView.dataSource = self
    
    let musicCellNib = UINib(nibName: "MusicCell", bundle: .main)
    tableView.register(musicCellNib, forCellReuseIdentifier: "MusicCell")
    
    // Navigation Bar
    let clearBarButton = UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(reset))
    self.navigationItem.rightBarButtonItem = clearBarButton
  }
  
  //MARK: Binding
  override func bindingToView() {
    // musics
    viewModel.$musics
      .debounce(for: .seconds(0.1), scheduler: DispatchQueue.main)
      .sink(receiveValue: { _ in
        print("binding table : \(self.viewModel.numberOfRows(in: 1))")
        self.tableView.reloadData()
      })
      .store(in: &subscriptions)
    
  }
  
  override func bindingToViewModel() {
    
  }
  
  //MARK: Router
  override func router() {
    // viewmodel State
    viewModel.state
      .sink { [weak self] state in
        if case .error(let message) = state {
          // show alert
          _ = self?.alert(title: "HOME", text: message)
        }
        
      }
      .store(in: &subscriptions)
  }
  
  //MARK: - Private functions
  @objc func reset() {
    viewModel.action.send(.reset)
  }
  
}

//MARK: - UITableView Delegate
extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.numberOfRows(in: section)
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    80
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "MusicCell", for: indexPath) as! MusicCell
    
    let vm = viewModel.musicCellViewModel(at: indexPath)
    cell.viewModel = vm
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
  }
  
}
