import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()
public func example(of description: String,
                    action: () -> Void) {
  print("\n——— Example of:", description, "———")
  action()
}

// ----------------------------------------------- //

example(of: "operationCount") {
  let queue = OperationQueue()
  
  queue.publisher(for: \.operationCount)
    .sink { value in
      print("Outstanding operations in queue: \(value)")
  }
  .store(in: &subscriptions)
  
  queue.addOperation {
    print("add the 1st task")
  }
  
  queue.addOperation {
    print("add the 2nd task")
  }
}

example(of: "Custom your class") {
  
  struct UserLocation {
    var city: String
    var address: String
  }
  
  class User: NSObject {
    @objc dynamic var name: String = ""
    @objc dynamic var age: Int = 0
  }
  
  let obj = User()
  
  obj.publisher(for: \.name, options: [.prior])
    .sink { string in
      print("New name of user: \(string)")
    }
    .store(in: &subscriptions)
  
  obj.publisher(for: \.age, options: [.old])
  .sink { value in
    print("New age of user: \(value)")
  }
  .store(in: &subscriptions)
  
  obj.name = "Tèo"
  obj.name = "Tí"
  obj.name = "Tủm"
  
  obj.age = 10
  obj.age = 11
}

example(of: "ObservableObject") {
  class MonitorObject: ObservableObject {
    @Published var someProperty = false
    @Published var someOtherProperty = ""
  }
  let object = MonitorObject()
  
  object.objectWillChange
    .sink {
      print("object will change: \($0)")
  }
  .store(in: &subscriptions)
  
  object.someProperty = true
  object.someOtherProperty = "Hello world"
}
