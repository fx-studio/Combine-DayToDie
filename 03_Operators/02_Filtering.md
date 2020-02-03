## 2. Filtering Operators

Đôi khi vấn đề bạn gặp phải là có quá nhiều phần tử nhận được. Đôi lúc bạn muốn lọc bỏ bớt đi. Hoặc theo vào điều kiện mà sẽ lấy vài phần tử thích hợp... Và bây giờ tới với **Filtering Operators**, nó sẽ giúp bạn bớt đi những phiền não trên.

### 2.1. Filtering basic

Sử dụng toán tử `filter` để tiến hành lọc các phần tử được phát ra từ publisher. Dễ hiểu nhất là thử làm việc với 1 closure trả về giá trị `bool`. Xem ví dụ sau:

```swift
let numbers = (1...10).publisher
    
    numbers
        .filter { $0.isMultiple(of: 3) }
        .sink { n in
            print("\(n) is a multiple of 3!")
        }
        .store(in: &subscriptions)
```

Giải thích:

- Tạo 1 publisher từ 1 array Int từ 0 đến 10
- sử dụng toán tử `filter` với quy luật đặt ra là giá trị của numbers phải chi hết cho 3
- Khi đó các subcribers sẽ chỉ nhận được các giá trị mà được returm là `true` từ closure của filter

`removeDuplicates()`

Khi bạn nhận quá nhiều các giá trị giống nhau, thì cách đơn giản nhất để loại trừ chúng thì sử dụng toán tử sau:

```swift
 let words = "hey hey there! want to listen to mister mister ?" .components(separatedBy: " ")
        // 2
        .publisher
    words
        .removeDuplicates()
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
```

Chú ý: là chỉ remove đi các phần tử liên tiếp giống nhau mà thôi. 

Ví dụ:

* aabbbc -> abc
* aabbbca -> abca

### 2.2. Compacting & ignoring

#### `compactMap`

Nhiều publisher sẽ phát ra các giá trị là optional hoặc nil. Và bạn không muốn thay thế nó, chỉ muốn đơn giản là loại bỏ nó đi. Thì hay dùng toán tử `compactMap`. 

```swift
let strings = ["a", "1.24", "3", "def", "45", "0.23"].publisher

    strings
        .compactMap { Float($0) }
        .sink(receiveValue: {  print($0) })
        .store(in: &subscriptions)
```

Xem ví dụ trên thì bạn cũng sẽ tự hiểu ra. Hiểu đơn giản thì nó cũng như `map`, biến đổi các phần tử với kiểu giá trị này thành kiểu giá trị khác và lượt bỏ đi các giá trị không đạt theo điều kiện.

#### `ignoreOutput`

Xem đoạn code sau:

```swift
 let numbers = (1...10_000).publisher

    numbers
        .ignoreOutput()
        .sink(receiveCompletion: { print("Completed with: \($0)") }, receiveValue: { print($0) })
        .store(in: &subscriptions)
```

Với toán tử `ignoreOutput` , thì sẽ loại trừ hết tất cả các phần tử. Tới lúc nhận được `completion` thì sẽ kết thúc.

### 2.3. Finding values

#### `first(where:)`

Dùng để tìm kiếm phần tử đầu tiên phù hợp với yêu cầu đặt ra. Sau đó sẽ tự completion. Xem đoạn code sau:

```swift
let numbers = (1...9).publisher

  numbers
    .print("numbers")
    .first(where: { $0 % 2 == 0 })
    .sink(receiveCompletion: { print("Completed with: \($0)") },
          receiveValue: { print($0) })
    .store(in: &subscriptions)
```

* Ta có 1 array Int từ 0 đến 9 và biến nó thành 1 publisher.
* Sau đó dùng hàm `print` với tiền tố in ra là `numbers` --> để kiểm tra các giá trị có nhận được lần lượt hay ko?
* Sử dụng toán tử `first` để tìm giá trị đầu tiên phù hợp với điều kiện là chia hết cho 2
* Sau đó subscription nó và in giá trị nhận được ra.

Ta thấy khi gặp giá trị đầu tiền phù hợp điều kiện thì sẽ gọi `completion`. 

#### `last(where:)`

Đối trọng lại với `first`. Sẽ tìm ra phần tử cuối cùng được phát đi phù hợp với điều kiện. Miễn là trước khi có completion. Lại xem và thấu hiểu đoạn code sau:

```swift
let numbers = PassthroughSubject<Int, Never>()
  
  numbers
    .last(where: { $0 % 2 == 0 })
    .sink(receiveCompletion: { print("Completed with: \($0)") },
          receiveValue: { print($0) })
    .store(in: &subscriptions)
  
  numbers.send(1)
  numbers.send(2)
  numbers.send(3)
  numbers.send(4)
  numbers.send(5)
  numbers.send(completion: .finished)
```

Lần này sử dụng 1 subject để tiện phát theo ý mình. Bạn sẽ thấy giá trị in ra được là `4`. Và tất nhiên phải sau khi phát completion thì mới in được giá trị ra.

### 2.4. Dropping values

Các toán tử này sẽ giúp loại bỏ đi nhiều phần tử. Mà không cần quan tâm gì nhiều tới điều kiện. Chỉ quan tâm tới thứ tự và số lượng.

