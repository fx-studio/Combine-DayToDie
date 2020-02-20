//
//  HomeViewModel.swift
//  DemoMVVMCombine
//
//  Created by Le Phuong Tien on 2/19/20.
//  Copyright © 2020 Fx Studio. All rights reserved.
//

import Foundation
import Combine

final class HomeViewModel {
  
  //MARK: - Define
  // State
  enum State {
    case initial
    case fetched
    case error(message: String)
    case reloadCell(indexPath: IndexPath)
  }
  
  // Action
  enum Action {
    case fetchData
    case reset
    case downloadImage(indexPath: IndexPath)
  }
  
  //MARK: - Properties
  // Publisher & store
  @Published var musics: [Music] = []
  @Published var isLoading: Bool = false
  
  // Actions
  let action = PassthroughSubject<Action, Never>()
  
  // State
  let state = CurrentValueSubject<State, Never>(.initial)
  
  // Subscriptions
  var subscriptions = [AnyCancellable]()
  var musicsCancellable = [AnyCancellable]()
  
  //MARK: - Init
  init() {
    // state
    state
      .sink { [weak self] state in
        self?.processState(state)
    }.store(in: &subscriptions)
    
    // action
    action
      .sink { [weak self] action in
        self?.processAction(action)
    }.store(in: &subscriptions)
  }

  //MARK: - Private functions
  // process Action
  private func processAction(_ action: Action) {
    switch action {
    case .fetchData:
      print("ViewModel -> Action: FetchData")
      fetchData()
      
    case .reset:
      print("ViewModel -> Action: Reset")
      musics = []
      fetchData()
      
    case .downloadImage(let indexPath):
      print("ViewModel -> Action: Download at \(indexPath.row)")
      downloadImage(indexPath: indexPath)
    }
  }
    
  // process State
  private func processState(_ state: State) {
    switch state {
    case .initial:
      print("ViewModel -> State: initial")
      isLoading = false
      
    case .fetched:
      print("ViewModel -> State: fetched")
      isLoading = true
      
    case .error(let message):
      print("ViewModel -> State: error : \(message)")
      
    case .reloadCell(let indexPath):
      print("ViewModel -> State: reload cell : \(indexPath.row)")
      
    }
  }
  
  //MARK: - Actions
  func fetchData() {
    
    musicsCancellable = []
    
//    API.Music.getNewMusic(limit: 100)
//      .map(\.feed.results)
//      .replaceError(with: [])
//      .assign(to: \.musics, on: self)
//      .store(in: &musicsCancellable)
      
    
    API.Music.getNewMusic(limit: 100)
      .map(\.feed.results)
      .sink(receiveCompletion: { [weak self] completion in
        guard let self = self else { return }

        //state
        self.state.send(.fetched)
        //error
        if case .failure(let error) = completion {
          self.state.send(.error(message: error.localizedDescription))
        }

      }) { [weak self] results in
        guard let self = self else { return }
        self.musics = results
      }
      .store(in: &musicsCancellable)
  }
  
  func downloadImage(indexPath: IndexPath) {
    if indexPath.row < musics.count {
      let item = musics[indexPath.row]
      
      _ = API.Downloader.image(urlString: item.artworkUrl100)
        .replaceError(with: nil)
        .sink(receiveValue: { image in
          
          item.thumbnailImage = image
          
          self.state.send(.reloadCell(indexPath: indexPath))

        })
    }
  }
    
}

//MARK: - TableView
extension HomeViewModel {
  func numberOfRows(in section: Int) -> Int {
    musics.count
  }
  
  func musicCellViewModel(at indexPath: IndexPath) -> MusicCellViewModel {
    MusicCellViewModel(music: musics[indexPath.row])
  }
  
}
