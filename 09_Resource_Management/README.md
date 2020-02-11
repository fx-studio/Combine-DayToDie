# Resource Management

Chắc phần này đơn giản, đơn giản vì chưa biết áp dụng hay xử lý code như thế nào. Có thể lúc bắt đầu tìm hiểu về Combine thì việc ưu tiên trước mắt là áp dụng nó vào project. Khi level đạt đủ mới tiến hành nâng cấp cũng như tối ưu thêm các xử lý hay tài nguyên.

Tập trung vào 2 toán tứ hay dùng:

* `share()`
* `multicast(_:)`

### 9.1. `share()`

Trong Combine hay Reactive Programming thì việc sử dụng các toán tử tác động lên publisher thì nó sẽ biến đổi publisher đó về mặc giá trị. Hay nó sẽ tác động lên stream. Vì vậy, thường qua vài lần sử dụng thì publisher mới giờ đã không còn như lúc ban đầu.

Toán tử `share()` giúp cho bạn tham chiếu tới 1 publisher. Đảm bảo tính nhất quán của publisher đó cho nhiều lần subscription.

Nó thuộc `Publishers.Share`

Xem lại ví dụ từ chương trước

```swift
let shared = URLSession.shared 
		.dataTaskPublisher(for: URL(string: "https://www.xvideos.com")!) 
		.map(\.data) 
		.print("shared") 
		.share()

print("subscribing first")
let subscription1 = shared
	.sink( receiveCompletion: { _ in },
  	receiveValue: { print("subscription1 received: '\($0)'") }
	)

print("subscribing second")
let subscription2 = shared
	.sink( receiveCompletion: { _ in },
  	receiveValue: { print("subscription2 received: '\($0)'") }
	)
```

Bần nhớ rằng, publisher của bạn sẽ ko thay đổi gì. Và các subscription tới thì sẽ hoạt động riêng biệt nhau. Đôi khi chúng có thể tương tác khác nhau và có thể request tài nguyên khác nhau. Ví dụ: như việc gọi đi gọi lại các connect tới api để lấy kết quả.

### 8.2. `multicast(_:)`

Toán tử này đã xuất hiện ở phần Networking. Nó giải quyết vấn đề tài nguyên cũng như cacher lại giá trị. Sau khi đã tiến hành cài đặt xong hết các subscription. Thì với toán tử `multicast` sẽ tạo ra 1 `ConnectablePublisher`. Việc của bạn sẽ là tiến hành gọi `connect` khi đó các subscribers sẽ đồng loạt nhận được cùng giá trị từ cùng 1 nguồn.

Ngoài ` connect` thì có `autoconnect` để tự động kích hoạt.

Code ví dụ:

```swift
let subject = PassthroughSubject<Data, URLError>()

let multicasted = URLSession.shared 
		.dataTaskPublisher(for: URL(string: "https://www.raywenderlich.com")!) 
    .map(\.data) 
		.print("shared") 
		.multicast(subject: subject)

let subscription1 = multicasted 
		.sink(receiveCompletion: { _ in }, receiveValue: { 
      print("subscription1 received: '\($0)'") 
    }
  )

let subscription2 = multicasted 
		.sink(receiveCompletion: { _ in }, receiveValue: { 
      print("subscription2 received: '\($0)'") 
    }
  )

multicasted.connect()

subject.send(Data())
```

Với `multicast` sẽ tạo ra 1 subject. Tiến hành `connect` thì sẽ thực thi và phát ra các giá trị tới các subscribers. Còn với `subject` kìa thì có thể phát ra giá trị và các subscriber vẫn nhận đc.

### 8.3. Future

Khi bạn mệt mỏi với đám publisher này và việc quản lý chúng. Thì `Future` đến với bạn như 1 giải phải

> Sống đơn giản cho đời thanh thản

* Cung cấp cho bạn 1 publisher
* Chỉ phát 1 lần duy nhất (có thể có giá trị hoặc lỗi)
* Lưu trữ lại kết quả và khi có subscription thì nó sẽ cung cấp

Code ví dụ:

```swift
let future = Future<Int, Error> { fulfill in
  do {
    let result = try performSomeWork()
		fulfill(.success(result)) 
		} catch {
			fulfill(.failure(error)) 
	 	}
}
```

### Tóm tắt

* Việc subscription nhiều sẽ dẫn tới việc tốn tài nguyên và khó quản lý. Nhất là các tác vụ đòi hỏi tài nguyên lớn.
* `share()` khi bạn chỉ cần share publisher cho nhiều subscribers
* `multicast` khi bạn muốn kiểm soát tốt publisher và các giá trị tới các subscribers
* `Future` đưa 1 kết quả tới cho nhiều subscriber và hết

