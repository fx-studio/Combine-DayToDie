//
//  LoginViewController.swift
//  DemoMVVMCombine
//
//  Created by Le Phuong Tien on 2/18/20.
//  Copyright © 2020 Fx Studio. All rights reserved.
//

import UIKit
import Combine

class LoginViewController: BaseViewController {
  
  //MARK: - Properties
  // ViewModel
  var viewModel = LoginViewModel(user: .init(username: "fxstudio", password: "123456"))
    
  // Outlet
  @IBOutlet weak var usernameTextField: UITextField!
  @IBOutlet weak var passwordTextField: UITextField!
  @IBOutlet weak var loginButton: UIButton!
  @IBOutlet weak var indicatorView: UIActivityIndicatorView!
  
  
  //MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  //MARK: - Config View
  //MARK: Setup
  override func setupData() {
    super.setupData()
  }
  
  override func setupUI() {
    super.setupUI()
    
    // Title
    self.title = "Login"
    
    // Navigation Bar
    let clearBarButton = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clear))
    self.navigationItem.leftBarButtonItem = clearBarButton

  }
  
  //MARK: Binding
  override func bindingToView() {
    // username
    viewModel.$username
      .assign(to: \.text, on: usernameTextField)
      .store(in: &subscriptions)
    
    // password
    viewModel.$password
      .assign(to: \.text, on: passwordTextField)
      .store(in: &subscriptions)
    
    // indicator
    viewModel.$isLoading
      .sink(receiveValue: { isLoading in
        if isLoading {
          self.indicatorView.startAnimating()
        } else {
          self.indicatorView.stopAnimating()
        }
      })
      .store(in: &subscriptions)
    
    // button
    viewModel.validatedText
      .assign(to: \.isEnabled, on: loginButton)
      .store(in: &subscriptions)
  }
  
  override func bindingToViewModel() {
    // usernameTextField
    usernameTextField.publisher
      .assign(to: \.username, on: viewModel)
      .store(in: &subscriptions)
    
    // passwordTextField
    passwordTextField.publisher
      .assign(to: \.password, on: viewModel)
      .store(in: &subscriptions)
    
  }
  
  //MARK: Router
  override func router() {
    // viewmodel State
    viewModel.state
      .sink { [weak self] state in
        if case .error(let message) = state {
          // show alert
          _ = self?.alert(title: "Demo MVVM", text: message)
          
        } else if case .logined = state {
          self!.viewModel.isLoading = false
          
          let vc = HomeViewController()
          self?.navigationController?.pushViewController(vc, animated: true)
          
        }
        
    }.store(in: &subscriptions)
  }
  
  //MARK: - Actions
  @IBAction func loginButtonTouchUpInside(_ sender: Any) {
    
//    viewModel.login()
//      .sink { [weak self] done in
//
//        self!.viewModel.isLoading = false
//
//        if done {
//          let vc = HomeViewController()
//          self?.navigationController?.pushViewController(vc, animated: true)
//
//        } else {
//          print("Login Failed")
//
//        }
//      }
//      .store(in: &subscriptions)
    
    viewModel.action.send(.login)
  }
  
  @objc func clear() {
    //viewModel.clear()
    viewModel.action.send(.clear)
  }
  
}
