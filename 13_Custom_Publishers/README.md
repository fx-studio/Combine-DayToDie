# Custom Publishers & Handling Backpressure

Đây là phần hứa hẹn sẽ rất hay. Ngay từ ngày đầu tìm hiểu thì có nhắc tới việc Custom các class là Publisher và bây giờ mới tới được phần này.

## 13.1. Tạo Publisher cho riêng bạn

Cũng tới lúc tạo publisher riêng cho mình rồi. Có nhiều cách từ đơn giản tới phức tạp. Tuỳ thuộc vào hoàn cảnh và mục đích của bạn muốn sử dụng. Có 3 các điển hình

* Sử dụng `extension` của `Publisher`
* Tạo ra 1 loại mới
* Sử dụng các toán tử transfrom trong subscription để biến đổi ra Publisher mình mong muốn.

Ngta không khuyến kích việc custom mà ko sử dụng subscription. Nó sẽ phát vỡ đi các nguyên tắc hệ thống trong Combine. Nói trắng ra cố gắng tương minh các chức năng của từng class hay đối tượng. Đừng bọc chúng lại quá. Cụ thể sẽ bắt đầu như sau:

## 13.2. Sử dụng `extension` của Publisher

Đây là cách đơn giản nhất mà bạn có thể tiếp cận. Nó sử dụng extention của Publisher để tạo ra các `operators` của riêng mình. Có 2 kiểu operator đó là:

* producers đóng vai trò tạo ra các publisher một cách trực tiếp
* transformers dùng các toán tử biến đổi để tạo ra các publisher

Xem ví dụ sau:

```swift
extension Publisher {
  func unwrap<T>() -> Publishers.CompactMap<Self, T> where Output == Optional<T> {
    compactMap { $0 }
  }
}
```

Trong đó:

* `extension Publisher` là cái đầu tiên cần viết, sau này dùng như các toán tử khác
* `func unwrap<T>()` tên function mới hay operator mới với kiểu generic là T bất kì nào đó
* Giá trị trả về là 1 kiểu `Publishers.CompactMap` nó sẽ tạo lại 1 publisher mà ko chứa giá trị nào `nil` trên stream
* Giá trị cung cấp cho return type là `Self` --> chính publisher đó và biến đổi thành `T`
* `Output` là kiểu `Optional<T>`
* return với giá trị là `compactMap { $0 }` trong mỗi lần giá trị phát ra thì closure sẽ chạy (function sẽ thực thi)

Test với đoạn code sau:

```swift
let values: [Int?] = [1, 2, nil, 3, nil, 4]
values.publisher
  .unwrap()
  .sink {
    print("Received value: \($0)")
  }
```

Sẽ nhìn pro hơn so với dùng `compactMap` nhĩ. 

Nếu bạn xử lý nhiều trong việc tạo ra publisher của riêng mình và ko kiểm soát đc các kiểu dữ liệu thì hãy nhớ tới 2 điều sau:

* `AnyPublisher<OutputType, FailureType>`
* `eraseToAnyPublisher()`

Đó là thần chú cho bạn!

## 13.3. Tóm tắt một chút về cơ chế của subscription

Xem như thành phần âm thâm trong Combine, subscription giúp ra rất nhiều thứ mà ta không hề hay biết. Xem lại chút cơ chế sau để có thể giúp bạn bẽ gãy bước nào cho việc custom publisher của riêng bạn.

1. Subscriber đăng kỳ (subscribe) tới Publisher
2. Publisher tạo ra `subscription` và đưa nó cho Subscriber. Bạn có thể thấy qua 2 chỗ:
   1. receive(subscription:)
   2. handleEvent
3. Subscriber sẽ `request` giá trị thông qua subscription. Yêu cầu số lượng nhận được, nhớ lại các phần trước thì nó nằm trong class của Subscriber là `request(_:)`
4. Subscription sẽ hoạt động và gởi 1 hoặc nhiều giá trị tới Subscriber
5. Khi nhận được giá trị thì Subscriber sẽ return về `Subscribers.Demand` để điều chỉnh tiếp việc request tới publisher
6. Subscription sẽ gởi cho đến hết số lượng yêu cầu.

Chúng ta sẽ bắt đầu phân rả tiếp quá trình trên dựa theo các ví dụ sau

## 13.4. Publishers emitting values

(đây là 1 trong 2 kiểu publisher sẽ custom, để cập ở phần thứ 1)

### CREATE CONFIG

Tạo 1 struct mới cho Publisher của riêng bạn, à cái này ko phải publisher nha. Đơn giản nó chưa các proprety cần thiết thôi

