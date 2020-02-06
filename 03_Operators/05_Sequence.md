# 5. Sequence Operators

Phần này hứa hẹn sẽ đơn giản. Các đối tượng thao tác sẽ là các array, collection, set ... Xử lý cho nhiều giá trị.

Chú ý:

* Input cuả publisher là 1 array

Vì vậy, chúng ta sẽ đi nhanh mà thôi.

### 5.1. Finding values

Tìm kiếm các giá trị đặc biệt. Tương tự như các function truyền thống của Swift.

#### `min`

Xem đoạn code sau:

```swift
let publisher = [1, -50, 246, 0].publisher

  publisher
    .print("publisher")
    .min()
    .sink(receiveValue: { print("Lowest value is \($0)") })
    .store(in: &subscriptions)
```

Quá đơn giản, nói chung là sẽ tìm đc giá trị nhất được phát đi. Và phải đợi lúc `completion` thì mới nhận được giá trị nhỏ nhất đó.

Tuy nhiên, đôi lúc nhiều thứ bạn không thể so sánh một cách đơn giản như vậy. Khi này ta dùng toán tử `min(by:)`

Xem code ví dụ sau:

```swift
let publisher = ["12345",
                   "ab",
                   "hello world"]
    .compactMap { $0.data(using: .utf8) } // [Data]
    .publisher // Publisher<Data, Never>

  publisher
    .print("publisher")
    .min(by: { $0.count < $1.count })
    .sink(receiveValue: { data in
      let string = String(data: data, encoding: .utf8)!
      print("Smallest data is \(string), \(data.count) bytes")
    })
    .store(in: &subscriptions)
```

Trong đó, 1 array String mà thì các phần tử trong đó khó so sánh. Nên

* dùng `compactMap` để biến đổi pulisher với Input là String thành publisher với Input là Data. Vai trò toán tử `compactMap` giúp loại bỏ đi các phần thử ko biến đổi được.
* `min(by:)` sẽ dùng một closure để kiểm tra số byte của 1 phần tử
* `sink` để subscribe và in ra giá trị như mình mong muốn

> Áp dụng thường xuyên có Input là các kiểu custom, class .... phức tạp

#### `max`

Tương tự như min, và cũng có 2 cách sử dụng cho 2 kiểu đối tượng (so sánh được ko so sánh đc).

Code ví dụ:

```swift
let publisher = ["A", "F", "Z", "E"].publisher

  publisher
    .print("publisher")
    .max()
    .sink(receiveValue: { print("Highest value is \($0)") })
    .store(in: &subscriptions)
```

#### `first`

Cái tên cũng hiểu rồi. Sẽ tìm kiếm giá trị đầu tiền được publisher phát ra. Và nó cũng sẽ kết thúc sau đó, cho dù publisher kia có phát tiếp theo bao nhiêu đi nữa.

Sau khi tìm kiếm được, thì tự động chuyển sang `canncel`.

Code ví dụ

```swift
let publisher = ["A", "B", "C"].publisher
  publisher
    .print("publisher")
    .first()
    .sink(receiveValue: { print("First value is \($0)") })
    .store(in: &subscriptions)
```

#### `first(where:)`

Để nâng cấp tìm kiếm thì có thể sử dụng toán tử `first(where:)`. Tha hồ mà tự sướng với em nó.

```swift
let publisher = ["J", "O", "H", "N"].publisher

  publisher
    .print("publisher")
    .first(where: { "Hello World".contains($0) })
    .sink(receiveValue: { print("First match is \($0)") })
    .store(in: &subscriptions)
```

Trong điều kiện của `where` thì tìm kiếm chữ cái đầu tiền chưa trong chuỗi string cho trước.

#### `last` & `last(where:)`

Tương tự như `first`. Nhưng ngược lại. Chỉ khi nào publisher phát đi completion, thì mới tìm kiến phần tử giá trị cuối cùng được phát ra.

```swift
let publisher = ["A", "B", "C"].publisher

  publisher
    .print("publisher")
    .last()
    .sink(receiveValue: { print("Last value is \($0)") })
    .store(in: &subscriptions)
```

#### `output(at:)`

Tìm kiếm phần tử theo chỉ định `index` trên upstream của publisher.

```swift
let publisher = ["A", "B", "C"].publisher

  publisher
    .print("publisher")
    .output(at: 1)
    .sink(receiveValue: { print("Value at index 1 is \($0)") })
    .store(in: &subscriptions)
```

Khi nhận được B ở index (1), thì sẽ in giá trị ra và tự kết liễu mình.

#### `output(in:)`

Để lấy ra 1 lúc nhiều phần tử ở nhiều index khác nhau thì. Thay vì cung cấp 1 giá trị đơn lẽ, có thể cung cấp 1 array thứ tự cho toán tử `output(in:)`

Xem code ví dụ sau:

```swift
 let publisher = ["A", "B", "C", "D", "E"].publisher

  publisher
    .output(in: 1...3)
    .sink(receiveCompletion: { print($0) },
          receiveValue: { print("Value in range: \($0)") })
    .store(in: &subscriptions)
```

Sẽ lấy các giá trị trong range là 1, 2 và 3 trong các giá trị được publisher phát đi.

### 5.2. Querying the publisher

Các toán tử trong phần Query sẽ không phát ra các giá trị cũng kiểu với Input của pubsliher nữa. Mà là các giá trị theo từng mục đích sử dụng của từng toán tử.

#### `count`

