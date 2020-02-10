# Timer

Thời điểm quay lại quá khứ hào hùng của Objective-C và RunLoop và Timer!

### 7.1. RunLoop

```swift
let runLoop = RunLoop.main
  
  let subscription = runLoop.schedule( after: runLoop.now, interval: .seconds(1), tolerance: .milliseconds(100)) {
    print("Timer fired")
  }
```

Cách đầu tiên từ thuở sơ khai để tạo ra 1 vòng lặp thời gian. Với mỗi Thead thì để có vòng lặp của riêng nó. Và bạn có thể tạo ra 1 Thread từ thread hiện tại của bạn và kèm theo đó bạn có 1 RunLoop riêng của bạn.

> Apple không khuyến khích lập trình viên thực hiện điều này.

### 7.2. Timer

Cách thứ 2 để có 1 vòng lặp thời gian là sử dụng class Timer. Nó cũng là class khá lâu đời trong lịch sử phát triển của Apple

```swift
let publisher = Timer.publish(every: 1.0, on: .main, in: .common)
  
  publisher
    .autoconnect()
    .scan(0) { counter, _ in counter + 1 }
    .sink { counter in
      print("counter is \(counter)")
    }
    .store(in: &subscriptions)
```

Các tham số `.main` và `.common` thì bạn tự tìm hiểu thêm.

Mỗi lần subscribe thì nó tạo ra 1 Cancelable. Hoặc thực hiện lệnh `connect()` thì cũng tạo ra Cancelable.

### 7.3. DispatchQueue

Cách thứ 3 là sử dụng DispatchQueue. Cái này khá quen thuộc cho anh em dev iOS.

```swift
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
```

Trong đó:

* `queue` main queue
* `source` là 1 publisher
* `counter` giá trị đếm
* `cancellable` là `Cancellaber` --> cần lưu trữ, ko thì auto kết thúc
* subscription từ source để in giá trị ra

### Tóm tắt

* RunLoop.schedule --> tạo ra 1 bộ đếm thời gian, hãy dùng nó nếu còn nhờ code Objective-C
* Timer.publish --> tạo ra 1 publisher, sẽ phát ra các giá trị theo từng khoản thời gian cài đặt
* DispatchQueue.schedule --> Tương tự như Timer nhưng dùng DispatchQueue