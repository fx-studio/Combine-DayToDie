//
//  LoginViewModel.swift
//  DemoMVVMCombine
//
//  Created by Le Phuong Tien on 2/18/20.
//  Copyright © 2020 Fx Studio. All rights reserved.
//

import Foundation
import Combine

final class LoginViewModel {
  
  //MARK: - Define
  // State
  enum State {
    case initial
    case logined
    case error(message: String)
  }
  
  // Action
  enum Action {
    case login
    case clear
  }
  
  //MARK: - Properties
  // Publisher & store
  @Published var username: String?
  @Published var password: String?
  @Published var isLoading: Bool = false
  
  // Model
  var user: User?
  
  // Trigger TextField
  var validatedText: AnyPublisher<Bool, Never> {
    return Publishers.CombineLatest($username, $password)
      .map { !($0!.isEmpty || $1!.isEmpty) }
      .eraseToAnyPublisher()
  }
  
  // Actions
  let action = PassthroughSubject<Action, Never>()
  
  // State
  let state = CurrentValueSubject<State, Never>(.initial)
  
  // Subscriptions
  var subscriptions = [AnyCancellable]()
  
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
  
  init(username: String, password: String) {
    self.username = username
    self.password = password
    
    self.user = .init(username: username, password: password)
    
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
  
  init(user: User) {
    self.user = user
    
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
  
  //MARK: - Actions
  
  // Request with callback
  func login() -> AnyPublisher<Bool, Never> {
    
    if isLoading {
      return $isLoading.map { !$0 }.eraseToAnyPublisher()
    }
    
    isLoading = true
    
    // test
    let test = username == "fxstudio" && password == "123456"
    
    let subject = CurrentValueSubject<Bool, Never>(test)
    return subject.delay(for: .seconds(3), scheduler: DispatchQueue.main).eraseToAnyPublisher()
  }
  
  // Request without callback
  func clear() {
    username = ""
    password = ""
  }
  
  //MARK: - Private functions
  // process Action
  private func processAction(_ action: Action) {
    
    print(subscriptions.count)
    
    switch action {
    case .login:
      print("ViewModel -> Login")
    
      _ = login().sink { done in
        self.isLoading = false
        
        if done {
          self.state.value = .logined
        } else {
          self.state.value = .error(message: "Login failed.")
        }
      }
      
    case .clear:
      username = ""
      password = ""
    }
  }
  
  // process State
  private func processState(_ state: State) {
    switch state {
    case .initial:
      
      if let user = user {
        username = user.username
        password = user.password
        isLoading = false
      } else {
        username = ""
        password = ""
        isLoading = false
      }
      
    case .logined:
      print("LOGINED")
      
    case .error(let message):
      print("Error: \(message)")
    }
  }


}
