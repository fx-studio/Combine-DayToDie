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
          print(error.localizedDescription)
        }
        
        
      }) { [unowned self] id in
        print("SAVED SUCCESS!")
        
      }
      .store(in: &subscriptions)
    
  }
  
  
}
