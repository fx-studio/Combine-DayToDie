# Debugging

Cha ông ta đã từng có câu:

> Code nhiều bug nhiều, code ít bug ít, không code không bug.

Vì vậy chương này sẽ cung cấp những công cụ giúp tìm kiếm bugs. Tuỳ vào trình độ của bạn mà sử dụng sao cho có hiệu quả.

### 6.1. Printing events

Cách đơn giản nhất để xem `publisher` phát ra gì:

* Toán tử `print()` và `print(_:to:)`

```swift
let publisher = (0...10).publisher
  
  publisher
    .print("publisher")
    .sink { print($0) }
    .store(in: &subscriptions)
```

Trong đó từ `"publisher"` là tiền tố trước khi in thứ gì đó ra.

Giờ nâng cấp thêm 1 chút nữa cho đẹp, để thấy được thời gian giữa mỗi lần phát. Thêm class này

```swift
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
```

Edit tiếp code

```swift
let publisher = (0...10).publisher
  
  publisher
    .print("publisher", to: TimeLogger())
    .sink { _ in }
    .store(in: &subscriptions)
```

### 6.2. handle Events

Đôi lúc chưa nhận được giá trị nào hết nhưng subscription của bạn kết thúc hoặc lỗi. Nên thêm 1 toán tử để debug cho publisher phát ra  hay nhận về sự kiện gì, đó là `handleEvents`. Chúng ta có đầy đủ các thể loại sau:

* receiveSubscription
* receiveOutput
* receiveCompletion
* receiveCancel
* receiveRequest

```swift
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
```

### 6.3. the last resort

Xem như là giải pháp cuối cùng để debug. Bao gồm 2 toán tử:

* `breakpointOnError()`
* `breakpoint(receiveSubscription:receiveOutput:receiveCompletion:). `

Nghe 2 cái tên thì bạn đã liên hệ tới Break point trong Xcode. Tại sao vậy? Mình xin phép để lại nó cho các bạn tự tìm câu trả lời.

### Tóm tắt

* `print` dùng để theo dõi vòng đời của publisher bao gồm các giá trị mà nó phát ra hay nhận được
* `print(_:to:)` custom lại cái print cho ngầu hơn
* `handleEvents` theo dõi các sự kiện phát ra trong vòng đời của publisher
* `breakpointOnError` & `breakpoint` dùng để ngắt đứt hoạt động của publisher với các sự kiện chỉ định