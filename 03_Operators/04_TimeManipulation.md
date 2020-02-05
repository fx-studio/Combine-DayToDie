## 4. Time Manipulation Operators

Phần này thì không còn thao tác đơn giản nữa. Phải xử lý đa luồng và life-time khác nhau. Các toán tử trong phần này sẽ giúp bạn thực hiện các việc đó. Tính ra sẽ là khá hữu dụng khi môi trường thao tác trên app là bất đồng bộ.

### 4.1. Delay

Toán tử `delay` sẽ tạo ra 1 publisher mới từ 1 publisher gốc. Cơ chết hoạt động rất đơn giản, khi publisher gốc phát đi 1 giá trị, thì sau khoảng thời gian cài đặt thì publisher delay sẽ phát cùng giá trị đó đi.

```swift
let valuesPerSecond = 1.0
let delayInSeconds = 1.5

// 1
let sourcePublisher = PassthroughSubject<Date, Never>()

// 2
let delayedPublisher = sourcePublisher.delay(for: .seconds(delayInSeconds), scheduler: DispatchQueue.main)

// 3
let subscription = Timer
  .publish(every: 1.0 / valuesPerSecond, on: .main, in: .common)
  .autoconnect()
  .subscribe(sourcePublisher)
```

* `sourcePublisher` là 1 subject
* `delayPublisher` được tạo ra nhờ toán tử `delay` của publisher trên
* Tiến hanhf subscription và cứ mỗi giây cho `sourcePublisher` phát đi
* Thì sau 1 khoản thời gian đc cài đặt trên thì `delayPublisher` sẽ phát tiếp

Đoạn code đơn giản dễ hiểu hơn

```swift
var subscriptions = Set<AnyCancellable>()

let valuesPerSecond = 1.0
let delayInSeconds = 2.0

let sourcePublisher = PassthroughSubject<Date, Never>()
let delayedPublisher = sourcePublisher.delay(for: .seconds(delayInSeconds), scheduler: DispatchQueue.main)

//subscription
sourcePublisher
    .sink(receiveCompletion: { print("Source complete: ", $0) }) { print("Source: ", $0)}
    .store(in: &subscriptions)

delayedPublisher
   .sink(receiveCompletion: { print("Delay complete: \($0) - \(Date()) ") }) { print("Delay: \($0) - \(Date()) ")}
   .store(in: &subscriptions)

//emit values by timer
DispatchQueue.main.async {
    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
        sourcePublisher.send(Date())
    }
}
```



### 4.2. Collecting values

```swift
func collect() {
    let valuesPerSecond = 1.0
    let collectTimeStride = 4

    let sourcePublisher = PassthroughSubject<Int, Never>()

    let collectedPublisher = sourcePublisher
            .collect(.byTime(DispatchQueue.main, .seconds(collectTimeStride)))
            .flatMap { dates in dates.publisher }
    
    //subscription
    sourcePublisher
        .sink(receiveCompletion: { print("\(Date()) - 🔵 complete: ", $0) }) { print("\(Date()) - 🔵: ", $0)}
        .store(in: &subscriptions)

    collectedPublisher
       .sink(receiveCompletion: { print("\(Date()) - 🔴 complete: \($0)") }) { print("\(Date()) - 🔴: \($0)")}
       .store(in: &subscriptions)
    
    DispatchQueue.main.async {
        var count = 1
        Timer.scheduledTimer(withTimeInterval: 1.0 / valuesPerSecond, repeats: true) { _ in
            sourcePublisher.send(count)
            count += 1
        }
    }
}
```

Ta theo dõi đoạn code trên để hiểu về toán tử `collect`

* Tạo 1 publisher từ 1 PassthroughSubject với Input là Int
* Tạo tiếp 1 publisher nữa từ publisher trên với toán tử `collect` 
* Tiến hành subscription 2 publisher để xem giá trị sau mỗi lần nhận được
* Cho vào vòng lặp vô tận để quan sát kết quả

Ta thấy

* Nếu không có `flatMap` thì cứ sau 1 khoản thời gian được cài đặt `collectTimeStride` thì các giá trị sẽ được thu tập. Và kiểu giá trị của nó là một Array
* Sử dụng `flatMap` để biến đổi chúng cho dễ nhìn hơn

Chúng ta tiếp tục nâng cấp thêm cho toán tử `collect` để tăng cường khả năng thu thập giá trị.

```swift
let collectedPublisher2 = sourcePublisher
        .collect(.byTimeOrCount(DispatchQueue.main, .seconds(collectTimeStride), collectMaxCount))
        .flatMap { dates in dates.publisher }
```

Ta chú ý điểm `byTimeOrCount`, có nghĩa là:

* Nếu đủ số lượng thu thập theo `collectMaxCount` --> thì sẽ bắn giá trị đi
* Nếu chưa đủ giá trị mà tới thời gian thu thập `collectTimeStride` thì vẫn gom hàng và bắn

> Khá là hay và linh hoạt trong thời buổi kinh thế khó khăn hiện nay.

### 4.3. Holding off on events

