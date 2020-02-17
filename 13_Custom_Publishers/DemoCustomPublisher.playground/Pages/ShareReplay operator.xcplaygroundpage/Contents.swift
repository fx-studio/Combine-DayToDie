import Foundation
import Combine

// Khai báo 1 class của Subscription. Nhắc lại đây chính là đối tượng mà Subscriber nhận được, khi subscribe tới publisher
// Cần khai báo class
fileprivate final class ShareReplaySubscription<Output, Failure: Error>: Subscription {
  
  // Properties
  // Bộ đệm để phát lại
  let capacity: Int
  
  // lưu trữ lại 1 subscriber
  var subscriber: AnySubscriber<Output,Failure>? = nil
  
  // yêu cầu request
  var demand: Subscribers.Demand = .none
  
  // Lưu trữ các giá trị trong bộ đệm
  var buffer: [Output]
  
  // kết thúc để sẵn đó
  var completion: Subscribers.Completion<Failure>? = nil
  
  // INIT -> khởi tạo các giá trị cần cho subscription
  init<S>(subscriber: S, replay: [Output], capacity: Int, completion: Subscribers.Completion<Failure>?) where S: Subscriber, Failure == S.Failure, Output == S.Input {
    self.subscriber = AnySubscriber(subscriber)
    self.buffer = replay
    self.capacity = capacity
    self.completion = completion
  }
  
  // Phát đi các giá trị nấu cần
  private func emitAsNeeded() {
    // Đảm bảo subscriber tồn tại
    guard let subscriber = subscriber else { return }
    
    // Còn trong bộ đệm thì phát
    while self.demand > .none && !buffer.isEmpty {
      
      // giả 1 sau 1 lần phát
      self.demand -= .max(1)
      
      // giảm demain đi 1
      let nextDemand = subscriber.receive(buffer.removeFirst())
      
      // nếu total Demand = 0 thì sét lại self.demand
      if nextDemand != .none {
        self.demand += nextDemand
      }
      
      // Nếu 1 sự kiện hoàn thành thì gởi completion đi
      if let completion = completion {
        complete(with: completion)
      }
    }
  }
  
  // Method khi nhận được giá trị
  func receive(_ input: Output) {
    
    // đảm bảo subscriber
    guard subscriber != nil else { return }
    
    // Thêm giá trị vào bộ đệm
    buffer.append(input)
    if buffer.count > capacity {
      // số lượng của buffer hơn khả năng lưu trữ thì remove đi 1
      buffer.removeFirst()
    }
    // phát giá trị đi
    emitAsNeeded()
  }
  
  // Khi nhận completion
  func receive(completion: Subscribers.Completion<Failure>) {
    // vẫn là đảm bảo có subscriber
    guard let subscriber = subscriber else { return }
    // xoá subscriber
    self.subscriber = nil
    // xoá hết bộ đệm
    self.buffer.removeAll()
    // phát completion cho subscriber
    subscriber.receive(completion: completion)
  }
  
  // Các method cần thiết
  func request(_ demand: Subscribers.Demand) {
    if demand != .none {
      self.demand += demand
    }
    
    // đảm bảo chuyển tiếp giá trị đi
    emitAsNeeded()
  }
  
  func cancel() {
    complete(with: .finished)
  }
  
  private func complete(with completion: Subscribers.Completion<Failure>) {
    // xác định subscriber tồn tại
    guard let subscriber = subscriber else { return }
    // xoá nó
    self.subscriber = nil
    // xoá tiếp
    self.completion = nil
    // xoá sạch
    self.buffer.removeAll()
    // phát completion
    subscriber.receive(completion: completion)
  }
  
  
}

// ---------------- PUBLISHER ---------------- //
extension Publishers {
  // Khai báo class mới với nhiều cái cần chú ý
  final class ShareReplay<Upstream: Publisher>: Publisher {
    
    // Properties
    // Không hiểu mấy nhưng khoá và hạn quyền truy cập vào các biến của mình để bị ng khác thay đổi
    private let lock = NSRecursiveLock()
    // tham chiếu tới 1 publisher
    private let upstream: Upstream
    // khả năng chứa
    private let capacity: Int
    // lưu trữ các giá trị cho việc phát
    private var replay = [Output]()
    // lưu trữ các subscription tới
    private var subscriptions = [ShareReplaySubscription<Output, Failure>]()
    // Vì nó sẽ phát ra các giá trị trong lưu trữ khi có 1 subscriber kết nối tới, mặc dù lúc đó đã completed rồi. Cái này mang tính chất ghi nhớ.
    private var completion: Subscribers.Completion<Failure>? = nil
    
    // Cung cấp kiểu giá trị cho các Output và Failure
    typealias Output = Upstream.Output
    typealias Failure = Upstream.Failure
    
    
    // INIT --> khởi tạo với các gía trị cần thiết
    init(upstream: Upstream, capacity: Int) {
      self.upstream = upstream
      self.capacity = capacity
    }
    
