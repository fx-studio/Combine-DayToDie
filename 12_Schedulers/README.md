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

