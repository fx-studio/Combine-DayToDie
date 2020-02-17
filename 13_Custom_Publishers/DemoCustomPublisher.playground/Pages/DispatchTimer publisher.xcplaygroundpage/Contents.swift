import Foundation
import Combine

struct DispatchTimerConfiguration {
  let queue : DispatchQueue?
  let interval : DispatchTimeInterval
  let leeway : DispatchTimeInterval
  let times : Subscribers.Demand
}

extension Publishers {

  struct DispatchTimer: Publisher {
    
    typealias Output = DispatchTime
    typealias Failure = Never
    
    let configuration: DispatchTimerConfiguration
    
    init(configuration: DispatchTimerConfiguration) {
      self.configuration = configuration
    }
    
    func receive<S: Subscriber>(subscriber: S)
      where Failure == S.Failure,
            Output == S.Input {
    
      let subscription = DispatchTimerSubscription( subscriber: subscriber, configuration: configuration)
      
      subscriber.receive(subscription: subscription)
    }
    
  }
}

private final class DispatchTimerSubscription<S: Subscriber>: Subscription where S.Input == DispatchTime {
  
  //Properties
  // thiết lập giá trị cho publisher
  let configuration: DispatchTimerConfiguration
  // thời gian theo request
  var times: Subscribers.Demand
  // sự thay đổi request, bắt đầu là 0 có gì
  var requested: Subscribers.Demand = .none
  // nhân vật chính, dùng để phát đi từng giây
  var source: DispatchSourceTimer? = nil
  // khứa subcriber
  var subscriber: S?
  
  //init --> khởi tạo các giá tri cần thiết
  init(subscriber: S, configuration: DispatchTimerConfiguration) {
    self.configuration = configuration
    self.subscriber = subscriber
    self.times = configuration.times
  }
  
  // Yêu cầu function từ class Subscription kế thừa
  func request(_ demand: Subscribers.Demand) {
    
    // bảo vệ times --> hết times thì kết thúc
    guard times > .none else {
      subscriber?.receive(completion: .finished)
      return
    }
    
    // công dồn request vào
    requested += demand
    
    // kích hoạt source
    if source == nil, requested > .none {
      
      // khởi tạo publisher để làm source
      let source = DispatchSource.makeTimerSource(queue: configuration.queue)
      
      // lập lịch cho nó
      source.schedule(deadline: .now() + configuration.interval,
                       repeating: configuration.interval,
                       leeway: configuration.leeway)
      
      // set các sự kiện
      source.setEventHandler{ [weak self] in
        
        // dừng nếu không còn gì
        guard let self = self, self.requested > .none else { return }
        
        // phát ra 1 giá trị thì giảm đi 1
        self.requested -= .max(1)
        self.times -= .max(1)
        
        // gởi giá trị cho subscriper (QUAN TRỌNG_
        _ = self.subscriber?.receive(.now())
        
        // Nếu max config rồi (bị trừ sau mỗi lần subscribe) thì thôi, say goodbye em nó
        if self.times == .none {
          self.subscriber?.receive(completion: .finished)
        }
      }
      
      // kích hoạt source
      self.source = source
      source.activate()
      
    }
  }
  
  // Yêu cầu function từ class Subscription kế thừa
  func cancel() {
    source = nil
    subscriber = nil
  }
  
}

//Tạo toán tử mới
extension Publishers {
  static func timer(queue: DispatchQueue? = nil,
                    interval: DispatchTimeInterval,
                    leeway: DispatchTimeInterval = .nanoseconds(0),
                    times: Subscribers.Demand = .unlimited)
  -> Publishers.DispatchTimer {
    return Publishers.DispatchTimer(configuration: .init(queue: queue,
                                                         interval: interval,
                                                         leeway: leeway,
                                                         times: times))
  }
}

// log thời gian
var logger = TimeLogger(sinceOrigin: true)

// dùng operator vừa khai báo trên, lượt bỏ đi 2 tham số queue và leeway
let publisher = Publishers.timer(interval: .seconds(1), times: .max(6))

// tiến hành subscription
let subscription = publisher.sink { time in
  print("Timer emits: \(time)", to: &logger)
}

// sau 3.5 giây thì cancel
DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
  subscription.cancel()
}

