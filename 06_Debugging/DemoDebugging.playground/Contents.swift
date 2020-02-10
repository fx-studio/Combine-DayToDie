import UIKit
import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()
public func example(of description: String,
                    action: () -> Void) {
  print("\n——— Example of:", description, "———")
  action()
}

class TimeLogger: TextOutputStream {
  private var previous = Date()
  private let formatter = NumberFormatter()
  
  init() {
    formatter.maximumFractionDigits = 5
    formatter.minimumFractionDigits = 5
    
  }
  
  func write(_ string: String) {
    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    let now = Date()
    print("+\(formatter.string(for:now.timeIntervalSince(previous))!)s: \(string)")
    previous = now
  }
}

// -------------------------------------------- //
example(of: "Printing events") {
  let publisher = (0...10).publisher
  
  publisher
    .print("publisher", to: TimeLogger())
    .sink { _ in }
    .store(in: &subscriptions)

}

example(of: "handleEvents") {
  let request = URLSession.shared
      .dataTaskPublisher(for: URL(string: "https://www.google.com/")!)
  
  request
    .handleEvents(receiveSubscription: { _ in print("Network request will start")
    }, receiveOutput: { _ in
      print("Network request data received")
    }, receiveCancel: {
      print("Network request cancelled")
    })
    .sink(receiveCompletion: { completion in
      print("Sink received completion: \(completion)")
    }) { (data, _) in
      print("Sink received data: \(data)")
    }
    .store(in: &subscriptions)
}

