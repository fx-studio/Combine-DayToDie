import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()
public func example(of description: String,
                    action: () -> Void) {
  print("\n——— Example of:", description, "———")
  action()
}

//example(of: "RunLoop") {
//  let runLoop = RunLoop.main
//
//  let subscription = runLoop.schedule( after: runLoop.now, interval: .seconds(1), tolerance: .milliseconds(100)) {
//    print("Timer fired")
//  }
//
//  subscription.store(in: &subscriptions)
//}

//example(of: "Timer") {
//  let publisher = Timer.publish(every: 1.0, on: .main, in: .common)
//
//  publisher
//    .autoconnect()
//    .scan(0) { counter, _ in counter + 1 }
//    .sink { counter in
//      print("counter is \(counter)")
//    }
//    .store(in: &subscriptions)
//}

example(of: "DispatchQueue") {
  let queue = DispatchQueue.main
  
  let source = PassthroughSubject<Int, Never>()
  
  var counter = 0
  
  let cancellable = queue.schedule(after: queue.now, interval: .seconds(1)) {
    source.send(counter)
    counter += 1
  }
  
  cancellable.store(in: &subscriptions)
  
  source
    .sink { (temp) in
      print("temp : \(temp)")
      if temp == 10 {
        cancellable.cancel()
      }
  }
  .store(in: &subscriptions)
  
}