```swift
struct DispatchTimerConfiguration {
  let queue : DispatchQueue?
  let interval : DispatchTimeInterval
  let leeway : DispatchTimeInterval
  let timer : Subscribers.Demand
}
```

### CUSTOM PUBLISHER

Tạo một struct là `DispatchTimer` là 1 publisher, đây là phần chính. Xem ví dụ sau:

```swift
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
    
      let subscription = DispatchTimerSubscription(
        subscriber: subscriber,
        configuration: configuration
      )
      
      subscriber.receive(subscription: subscription)
    }
    
  }

}
```

* Bước 1: tạo ra struct mới kế thừa từ `Publisher` chú ý có chữ `s` sau ko
* Bước 2: yêu cầu cung cấp các giá trị của `Output` và `Failure`
* Bước 3: yêu cầu implement function `receive(subscriber:)` nó ngược lại với việc Custom Subscriber. Function này yêu cầu phải có `subscription` để trả về cho subscriber. 

Tiếp tục sang phần custom `subscription` nữa. Đời là bể khổ, chưa siêu thoát đc.

### CUSTOM SUBSCRIPTION

Tạo 1 class mới kế thừa `Subscription` Với `Input` của nó chính là Publisher vừa tạo

```swift
private final class DispatchTimerSubscription<S: Subscriber>: Subscription where S.Input == DispatchTime {
  
  func request(_ demand: Subscribers.Demand) {
    <#code#>
  }
  
  func cancel() {
    <#code#>
  }
  
}
```

Các bạn chú ý các chữ `s` nha. và nó yêu cầu 2 function cần thiết là:

* `request`
* `cancel` 

Hoàn thiện class Subscription với các properties, init và 2 function yêu cầu trên

```swift
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
```

Ý nghĩa thì các bạn đọc comments trong code nha.

### CREATE OPERATOR

 Còn giờ qua phần tạo operator cho `Publishers`  để sinh ra publisher xịn sò

```swift
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
```

Các tham số dùng để tạo `configuration`. Giá trị trả về là kiểu `DispatchTimer` (khởi tạo ở trên đó). Test hoath động bằng đoạn code sau

```swift
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
```

OKE, xong phần khó thứ 1, giờ sang phần khó thứ 2 với

## 13.5. Publishers transforming values

Các tiếp theo để custom Publisher, lần này sẽ biến đổi các giá trị. Chúng ta bắt đầu bằng một ví dụ là viết lại 1 operator là `shareReplay`. Qua ví dụ này để phân tích và hiểu hơn về việc custom này. 

Bắt đầu bằng việc khai báo class cho Subscription

### CUSTOM SUBSCRIPTION

```swift
fileprivate final class ShareReplaySubscription<Output, Failure: Error>: Subscription { 
}
```

Bổ sung các thuộc tính cần thiết cho nó

```swift
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
```

Thêm function cho khởi tạo `init`

```swift
// INIT -> khởi tạo các giá trị cần cho subscription
  init<S>(subscriber: S, replay: [Output], capacity: Int, completion: Subscribers.Completion<Failure>?) where S: Subscriber, Failure == S.Failure, Output == S.Input {
    self.subscriber = AnySubscriber(subscriber)
    self.buffer = replay
    self.capacity = capacity
    self.completion = completion
  }
```

Tiếp theo cần có 1 function để gởi `completion` với giá trị đặc biệt (là kết thúc hoặc failure)

```swift
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
```

Khai báo 2 function cần thiết mà việc kế thừa 1 Subscription yêu cầu:

* request
* cancel

```swift
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
```

Bạn sẽ thấy function `emitAsNeeded()`, khai báo tiếp function này để phát giá trị tới các subscriber khác.

* Chú ý việc điều chỉnh `demand` khi có request từ subscriber
* Nếu subscriber ko chị nhận thì thôi
* Còn có nhận thêm thì lấy `demand` mới gán cho `demand` của class này.

```swift
// Phát đi các giá trị nấu cần
  private func emitAsNeeded() {
    // Đảm bảo subscriber tồn tại
    guard let subscriber = subscriber else { return }
    
    // Còn trong bộ đệm thì phát
    while self.demand > .none && !buffer.isEmpty {
      
      // giả 1 sau 1 lần phát
      self.demand -= .max(1)
      
      // cập nhật lại demain, bằng cách gởi đi 1 giá 
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
```

Phát giá trị cuối cùng cho tất cả các `subscriber`.

Định nghĩa thêm function `receive` khi nhận được `Output` từ Publisher

* Lưu trữ dữ liệu đó vào bộ đệm
* Nếu số lượng lưu trữ nhiều hơn khả năng lưu thì remove đi 1 cái (đầu tiên)
* Sau đó là phát giá trị đi

```swift
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
```

