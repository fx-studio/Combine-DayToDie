import Combine
import Foundation

// Định nghĩa 1 struct cho Pause
protocol Pausable {
  var paused: Bool { get }
  func resume()
}


// Class chính kế thứa 1 sãnh các class máu mặt
final class PausableSubscriber<Input, Failure: Error> : Subscriber, Pausable, Cancellable {
  
  // Properties
  // Mã định danh cho Combine và tối ưu stream
  let combineIdentifier = CombineIdentifier()
  
  // Khai báo closure cho việc nhận value để quyết định pause hay ko>
  let receiveValue: (Input) -> Bool
  
  // completion cho việc kết thúc
  let receiveCompletion: (Subscribers.Completion<Failure>) -> Void
  
  // lưu giữ subscription này lại
  private var subscription: Subscription? = nil
  
  // bắt đầu là ko dừng
  var paused = false
  
  // INIT --> khởi tạo
  init(receiveValue: @escaping (Input) -> Bool,
       receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void) {
    
    self.receiveValue = receiveValue
    self.receiveCompletion = receiveCompletion
  }
  
  // CANCEL --> khai bảo thêm, chứ ko yêu câu lắm
  func cancel() {
    subscription?.cancel()
    subscription = nil
  }
  
  // 3 FUNCTION YÊU CẦU phải có
  
  // Nhận được subscription
  func receive(subscription: Subscription) {
    // lưu trữ lại
    self.subscription = subscription
    // Request với 1 giá trị
    subscription.request(.max(1))
  }
  
  // Nhận được input
  func receive(_ input: Input) -> Subscribers.Demand {
    // luật này sẽ quyết định việc nhận giá trị hay là không --> KHÁ THÔNG MINH
    paused = receiveValue(input) == false
    
    // Nếu ko nhận .none, nếu có thì request lại 1
    return paused ? .none : .max(1)
  }
  
  // khi nhận kết thúc
  func receive(completion: Subscribers.Completion<Failure>) {
    // giải quyết hậu quả
    receiveCompletion(completion)
    subscription = nil
  }
  
  // Thêm function kích hợp việc phát, của em struct trên
  func resume() {
    guard paused else { return }
    paused = false
    // 14
    subscription?.request(.max(1))
  }
}

//------------------- PUBLISHER ------------------- //
extension Publisher {
  
  // Thêm 1 function mới cho Publisher (ko s)
  func pausableSink(
    receiveCompletion: @escaping ((Subscribers.Completion<Failure>) -> Void),
    receiveValue: @escaping ((Output) -> Bool)) -> Pausable & Cancellable {
    
    // Tạo đối tượng subcriber mới với kiểu `PausableSubscriber`
    let pausable = PausableSubscriber(receiveValue: receiveValue, receiveCompletion: receiveCompletion)
    
    // subscribe tới publisher
    self.subscribe(pausable)
    
    // trả về cho thích làm gì thì làm
    return pausable
  }
}

//-------------------- SUBSCRIPTION ---------------------//
let subscription = [0, 8, 10, 1, 2, 3, 4, 5, 6]
  .publisher
  .pausableSink(receiveCompletion: { completion in
    print("Pausable subscription completed: \(completion)")
  }) { value -> Bool in
    // in giá trị ra
    print("Receive value: \(value)")
    
    // sau đó quyết định quyền sinh sát cho Publisher
    if value % 2 == 1 {
      print("Pausing")
      return false
    }
    return true
}

// Dùng Timer để phát lần lượt mỗi giây
let timer = Timer.publish(every: 2, on: .main, in: .common)
  .autoconnect()
  .sink { _ in
    guard subscription.paused else { return }
    print("Subscription is paused, resuming")
    subscription.resume()
}
