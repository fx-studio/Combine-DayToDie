//
//  HomeViewController.swift
//  HelloUIKit
//
//  Created by Le Phuong Tien on 3/3/20.
//  Copyright © 2020 Fx Studio. All rights reserved.
//

import UIKit
import Combine

class HomeViewController: UIViewController {
  
  var subscriptions = Set<AnyCancellable>()
  
  var countPublisher = CurrentValueSubject<Int, Never>(0)
  
  @IBOutlet weak var counterLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    //title
    title = "HOME"
    
    //navigation
    let saveBarButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(save))
    self.navigationItem.leftBarButtonItem = saveBarButton
    
    let settingsBarButton = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(gotoSettingsVC))
    self.navigationItem.rightBarButtonItem = settingsBarButton
    
    //subscription
    countPublisher
      .handleEvents(receiveSubscription: { subscription in
        print(subscription)
      }, receiveOutput: { (value) in
        print(value)
      }, receiveCompletion: { (completion) in
        print(completion)
      }, receiveCancel: {
        print("Cancel")
      }, receiveRequest: { (request) in
        print(request.hashValue)
      })
      .map { "\($0)"}
      .assign(to: \.text, on: self.counterLabel)
      .store(in: &subscriptions)
    
    // load count
    let temp = DataManagement.share.load()["count"] ?? 0
    countPublisher.send(temp)
    
  }
  
  @IBAction func increase(_ sender: Any) {
    countPublisher.value += 1
    
  }
  
  @IBAction func reduce(_ sender: Any) {
    countPublisher.value -= 1
  }
  
  @objc func save() {
    DataManagement.share.save(value: self.countPublisher.value)
      .sink(receiveCompletion: { [unowned self] completion in
        if case .failure(let error) = completion {
          self.alert(title: "Error", text: error.localizedDescription)
            .sink { _ in
              // tự sướng trong này
          }
          .store(in: &self.subscriptions)
        }
        
        
      }) { [unowned self] id in
        print("SAVED SUCCESS!")
        self.alert(title: "HOME", text: "SAVED SUCCESS!").sink { _ in }.store(in: &self.subscriptions)
      }
      .store(in: &subscriptions)
    
  }
  
  @objc func gotoSettingsVC() {
    // vc
    let settingsVC = SettingsViewController()
//    settingsVC.count = countPublisher.value
    
//    // publisher
//    let publisher = settingsVC.countPublisher.share()
//
//    // subscription 2
//    publisher
//      .sink { value in
//        self.countPublisher.value = value
//    }
//    .store(in: &subscriptions)
//
//    // subscription 2
//    publisher
//      .map { "\($0)" }
//      .assign(to: \.text, on: self.counterLabel)
//      .store(in: &subscriptions)
    
    settingsVC.$count
      .sink { value in
        self.countPublisher.value = value
    }.store(in: &subscriptions)
    
    
    // push
    self.navigationController?.pushViewController(settingsVC, animated: true)
  }
  
  func alert(title: String, text: String?) -> AnyPublisher<Void, Never> {
    let alertVC = UIAlertController(title: title, message: text, preferredStyle: .alert)
    
    return Future { resolve in
      alertVC.addAction(UIAlertAction(title: "Close", style: .default, handler: { _ in
        resolve(.success(()))
      }))
      
      self.present(alertVC, animated: true, completion: nil)
    }
    .handleEvents(receiveCancel: {
      self.dismiss(animated: true, completion: nil)
    })
    .eraseToAnyPublisher()
  }
  
}