Tiếp tục, viết lại `receive` với completion

```swift
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
```

Tới đây thì DONE cho Subscription nhoé! Sang tiếp thèn Publisher custom. Bắt đầu bằng khai báo

### CUSTOM PUBLISHER

```swift
extension Publishers {
  // Khai báo class mới với nhiều cái cần chú ý
  final class ShareReplay<Upstream: Publisher>: Publisher {
    
    // Cung cấp kiểu giá trị cho các Output và Failure
    typealias Output = Upstream.Output
    typealias Failure = Upstream.Failure
    
  }
}
```

Chú ý việc kế thừa:

* ShareReplay là class của mình, kế thừa Publisher (ko s)
* Phải ở trong Extension của Publishers (có s )
* Có 1 Generic là `Upstream` , dùng nó để set lại type cho `Output` và `Failure` (thèn đó là publisher gốc)

Thêm các thuộc tính cho class Publisher mới này

```swift
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
```

Chi tiết ý nghĩa như comments trong đọc code trên. Tiếp theo là hàm khởi tạo `init`

```swift
// INIT --> khởi tạo với các gía trị cần thiết
    init(upstream: Upstream, capacity: Int) {
      self.upstream = upstream
      self.capacity = capacity
    }
```

Viết function để share lại giá trị cho các subscriber khác được lưu trữ trong `subscriptions`

* Chú ý việc  nếu completion chưa có thì mới phát
* Đã có completion thì cancel việc phát
* Phát thông qua function `receive`

```swift
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
```

Khi publisher gốc phát đi completion

```swift
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
```

Nhân vật chính là custom lại function `receive` khi có subscribe tới --> trả subscription

```swift
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
```

Trong đó:

* Nhận được sự kiện mới thì tạo `subscription`
* Lưu trữ `subscription`
* Send `subscription` cho subscriber

Cái hay ở đây là khi có  subscription đầu tiên thì phải subscription tới thèn publisher gốc với `demand = unlinited` để ko bỏ sót giá trị nào hết. Từ đó khi nhận được

* Giá trị thì --> `replay` lại các subscriber trong lưu trữ
* Completion --> send completion cho các subscriber trong lưu trữ
* Lưu trữ đối tươngj publisher đó lại
* Khi có subscription mới (sau khi complete) thì khác các giá trị cũ trong bộ đệm.

### CUSTOM OPERATOR

Chừ dùng cho pro thì phải tạo 1 operator cho nó. Xem code ví dụ:

```swift
// ---------------- OPERATOR ---------------- //
// Tạo extension cho Publisher (ko s) để có 1 operator là `shareReplay`
extension Publisher {
  func shareReplay(capacity: Int = .max) -> Publishers.ShareReplay<Self> {
    return Publishers.ShareReplay(upstream: self, capacity: capacity)
  }
}

```

Operator này cho `Publisher` (ko s), từ từ publisher mình tạo ra 1 publisher khác từ upstream với Type là `ShareReplay`. 

Sử dụng

```swift
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


```

chạy ví dụ trên để hiểu kết quả nhận được từ việc Custom Publisher. Giờ mới hiểu ngta khuyến khích bạn ko nên custom nó.