#### `dropFirst`

Xem đoạn code sau:

```swift
 let numbers = ["a","b","c","e","f","g","h","i","k","l","m","n"].publisher

    numbers
        .dropFirst(8)
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
```

Toán tử này sẽ có 1 tham số là số lượng các giá trị sẽ được bỏ đi. Với ví dụ trên thì phần tử thứ 9 sẽ được in ra, các phần tử trước nó sẽ bị loại bỏ đi.

#### `drop(while:)`

Toán tử này là phiên bản nâng cấp hơn. Khi bạn không xác định được số lượng các phần tử cần phải loại trừ đi. Thì sẽ đưa cho nó 1 điều kiện. Và trong vòng while, thì phần tử nào thoải mãn điều kiện sẽ bị loại trừ. Cho đến khi gặp phần tử đầu tiên không toản mãn. Từ phần tử đó trở về sau (cho đến lúc kết thúc) thì các subcribers sẽ nhận được các giá trị đó.

Ví dụ

```swift
let numbers = (1...10).publisher
  
  numbers
    .drop(while: {
      print("x")
      return $0 % 5 != 0
    })
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
```

Ưu điểm thì cách này có thể handle được các phần tử bị loại trừ. Tuy nhiên không thể nhận được chúng.

**Bây giờ có sự so sánh sự khác nhau giữa `filter` và `drop`**

* Điểm thứ 1: điều kiện
  * Filter : cho phép các giá tri thoải điều kiện được thông qua
  * Drop : bỏ qua các giá trị thoải điều 
* Điểm thứ 2: duyệt phần tử
  * Filter: sau khi thoải điều kiện thì các phần tử vẫn bị duyệt qua
  * Drop: sẽ dừng việc kiểm tra khi đã thoải điều kiện

#### `drop(untilOutputFrom:) `

Một bài toán được đưa ra như sau:

* Bạn tap liên tục vào một cái nút
* Lúc nào có trạng thái `isReady` thì sẽ nhận giá trị từ cái nút bấm đó

Code như sau:

```swift
	let isReady = PassthroughSubject<Void, Never>()
  let taps = PassthroughSubject<Int, Never>()
  
  taps
    .drop(untilOutputFrom: isReady)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
  
  (1...15).forEach { n in
    taps.send(n)
    
    if n == 3 {
      isReady.send()
    }
  }
```

Giải thích:

* `isReady` là 1 subject. Với kiểu Void nên chi phát tín hiệu chứ ko có giá trị được gởi đi
* `taps` là một subject với input là Int
* Tiến hành subcription `taps`, trước đó thì gọi toán tử `drop(untilOutputFrom:)` để lắng nghe sự kiện phát ra từ `isReady`
* For xem như là chạy liên tục, mỗi lần thì `taps` sẽ phát đi 1 giá trị
* Với n == 3, thì isReady sẽ phát

#### Tóm tắt cho `drop`

* `dropFirst` cho giá trị tĩnh
* `drop(while:)` cho điều kiện
* `drop(untilOutputFrom:)` cho một publisher

### 2.5. Limiting values

Ngược lại với `drop` thì toán tử `prefix` sẽ thực hiện ngược lại:

* `prefix(:)` Giữ lại các phần tử từ lúc đầu tiên tới index đó (với index là tham số truyền vào)
* `prefix(while:)` Giữ lại các phần tử cho đến khi điều kiện không còn thoải mãn nữa
* `prefix(untilOutputFrom:)` Giữ lại các phần tử cho đến khi nhận được sự kiện phát của 1 publisher khác

Xem ví dụ và chiêm nghiệm 

```swift
let numbers = (1...10).publisher
  
  numbers
    .prefix(2)
    .sink(receiveCompletion: { print("Completed with: \($0)") },
          receiveValue: { print($0) })
    .store(in: &subscriptions)
```

Giữa lại 2 phần tử đầu tiên nhận được, các phần tử còn lại thì bỏ qua

```swift
let numbers = (1...10).publisher
  
  numbers
    .prefix(while: { $0 < 7 })
    .sink(receiveCompletion: { print("Completed with: \($0)") },
          receiveValue: { print($0) })
    .store(in: &subscriptions)
```

Các phần tử đầu tiên mà bé hơn 7 thì sẽ được in ra. Từ phần tử nào thoải mãn điều kiện thì từ đó trở về sau sẽ bị skip

```swift
	let isReady = PassthroughSubject<Void, Never>()
  let taps = PassthroughSubject<Int, Never>()

  taps
    .prefix(untilOutputFrom: isReady)
    .sink(receiveCompletion: { print("Completed with: \($0)") },
          receiveValue: { print($0) })
    .store(in: &subscriptions)
  
  (1...15).forEach { n in
    taps.send(n)
    
    if n == 5 {
      isReady.send()
    }
  }
```

Các sự kiện `taps` sẽ nhận được liên tiếp, cho tới khi `isReady` phát.

> Với `untilOutputFrom` cho cả 2 toán tử `drop` và `prefix` thì được xem như là một **trigger**. Cái này sẽ rất là hữu ích sau này.

