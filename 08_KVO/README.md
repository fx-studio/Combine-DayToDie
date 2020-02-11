# Key Value Observing

Một chương thú vị tiếp nữa về Combine. Trong chương này là sự kết hợp của Code Combine và Non-Combine, bên cạnh đó có thêm phần code của Objective-C. Vì chỉ có Objective-C mới là cái nôi của KVO này. 

Ngoài ra, trong bài còn sẽ trình bày thêm các cách nhằm tối ưu hoặc đa năng thêm class của bạn. Để bạn ứng dụng vào KVO Parttern.

### 8.1. `publisher(for:options:)`

Bạn xem đoạn code sau:

```swift
let queue = OperationQueue()
  
  queue.publisher(for: \.operationCount)
    .sink { value in
      print("Outstanding operations in queue: \(value)")
  }
  .store(in: &subscriptions)
  
  queue.addOperation {
    print("add the 1st task")
  }
  
  queue.addOperation {
    print("add the 2nd task")
  }
```

Đoạn code trên nhằm giới thiệu tới bạn toán tử `publisher(for:options:)`. Nó:

* Biến đổi 1 property hoặc 1 object thành 1 publisher
* Không cần phải cài đặt thêm gì đối với các class có sẵn
* Tiếp tục với các code combine mà không ảnh hưởng gì nhiều

Giải thích:

* OperatorQueue : là 1 class tạo ra 1 queue để thực hiện các task được thêm vào. Nó trực thuộc Objctive-C
* Tạo publisher bằng toán tử trên, tiếp tục subscription với `sink`
* Vì liên kết thuộc tính `operationCount`, cứ mỗi lần add thêm 1 task vào queue thì nó sẽ đếm lên 1. Khi đó chúng ta sẽ biết đc lúc nào queue đó được thêm vào hay giải phóng task bằng `sink`
* Tiến hành thêm task vào và xem kết quả

### 8.2. Custom your class

Phần này, chúng ta sẽ tiến hành xào xáo lại class Non-combine của mình, nhằm biến nó thành `publisher` và có thể `subscription` tới các thuộc tính trong class đó.

Yêu cầu:

* class phải kế thừa `NSObject`
* proprety phải khai báo thêm tiền đố `@objc`

```swift
class User: NSObject {
    @objc dynamic var name: String = ""
  }
  
  let obj = User()
  
  obj.publisher(for: \.name)
    .sink { string in
      print("New name of user: \(string)")
  }
  
  obj.name = "Tèo"
  obj.name = "Tí"
  obj.name = "Tủm"
```

Giải thích:

* Khai báo class User như bao class khác, với việc kế thừa `NSObject`
* Khai baos tiếp property `name` với sãnh `@objc` và `dynamic`
* Tạo đối tượng `obj`
* Subscription đối tượng đó
* Thay đổi giá trị của thuộc tính name

Thêm nhiều thuộc tính vẫn OKE

```swift
class User: NSObject {
    @objc dynamic var name: String = ""
    @objc dynamic var age: Int = 0
  }
  
  let obj = User()
  
  obj.publisher(for: \.name)
    .sink { string in
      print("New name of user: \(string)")
    }
    .store(in: &subscriptions)
  
  obj.publisher(for: \.age)
  .sink { value in
    print("New age of user: \(value)")
  }
  .store(in: &subscriptions)
  
  obj.name = "Tèo"
  obj.name = "Tí"
  obj.name = "Tủm"
  
  obj.age = 10
  obj.age = 11
```

Tuy nhiên, không phải tất cả đều biến thành KVO đc

```swift
struct UserLocation {
    var city: String
    var address: String
  }
  
  class User: NSObject {
    @objc dynamic var name: String = ""
    @objc dynamic var age: Int = 0
    @objc dynamic var location: UserLocation = .init(city: "Đà Nẵng", address: "Cẩm Lệ")
  }
```

Ví dụ trên thì sẽ bị báo lỗi. Vì vậy, bạn cũng phải nên cẩn trọng khi sử dụng skill này để có đc KVO cho class của bạn.

### 8.3. Observation options

Giờ thì tới với tham số `options` còn thiếu, có 3 giá trị ở đây

* `.initial` phát đi giá trị lúc khởi tạo
* `.prior` phát đi cả 2 giá trị trước và giá trị mới khi có sự thay đổi
* `.old` & `.new` không có gì hết

Ví dụ

```swift
 let subscription = obj.publisher(for: \.integerProperty, options: [.prior])
```

### 8.4. ObservableObject

Team up giữa Combine & Non-Combine code cho vui. Sử dụng thêm 2 từ khoá nào:

* `ObservableObject` : các class có thể kế thừa nó
* `@Published` : khai báo thêm cho cho các thuộc tính để biến nó thành publisher

Mỗi khi có sự thay đổi giá trị của các thuộc tính thì với toán tử `objectWillChange` thì nó sẽ tạo ra 1 publisher để thông báo cho các subscriber biết có sự thay đổi. Buồn cái là nó không chỉ ra đích danh thèn nào thay đổi. Mà thôi biết thế là được rồi, chứ cả sãnh subscription như Objective-C thì toang mất.

Code ví dụ:

```swift
class MonitorObject: ObservableObject {
    @Published var someProperty = false
    @Published var someOtherProperty = ""
  }
  let object = MonitorObject()
  
  object.objectWillChange
    .sink {
      print("object will change: \($0)")
  }
  .store(in: &subscriptions)
  
  object.someProperty = true
  object.someOtherProperty = "Hello world"
```

### Tóm tắt

* KVO chủ yếu dựa vào Objective-C runtime và các giao thức của NSObject
* Một số class hệ thống được tích hợp sẵn trong các properties của nó
* Có thể custom các class với việc kế thừa `NSObject` và `@objc` cho các thuộc tính để có thể sử dụng KVO
* Kế thừa `ObservableObject` và `@Published` cho thuộc tính. Sử dụng `objectWillChange` để biết sự thay đổi của objecti (ko biết đc thuộc tính nào thay đổi)