DONE phần mệt mỏi này :-(

## 13.6. Handling backpressure

Khi 1 dòng nước chảy, thì áp lực nước sẽ tác động tới các nơi nhận nước.  Vì dụ như cái van xả nc, luôn luôn chị 1 áp lức. Đúng như với Combine thì áp dụng nguyên tắc vật lý này vào thì các subscriber cũng phải chịu áp lực do các giá trị của publisher phát ra.

Thông thường bạn sẽ không thấy được, nhưng rơi vào các trường hợp sau đây thì bạn nên cân nhắc:

* Xử lý data lớn, như input của các sensors
* Xử lý file dung lượng lớn
* Render UI và update UI với data
* Chờ người dùng nhập liệu
* Các trường hợp mà subscriber xử lý dữ liệu chậm hơn tốc độ phát của publisher

Vấn đề này thì đã có giải quyết ở các chương trước với việc Custom Subscriber dựa theo điều chỉnh về `request` cho  `demand`. Phần trước chúng ta cũng thấy được custom subscription cũng có thể điều chỉnh linh hoạt việc này. Tuy nhiên, sẽ sinh ra các trường hợp publisher khủng bố với hàng loạt giá trị phát ra thì khi đó cần phải

* Control publisher
* Buffer values
* Drop values
* Combination

Việc điều chỉnh áp lực này tổng quát tới từ 2 thứ

* Custom subscription từ Publisher
* Điều chỉnh request từ Subscriber

Tuy nhiên, phần này chúng ta tìm hiểu về 1 thứ khác. Nó ở phái sau cùng của việc implement.

### PausableSink

Khi báo 1 struct với tên là `PausableSink`

```swift
protocol Pausable {
  var paused: Bool { get }
  func resume()
}
```

Chúng ta sẽ không sử dụng `pause()` có sẵn, mà dựa vào việc nhận từng giá trị mà quyết định dừng hay không dừng. Việc này sẽ phức tạp hơn nhiều.

#### Custom Subscriber

Khai báo 1 class Subscriber mới với 1 sãnh kế thừa

```swift
final class PausableSubscriber<Input, Failure: Error> : Subscriber, Pausable, Cancellable { 

}
```

Thêm các properties vào

* định danh cho Combine, cũng ko biết làm gì nữa. Hình như yêu cầu mỗi subscriber cần có
* các closure
  * `receiveValue` luật quyết định sinh tử
  * `receiveCompletion` kết thúc cuộc đời

```swift
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
```

Thêm hàm khởi tạo `init`

```swift
// INIT --> khởi tạo
  init(receiveValue: @escaping (Input) -> Bool,
       receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void) {
    
    self.receiveValue = receiveValue
    self.receiveCompletion = receiveCompletion
  }
```

Viết lại `cancel`

```swift
// CANCEL --> khai bảo thêm, chứ ko yêu câu lắm
  func cancel() {
    subscription?.cancel()
    subscription = nil
  }
```

Thêm `resume` để phát lại giá trị

```swift
// Thêm function kích hợp việc phát, của em struct trên
  func resume() {
    guard paused else { return }
    paused = false
    // 14
    subscription?.request(.max(1))
  }
```

3 function cần yêu cầu khi thực hiện việc custom subscriber

```swift
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
```

Pha xử lý ở đây phải gọi là thông minh. Tiếp theo là phần custom operator

#### Custom Operator

```swift
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

```

Cái này đơn giản thôi, không khó mấy. Khai báo các tham số cần thiết. Sau đó tạo 1 subscriber với class `PausableSubscriber`. Rồi subscribe tới publisher (đang là self). Return lại cho thích làm gì thì làm.

#### Sử dụng

Tạo subscriptions

* Cho 1 array từ 1 đến 6, biến đổi thành publisher
* Gọi operator mới tạo và cung cấp các đối số cần thiết
* `receiveCompletion` closure kết thúc với kiểu mặc định của `Subscriber`
* `receiveValue` với closer có tham số là `value` và return type là `Bool` --> đây là luật quyết định số phận
* Nếu giá trị nhận được là chẵn thì tiếp tục nhận, lẽ thì dừng

```swift
let subscription = [1, 2, 3, 4, 5, 6]
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

```

Khi chạy thì sẽ dừng ngay cái đầu tiên. Nên để xem ví dụ chạy tiếp thì phải thêm đoạn code sau cho timer phát tiếp.

```swift
// Dùng Timer để phát lần lượt mỗi 2 giây
let timer = Timer.publish(every: 2, on: .main, in: .common)
  .autoconnect()
  .sink { _ in
    guard subscription.paused else { return }
    print("Subscription is paused, resuming")
    subscription.resume()
}
```

OKE, WELL DONE!

## Tóm tắt

Quả thật là 1 bài dài và phức tạp + hại não. Ta có thể tóm tắt lại như sau:

* Sử dụng extention của `Publisher` (ko s) để tạo các `operator` cho riêng bạn. Phương pháp này bạn có thể custom các publisher từ các operator của hệ thông và không thay đổi gì nhiều tới cấu trúc chung.
* Có 2 kiểu custom Publisher chính
  * Tạo mới hoàn toàn và nó trực tiếp phát ra giá trị
  * Chuyển đổi từ 1 publisher khác, ngta gọi là `upstream` để tạo publisher riêng, Sau đó tuỳ thuộc vào giá trị nhận được sẽ phát ra theo kiểu riêng của mình
* Việc quan trong của custom Publisher đó là `Custom Subscription`
  * Điều kiển cả 2 đối tượng Publisher và Subscriber
  * `Demand` & `receive` là 2 cái cần chú ý nhất
* Có thể điều kiển việc phát giá trị của Publisher thông quan việc `Custom Subscriber`
  * Cách truyền thống là custom chính trong sub-class  subcriber mới
  * Custom tại cuối việc implement, tuỳ thuộc vào giá trị nhận được để quyết định (ở đây đó là luật)
  * Bản chất cũng không khác nhau mấy, nhưng 1 cái là class quyết định. Và 1 cái do subscription quyết định

---

### HẾT

(phần này sẽ tiếp tục nghiên cứu sau để hiểu rõ hơn, chứ thực sự là HAY)
