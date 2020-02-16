# Schedulers

Tới phần này sẽ tổn hại nhiều nơron thân kinh của bạn lắm đây. Combine là thư viện của Apple đưa ra nhằm giải quyết bài toán **asynchronous programming**. Mà sống với nó lại không biết cách lập lịch hay xử lý thread/queue thì quả là thiếu sót lớn.

## 12.1. Bắt đầu

Về Scheduler là prototcol mà định nghĩa khi nào & như thế nào thực thi một closure. Nhưng đó chỉ là 1 phần câu chuyện cần được kể. 

Schedule sẽ cung cấp nội dung của một hành động trong tương lai hoặc ở 1 tương lai xác định cụ thể nàom đó. Hành động đó được bọc lại bằng 1 closure (được khai báo trong chính nó).

Về khái niệm `Thread` thì hâu như không được đề cập tới trong khi làm việc với scheduler. Vì vậy, xác định được mình đang đứng ở Thread là điều rất quan trọng & sống còn. Và cần ghi nhớ điều này

> Scheduler không phải là thread.

Ví dụ:

Trong giao diện thì các thao tác như nhấn vào 1 button sẽ được bắt và thực thi trong `Main Thread`. Nhưng một số tác vụ như request api thì phải được thưc thi ở `background`. Lúc này bạn sẽ phải tạo scheduler cho nó. Cuối cùng, khi xong tác vụ thì cần phải update lại UI ở `Main Thread`. Lại phải tạo lại scheduler cho nó ...

Một số ngữ cảnh sẽ ảnh hưởng nhiều tới schedule như:

* foreground / background
* Serialized / Parallelized

## 12.2. Operators for scheduling

### `subscribe(on:)`

Một publisher sẽ không hoạt động nếu không có subcriber đăng kí tới. Như các phần trước thì việc subscribe từ subscriber thì sẽ tạo ra 1 subscription. Publisher sẽ bắt đầu hành động, sau đó gởi các giá trị đi. Tiếp theo sử dụng các toán tử để biến đổi giá trị ... và tới subscriber nhận được giá trị cuối cùng.

> Mọi thứ nếu không có gì đặc biệt thì chúng diễn ra ở Main Thread

 Bắt đầu với đoạn code sau:

```swift
let computationPublisher = Publishers.ExpensiveComputation(duration: 3)

let queue = DispatchQueue(label: "serial queue")

let currentThread = Thread.current.number
print("Start computation publisher on thread \(currentThread)")

let subscription = computationPublisher
  .subscribe(on: queue)
  .sink { value in
    let thread = Thread.current.number
    print("Received computation result on thread \(thread): '\(value)'")
  }
```

Bạn ko cần quan tâm nhiều về `ExpensiveComputation` , nó sẽ tính toán và phát ra giá trị sau 1 thời gian. Nó là 1 publisher.

Trước tiên bạn tạo ra 1 `queue` kiểu là `serial`. Sau đó in ra thử thread hiện tại là gì?

> Main Thread sẽ đc định danh là 1 (nó đc viết rồi).

Sau đó, tiến hành subscription tới đối tượng trên.  Với toán tử `.subscribe(on: queue)` thì việc subscription nó sẽ diễn ra ở `queue` kia (nó khác main thread). Nên dẫn tới việc `sink` và in kết quả thì cũng thuộc `queue` đó luôn.

> Gía trị in ra trong `sink` sẽ khác 1 (là khác main thread).

Như vậy, với `.subscribe(on: queue)` giúp bạn subscription trên 1 queue chỉ định nào đó. Tất nhiên giá trị nhận được sẽ ở trên queue đó luôn.

### `receive(on:)`

Phần tiếp theo là cho việc nhận giá trị. Tương tự như trên thì ta có thể set việc nhận giá trị ở 1 `queue` chỉ định nào đó.

Ví dụ code:

```swift
let subscription = computationPublisher 
	.subscribe(on: queue)
	.receive(on: DispatchQueue.main) 
	.sink { value in ... }
```

Hiệu quả trong việc update lại giao diện. Vì mọi thứ liên quan tới giao diện đều ở Main Thread.

## 12.3. Scheduler  implementations

Phần này sẽ là các toán tử thực hiện công việc ngay lập tức. Đây cũng là cách sử dụng schedule đơn giản nhất.

### Immediate Scheduler
Bắt đầu phân tích ví dụ sau, vì phần này không có các toán tử cụ thể.

Tạo 1 timer đếm thời gian, cứ 1 giây đếm 1 lần, thực chất là phát tín hiệu đi 1 lần.
```swift
let source = Timer
 .publish(every: 1.0, on: .main, in: .common) 
 .autoconnect()
 .scan(0) { counter, _ in counter + 1 }
```
Xem tiếp code
```swift
let setupPublisher = { recorder in
  source
    // 2
    .recordThread(using: recorder)
    // 3
    .receive(on: ImmediateScheduler.shared)
    // 4
    .receive(on: DispatchQueue.global())
    .recordThread(using: recorder)
    // 5
    .eraseToAnyPublisher()
}

// 6
let view = ThreadRecorderView(title: "Using ImmediateScheduler", setup: setupPublisher)
PlaygroundPage.current.liveView = UIHostingController(rootView: view)
```

Trong đó:
* `setupPublisher` là 1 publsiher
* `recordThread` ghi lại thông tin của thread hiện tại --> cứ mỗi lần `source` phát ra, thì ghi lại 1 lần và biết thành publisher
* Ta có các `receive` , với `ImmediateScheduler.shared` thì sẽ thực thi ngay trên Thread hiện tại. Nếu không có dòng `.receive(on: DispatchQueue.global())` toàn bộ sẽ được thực thi và nhận được Main Thread.