    // Phát lại giá trị cho các subscriber
    private func replay(_ value: Output) {
      // Vì có thể có nhiều người truy cập tới và phải bảo vêk khi bị share
      lock.lock()
      defer { // phòng bệnh hơn chữa bệnh
        lock.unlock()
        
      }
      
      // nếu chưa hoàn thành thì phát giá trị đi cho các subscriber
      guard completion == nil else { return }
      
      // lưu giá trị vào bộ đệm
      replay.append(value)
      
      // kiểm tra hơn khác năng lưu trữ thì remove 1 cái đầu tiên thêm vào
      if replay.count > capacity {
        replay.removeFirst()
      }
      // cứ mỗi subscription thì gởi đi 1 giá trị (giá trị này ở tham số)
      subscriptions.forEach {
        _ = $0.receive(value)
      }
      
    }
    
    // Khi publisher phát đi completion
    private func complete(_ completion: Subscribers.Completion<Failure>) {
      lock.lock()
      defer { lock.unlock() }
      
      // lưu dấu nó lại
      self.completion = completion
      // gởi cho tất cả các subscription biết là kết thúc cuộc chơi rồi
      subscriptions.forEach {
        _ = $0.receive(completion: completion)
      }
    }
    
    // Method quan trọng nhất của custom Publisher là nhận đc subscription từ Subscriber
    func receive<S: Subscriber>(subscriber: S)
      where Failure == S.Failure,
      Output == S.Input {
        
        // mịa cái thèn khoá với mở khoá này
        lock.lock()
        defer {
          lock.unlock()
        }
        
        // Vì khi có mỗi subscriber đăng kí tới thì phải tạo ra 1 subscription trả về cho subscriber
        // tạo subscription
        let subscription = ShareReplaySubscription(subscriber: subscriber,
                                                   replay: replay,
                                                   capacity: capacity,
                                                   completion: completion)
        // Lưu trữ subscription lại --> để gởi lại giá trị sau đó
        subscriptions.append(subscription)
        
        // Phát cho thèn subcriber hiện tại biết đã kết nỗi OKE roiof
        subscriber.receive(subscription: subscription)
        
        // Khi có 1 subscribe tới
        guard subscriptions.count == 1 else { return }
        
        // tạo 1 subscriber với Sink tới 1 AnySubscriber
        let sink = AnySubscriber(
          // khi có kết nối thì tạo request là unlimit
          receiveSubscription: { subscription in
            subscription.request(.unlimited)
          },
          // Nhận được giá trị
          receiveValue: { [weak self] (value: Output) -> Subscribers.Demand in
            // phát đi cho các subscriber khác
            self?.replay(value)
            // return bằng none để subscriber đó ko request thêm
            return .none
          },
          // khi có completion
          receiveCompletion: { [weak self] in
            self?.complete($0) }
        )
        
        //TỪ thèn Zombie gốc là UPSTREAM thì dùng chính subscriber đó để subscription tới --> QUÁ HAY luôn~
        upstream.subscribe(sink)
        
    }
  }
}

// ---------------- OPERATOR ---------------- //
// Tạo extension cho Publisher (ko s) để có 1 operator là `shareReplay`
extension Publisher {
  func shareReplay(capacity: Int = .max) -> Publishers.ShareReplay<Self> {
    return Publishers.ShareReplay(upstream: self, capacity: capacity)
  }
}

// ---------------- SỬ DỤNG ---------------- //
var logger = TimeLogger(sinceOrigin: true)

// Thèn zombie gốc
let subject = PassthroughSubject<Int,Never>()

// Tạo thèm publisher mới
let publisher = subject.shareReplay(capacity: 2)

// Gởi đi 1 : ko có ai theo dõi
subject.send(0)

// subscription đầu tiên
let subscription1 = publisher.sink( receiveCompletion: {
    print("subscription1 completed: \($0)", to: &logger)
  },
  receiveValue: {
    print("subscription1 received \($0)", to: &logger)
  }
)

// gởi đi 1 lố
subject.send(1)
subject.send(2)
subject.send(3)

// sub tiếp lần 2
let subscription2 = publisher.sink(
  receiveCompletion: {
    print("subscription2 completed: \($0)", to: &logger)
  },
  receiveValue: {
    print("subscription2 received \($0)", to: &logger)
  }
)

// gởi đi 1 lố nữa
subject.send(4)
subject.send(5)

// gởi đi completion
subject.send(completion: .finished)

// sub lần 3
var subscription3: Cancellable? = nil
// Sub 1 giây mới sub
DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
  print("Subscribing to shareReplay after upstream completed")
  subscription3 = publisher.sink(
    receiveCompletion: {
      print("subscription3 completed: \($0)", to: &logger)
    },
    receiveValue: {
      print("subscription3 received \($0)", to: &logger)
    }
  )
}