Bài toán hay gặp trong app là search. Thường sẽ là gõ tới đâu thì search tới đó. Nhưng đôi khi chờ 1 chút thời gian để xem ý đồ của người dùng là dừng lại hay gõ tiếp. Nếu họ gõ tiếp thì việc search các từ khoá chưa hoàn thành thì giống như bạn đêm lòng đi crush 1 cô mà cô ta chẵn hết biết tới.

Oke, chúng ta sẽ gỡ rối phần này với các toán tử sau:

#### `debounce`

Toán tử này cũng khá vui, nó có một số đặc điểm sau:

* publisher sử dụng nó thì sẽ tạo ra 1 publisher mới
* với với gian được set vào
* khi đủ thời gian thì publisher mới này sẽ phát ra giá trị, với gián trị là giá trị mới nhất của publisher gốc

Ta xem ví dụ sau

```swift
//data
    let typingHelloWorld: [(TimeInterval, String)] = [
      (0.0, "H"),
      (0.1, "He"),
      (0.2, "Hel"),
      (0.3, "Hell"),
      (0.5, "Hello"),
      (0.6, "Hello "),
      (2.0, "Hello W"),
      (2.1, "Hello Wo"),
      (2.2, "Hello Wor"),
      (2.4, "Hello Worl"),
      (2.5, "Hello World")
    ]
    
    //subject
    let subject = PassthroughSubject<String, Never>()
    
    //debounce publisher
    let debounced = subject
        .debounce(for: .seconds(1.0), scheduler: DispatchQueue.main)
        .share()
    
    //subscription
    subject
        .sink { string in
            print("\(printDate()) - 🔵 : \(string)")
        }
        .store(in: &subscriptions)
    
    debounced
        .sink { string in
            print("\(printDate()) - 🔴 : \(string)")
        }
        .store(in: &subscriptions)
    
    //loop
    let now = DispatchTime.now()
    for item in typingHelloWorld {
        DispatchQueue.main.asyncAfter(deadline: now + item.0) {
            subject.send(item.1)
        }
    }
```

* `typingHelloWorld` là để giả lập việc gõ bàn phím với kiểu dữ liệu là Array Typle gồm
  * Thời gian gõ
  * Ký tự gõ
* Tạo `subject` với Input là String
* Tạo tiếp debounce với time là `1.0` -> nghĩa là cứ sau 1 giây, nếu subject không biến động gì thì sẽ phát giá trị đi
* hàm `share()` để đảm bảo tính đồng nhất khi có nhiều subcriber subscribe tới nó
* Phần subscription để xem kết quả
* For và hẹn giờ lần lượt theo dữ liệu giả lập để `subject` gởi giá trị đi.

#### `throttle`

Toán tử điều tiết này cũng khá thú vị. Ta xem qua các đặc trưng của nó:

* Cũng từ 1 publisher khác tạo ra, thông qua việc thực thi toán tử `throttle`
* Cài đặt thêm giá trị thời gian điều tiết
* Trong khoảng thời gian điều tiết này, thì nó sẽ nhận và phát giá trị đầu tiên hay mới nhất nhận được từ publisher gốc (dựa theo tham số `latest` quyết định)

Xem đoạn code ví dụ sau:

```swift
//data
    let typingHelloWorld: [(TimeInterval, String)] = [
      (0.0, "H"),
      (0.1, "He"),
      (0.2, "Hel"),
      (0.3, "Hell"),
      (0.5, "Hello"),
      (0.6, "Hello "),
      (2.0, "Hello W"),
      (2.1, "Hello Wo"),
      (2.2, "Hello Wor"),
      (2.4, "Hello Worl"),
      (2.5, "Hello World")
    ]
    
    //subject
    let subject = PassthroughSubject<String, Never>()
    
    //debounce publisher
    let throttle = subject
        .throttle(for: .seconds(1.0), scheduler: DispatchQueue.main, latest: true)
        .share()
    
    //subscription
    subject
        .sink { string in
            print("\(printDate()) - 🔵 : \(string)")
        }
        .store(in: &subscriptions)
    
    throttle
        .sink { string in
            print("\(printDate()) - 🔴 : \(string)")
        }
        .store(in: &subscriptions)
    
    //loop
    let now = DispatchTime.now()
    for item in typingHelloWorld {
        DispatchQueue.main.asyncAfter(deadline: now + item.0) {
            subject.send(item.1)
        }
    }
```

* Ở giây thứ 0.0 thì chưa có gì mới từ `subject` và `throttle` bắt đầu sau 1.0 giây
* Tới thời điểm 1.0 thì có dữ liệu là `Hello` vì nó đc phát đi bởi `subject` ở 0.6
* Nhưng tới 2.0 thì vẫn ko có gì mới để `throttle` phát đi vì `subject` lúc đó mới phát Hello cách
* Tới thời điểm 3.0 thì `subject` đã có Hello world ở 2.5 rồi, nên `throttle` sẽ phát đc

####Tóm tắt