Ví dụ trên cho bạn thấy như vậy, các hoạt động sẽ thực thi ngay lập tức với `ImmediateSchedule`. Nó phải sử dụng với publisher có không bao giờ lỗi (Never).

Đối nghịch với nó là các toán tử delay hoặc thực thi ở 1 tương lai nào đó.

### RunLoop

Cũng khá  lâu rồi mới xuất hiện lại với RunLoop. Vì ngày nay các dev thường dùng `DispatchQueue` để thay thế việc xử lý các công việc với nhiều theard khác nhau. Bắt đầu với 1 ví dụ sau:

```swift
let source = Timer
  .publish(every: 1.0, on: .main, in: .common)
  .autoconnect()
  .scan(0) { (counter, _) in counter + 1 }

let setupPublisher = { recorder in
    source
        // 1
        .receive(on: DispatchQueue.global())
        .recordThread(using: recorder)
        // 2
        .receive(on: RunLoop.current)
        .recordThread(using: recorder)
        .eraseToAnyPublisher()
}

let view = ThreadRecorderView(title: "Using RunLoop", setup: setupPublisher)
PlaygroundPage.current.liveView = UIHostingController(rootView: view)
```

Tương tự như trên, nhưng lần này tại các `receive` thì dùng khác nhau và `recordThread` lại. Trong đó:
* `RunLoop.current` diễn ra trực tiếp trên Thread hiện tại. Có thể là Main Thread hoặc Thread nào đó.

Thay đổi 1 chút, `.subscribe(on: DispatchQueue.global())` thay vì là `receive` thì lúc này bạn sẽ thấy `RunLoop.current` là cùng thread với publisher.

### DispatchQueue scheduler

Với 2 phần nhỏ trên, bạn sẽ để ý là không có các tham số custom đươc. Chúng ta buộc phải dùng một số giá trị đặc biệt. Phụ thuộc vào thread hiện tại mà đang thực hiện subscription. Với `Dispatch Queue` thì mọi thứ sẽ khác.

#### Queue vs. Thread

Bổ túc lại kiến thức một chút ở phần này.
* `Queue` là hàng đợi mà chúng ta đẩy các công việc vào. Chúng sẽ thực thi theo tuần tự hay đồng thời, tuỳ thuộc vào cách setup. Tất cả các queue cùng 1 dispatch sẽ ở cùng 1 queue
* `Thread` là luồng để thực thi các task hay các queue. Mỗi Thread có 1 DispatchQueue quản lý và chúng ta cũng không cần quan tâm nhiều tới thread trong Dispatch. Các phần việc ưu tiên, chạy như thế nào, share tài nguyên giữa các Thread đều đc Dispatch âm thầm giải quyết rồi.

Xem code ví dụ sau

```swift
// Tạo 2 queue
let serialQueue = DispatchQueue(label: "Serial queue")
let sourceQueue = serialQueue //DispatchQueue.main

// Tạo 1 publisher là `source`
let source = PassthroughSubject<Void, Never>()

// Tạo subscription bằng sourceQueue.schedule (lên lịch) --> mỗi giây thì source phát đi 1 tín hiệu (hàm void)
let subscription = sourceQueue.schedule(after: sourceQueue.now, interval: .seconds(1)) {
  source.send()
}

// Khá quen thuộc, chúng ta quan tâm tới việc nhận giá trị `serialQueue
let setupPublisher = { recorder in
    source
        .recordThread(using: recorder)
        .receive(on: serialQueue)
        .recordThread(using: recorder)
        .eraseToAnyPublisher()
}

let view = ThreadRecorderView(title: "Using DispatchQueue",
                              setup: setupPublisher)
PlaygroundPage.current.liveView = UIHostingController(rootView: view)
```
Mình cũng không hiểu ý nghĩa lắm. Nhưng nôm na thế này:
* Định nghĩa 1 queue
* Thao tác trên đó, tạo publisher và phát giá trị trên chính `queue` đó
* Nhận lại ở 1 `queue` khác
* Còn `subscription` có thể lại ở 1 queue nào đó.

Khó hiểu phải không nào, nói chung thì giống như bạn code Non-Combine với DispatchQueue thôi. Còn giờ là subscribe ở đâu và receive ở đâu?

Có thể thêm các options cho việc này, ví dụ:
```swift
.receive(on: serialQueue, options: DispatchQueue.SchedulerOptions(qos: .userInteractive) )
```

### Operation Queue

Thành phần cuối và là cao cấp nhất. Đây là Class của hệ thống để thực thi các operations và quản lý chúng. Xem code ví dụ sau:

```swift
let queue = OperationQueue()
queue.maxConcurrentOperationCount = 1

let subscription = (1...10).publisher
  .receive(on: queue)
  .sink { value in
    print("Received \(value) on thread \(Thread.current.number)")
  }
```

Trong đó:
* tạo ra 1 queue
* Thực thi 1 subscription với việc phát 10 số từ 1 đến 10
* Nhận kết quả ở 1 queue, chú ý thứ tự kết quả sẽ không phải từ 1 đến 10
* tuy chỉnh để nhận ở 1 thread thực hiện 1 cái concurrent thôi, với thuộc tính `maxConcurrentOperationCount`

Về bản chất thì xem như nó đóng gọi `DispatchQueue` với concurrent lại. Cũng không có nhiều tuỳ chọn ở đây. Khá là buồn phải không nào.

Kết thúc phần này với một chút hụt hẫm, có thể là do thời gian tìm hiểu chưa nhiều và chưa thấy được các ứng dụng củ nó trong project.

---
## Hết