Nó chỉ thực hiện 1 lần, sau khi publisher kết thúc. Nhiệm vụ là đếm số lần mà publisher gởi đi các giá trị.

```swift
let publisher = ["A", "B", "C"].publisher

  publisher
    .print("publisher")
    .count()
    .sink(receiveValue: { print("I have \($0) items") })
    .store(in: &subscriptions)
```

#### `contains`

Chỉ phát ra `Bool` và kiểu của biến so sánh phải giống với Input của publisher

* true : tìm thấy đối lượng
* false : ko tìm thấy

```swift
example(of: "contains") {
  let publisher = ["A", "B", "C", "D", "E"].publisher
  let letter = "F"

  publisher
    .print("publisher")
    .contains(letter)
    .sink(receiveValue: { contains in
      print(contains ? "Publisher emitted \(letter)!"
                     : "Publisher never emitted \(letter)!")
    })
    .store(in: &subscriptions)
}
```

#### `contains(where:)`

Để nâng cao hơn điều kiện tìm kiếm cho các kiểu dữ liệu custom, class hoặc phức tạp hơn. 

```swift
// 1
  struct Person {
    let id: Int
    let name: String
  }

  // 2
  let people = [
    (456, "Scott Gardner"),
    (123, "Shai Mishali"),
    (777, "Marin Todorov"),
    (214, "Florent Pillet")
  ]
  .map(Person.init)
  .publisher

  // 3
  people
    .contains(where: { $0.id == 800 || $0.name == "Marin Todorov" })
    .sink(receiveValue: { contains in
      // 4
      print(contains ? "Criteria matches!"
                     : "Couldn't find a match for the criteria")
    })
    .store(in: &subscriptions)
```

Giải thích:

1. Define một struct dữ liệu là Person
2. Tạo 1 publisher với Input là Persion. Được biến đổi từ array chứa các tuple
3. Tiến hành kiểm tra xem có đối tượng là `800` và `Marin Todorov` hay ko?
4. subscription và in kết quả

#### `allSatisfy`

Toán tử này sẽ phát ra giá trị là `Bool` khi tất cả các giá trị của publisher thoả mãn điều kiện của nó.

Xem code ví dụ sau

```swift
// 1
  let publisher = stride(from: 0, to: 5, by: 2).publisher

  // 2
  publisher
    .print("publisher")
    .allSatisfy { $0 % 2 == 0 }
    .sink(receiveValue: { allEven in
      print(allEven ? "All numbers are even"
                    : "Something is odd...")
    })
    .store(in: &subscriptions)
```

Trong đó:

1. Tạo ra 1 publisher phát ra các giá trị từ 0 đến 5 với bước nhảy là 2. Nghĩa là 0, 2, 4
2. Kiểm tra điều kiện là tất cả giá trị của publisher đó đều chia hết cho 2 không

#### `reduce`

Toán tử này sẽ nhóm các giá trị lại với nhau của các giá trị mà publisher phát đi. Sau đó sẽ phát đi giá trị tổng hợp đó. Có nghĩa gom và làm giảm số lượng các giá trị của publisher kia.

Cần cung cấp cho nó giá trị ban đầu để nó thực hiện việc tổng hợp.

Ví dụ:

* bắt đầu cung cấp 0
* Nhận 1 -> 0 + 1 = 1
* Nhận 3 -> 1 + 3 = 4
* Nhận. 7 -> 4 + 7 = 11

Xem code ví dụ với String

```swift
// 1
  let publisher = ["Hel", "lo", " ", "Wor", "ld", "!"].publisher

  publisher
    .print("publisher")
    .reduce("") { accumulator, value in
    // 2
          accumulator + value
        }
    .sink(receiveValue: { print("Reduced into: \($0)") })
    .store(in: &subscriptions)
```

Trong đó:

1. Tạo publisher từ Array String 
2. thực hiện `reduce` các giá trị của publisher. Giá trị cung cấp đầu tiên là `""`. Công việc được thực hiện ở closure
3. Subscription và in kết quả

Có thể hay cả cloure bởi toán tử đơn giản hơn. Xem code ví dụ:

```swift
 let publisher = ["Hel", "lo", " ", "Wor", "ld", "!"].publisher

  publisher
    .print("publisher")
    .reduce("", +)
    .sink(receiveValue: { print("Reduced into: \($0)") })
    .store(in: &subscriptions)
```

### Tóm tắt

* Các publisher nên nhìn nhận đơn giản thì chúng cũng là các `sequence`. Do chúng phát ra các giá trị có cùng kiểu dữ liệu như nhau.
* Có thể tìm được `min` `max` trong số giá trị đc phát ra
* `first` & `last` tìm kiếm các giá trị đầu tiên hoặc cuối
* `first(where:)` & `last(where:)` cung cấp thêm điều kiện để tìm kiếm, nâng cao việc tìm kiếm với dữ liệu phức tạp
* `output(at:)` tìm giá tị với chỉ mục xác định
* `output(in:)` tìm các giá trị trong phạm vi của range
* Các toán tử sau phát ra giá trị với kiểu dữ liệu khác input của publisher
  * `contains` : trả về `Bool`, xác định 1 cái gì đó có trong các giá trị đc publisher phát ra hay ko
  * `contains(where:)` câu chuyện với kiểu dữ liệu của Input phức tạp lên
  * `allSatisfy` xác định tất cả các giá trị có thoả mãn 1 điều kiện nào đó hay ko
* `reduce` tích luỹ các giá trị được phát ra thành 1 giá trị duy nhất. Cùng kiểu dữ liệu với Input.

---

## HẾT