* `debounce` lúc nào source ngừng một khoảng thời gian theo cài đặt thì sẽ phát đi giá trị mới nhất
* `throttle` không quan tâm soucer dừng lại lúc nào, miễn tới thời gian điều tiết thì sẽ lấy giá trị (mới nhất hoặc đầu tiên trong khoảng thời gian điều tiết) để phát đi. Nếu ko có chi thì sẽ âm thầm skip

### 4.4. Timing out

Toán tử này rất chi là dễ hiểu, bạn cần sét cho nó 1 thời gian. Nếu quá thời gian đó mà publisher gốc không có phát bất cứ gì ra thì publisher timeout sẽ tự động kết thúc. 

Còn nếu có gía trị gì mới đc phát trong thời gian timeout thì sẽ tính lại từ đầu.

Xem đoạn code sau:

```swift
let subject = PassthroughSubject<Void, Never>()
    
    let timeoutSubject = subject.timeout(.seconds(5), scheduler: DispatchQueue.main)
    
    subject
        .sink(receiveCompletion: { print("\(printDate()) - 🔵 completion: ", $0) }) { print("\(printDate()) - 🔵 : event")}
        .store(in: &subscriptions)
    
    timeoutSubject
        .sink(receiveCompletion: { print("\(printDate()) - 🔴 completion: ", $0) }) { print("\(printDate()) - 🔴 : event")}
        .store(in: &subscriptions)
    
    print("\(printDate()) - BEGIN")
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        subject.send()
    }
```

Đơn giản là build lên vào xem. Tuy nhiên, nếu quá timeout thì sẽ sang completion là `finished`. Cái này có vẻ sai sai. Nên ta sẽ edit lại đoạn code trên để có thể gởi về `error`.

Khai báo thêm 1 enum để handler các error

```swift
enum TimeoutError: Error {
    case timedOut
}
```

Cài đặt lại code khởi tạo của publisher `timeout`

```swift
let subject = PassthroughSubject<Void, TimeoutError>()
    
let timeoutSubject = subject
			.timeout(.seconds(5), scheduler: DispatchQueue.main, customError: {.timedOut})
```

Mọi thứ còn lại không thay đổi gì. Run lại và xem kết quả đã đúng chuẩn chưa. 

### 4.5. Measuring time

Toán tử này thì đo lường thời gian khi có sự thay đổi trên publisher. Nói chung chưa thấy có ý nghĩa chi hết. Chắc ở các phần nâng cao.

Xem code ví dụ:

```swift
//data
    let typingHelloWorld: [(TimeInterval, String)] = [
      (0.0, "H"),
      (0.1, "He"),
      (0.2, "Hel"),
      (0.3, "Hell"),
      (0.5, "Hello"),
      (0.6, "Hello "),
      (2.0, "Hello W"),
      (2.1, "Hello Wo"),
      (2.2, "Hello Wor"),
      (2.4, "Hello Worl"),
      (2.5, "Hello World")
    ]
    
    //subject
    let subject = PassthroughSubject<String, Never>()
    //measure
    let measureSubject = subject.measureInterval(using: DispatchQueue.main)
    let measureSubject2 = subject.measureInterval(using: RunLoop.main)
    
    //subscription
    subject
        .sink { string in
            print("\(printDate()) - 🔵 : \(string)")
        }
        .store(in: &subscriptions)
    
    measureSubject
        .sink { string in
            print("\(printDate()) - 🔴 : \(string)")
        }
        .store(in: &subscriptions)
    
    measureSubject2
        .sink { string in
            print("\(printDate()) - 🔶 : \(string)")
        }
        .store(in: &subscriptions)
    
    
    //loop
    let now = DispatchTime.now()
    for item in typingHelloWorld {
        DispatchQueue.main.asyncAfter(deadline: now + item.0) {
            subject.send(item.1)
        }
    }
```

Giải thích:

* `subject` là 1 publisher với Input là String
* Tạo tiếp 2 publisher với toán tử `measureInterval`. Khách nhau ở
  * Trên main queue: thời gian thật với đơn vị thời gian là nano giây
  * Runloop trên main : thời gian trên main thread với đơn vị thời gian là giây
* Tiến hành subscription các publisher
* Loop để `subject` phát ra các giái trị

---

### Tóm tắt:

* `delay` : cứ sau 1 khoảng thời gian thì sẽ phát lại giá trị của publisher gốc
* `collect` : gôm các giá trị mà publisher gốc phát ra, rồi sẽ phát lại. Có 2 tiêu chí
  * theo thời gian chờ
  * theo số lượng cần gom
* `debounce` : lúc nào source ngừng một khoảng thời gian theo cài đặt thì sẽ phát đi giá trị mới nhất
* `throttle` không quan tâm soucer dừng lại lúc nào, miễn tới thời gian điều tiết thì sẽ lấy giá trị (mới nhất hoặc đầu tiên trong khoảng thời gian điều tiết) để phát đi. Nếu ko có chi thì sẽ âm thầm skip
* `timeout` : hết thời gian mà ko có giá trị nào được phát đi, thì auto kết thúc
  * Kết hợp thêm `error` để cho ngầu
* `measureInterval` : đo thời gian của publisher phát tín hiệu hoặc có sự thay đổi nào đó

---

## HẾT

