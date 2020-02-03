## 1. Transforming Operators

#### 1.1. publisher

Có nhiều function/method sẽ trả về 1 publisher và nó cũng gọi là operator. Các operator này giúp biến đổi một giá trị nào đó (có thể là Combine hoặc Non-Combine) để tạo thành một. `publisher`. Ví dụ sau:

```swift
["A", "B", "C", "D", "E"].publisher
```

Từ bây giờ, bạn sẽ làm quen nhiều tới việc biến đổi và biến đổi liên tục. Có nghĩa là đầu ra của 1 operator này là đầu vào của một operator khác.

#### 1.2. Collecting values

Tư tưởng lớn ở đây chính là khi bạn mệt mỏi khi phải làm việc với từng giá trị đơn riêng lẻ. Đôi lúc bạn muốn tổng hợp lại và xử lý nhanh gọn 1 lần nhiều giá trị. Thì các operator liên quan tới **collecting** sẽ giúp đỡ bạn.

Các dùng đơn giản, cầm đầu thèn publisher nào đó. và gọi function sau:

* Gôm hết các giá trị lại 1 lần

```swift
.collect()
```

* Gôm theo số lượng chỉ định

```swift
.collect(2)
```

> Về bản chất, nó cũng trả về là một **Publisher** mà thôi. Nên sau đó bạn có thể subscribe như bình thường.

#### 1.3. Mapping values

Đây là những toán tử chuyển đổi giá trị này thành giá trị khác, theo việc ánh xạ từ này sang kia & dựa theo một luật nào đó mà mình đặt ra. 

Ví dụ: Có 1 danh sách tên học sinh, mỗi cái tên ứng với một loài hoa -> sau khi biến đổi thì ta có 1 danh sách các loài hoa.

##### `.map(_:)`

```swift
let formatter = NumberFormatter()
formatter.numberStyle = .spellOut

    [22, 7, 2020].publisher
        .map {
            formatter.string(for: NSNumber(integerLiteral: $0)) ?? "" }
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
```

Giải thích:

* Tạo ra một formatter của Number. Nhiệm vụ nó biến đổi từ số thành chữ
* Tạo ra 1 `publisher` từ một array Integer
* Sử dụng toán tử `.map` để biến đối tường giá trị nhận được thành kiểu `string`
* Các toán tử còn lại thì như đã trình bày các phần trước rồi

##### Map key paths

Ngoài ánh xạ trực tiếp tới đối tượng thì họ hàng nhà `map` cho thêm 3 phiên bản như sau:

```swift
map<T>(_:)
map<T0, T1>(_:_:)
map<T0, T1, T2>(_:_:_:)
```

Với T là đại diện cho các giá trị được tìm thấy bởi key paths. Các T0, T1. T2 là đại diện cho các giá trị tới các thuộc tính dựa theo key path. Hiện tại, theo tra cứu document Apple thì nó chỉ có 3 thôi.

Chúng ta xem ví dụ sau:

Tạo 1 struct toạ độ

```swift
public struct Coordinate {
  public let x: Int
  public let y: Int
  
  public init(x: Int, y: Int) {
    self.x = x
    self.y = y
  }
}
```

Một function kiểm tra xem nó thuộc góc phần tư thứ mấy trong hệ toạ độ gốc (0,0) hoặc ở biên

```swift
public func quadrantOf(x: Int, y: Int) -> String {
  var quadrant = ""
  
  switch (x, y) {
  case (1..., 1...):
    quadrant = "1"
  case (..<0, 1...):
    quadrant = "2"
  case (..<0, ..<0):
    quadrant = "3"
  case (1..., ..<0):
    quadrant = "4"
  default:
    quadrant = "boundary"
  }
  
  return quadrant
}
```

Đến nhân vật chính là `map`

```swift
   //1
    let publisher = PassthroughSubject<Coordinate, Never>()
    
    //2
    publisher
        //3
        .map(\.x, \.y)
        .sink { (x, y) in
            //4
            print("The coodinate at (\(x), \(y)) is in quadrant", quadrantOf(x: x, y: y))
    }
        .store(in: &subscriptions)
    
    publisher.send(Coordinate(x: 10, y: -8))
    publisher.send(Coordinate(x: 0, y: 5))
```

Giải thích:

1. tạo 1 publisher với kiểu là PassthroughSubject với Input là Coordinate và không bao giờ lỗi.
2. `map(_, _)` dùng map để ánh xạ tới 2 thuộc tính x và y của đối tượng input nhận được
3. subscribe và tiến hành kiểm tra -> sau đó in giá trị ra

##### `tryMap`

Khi bạn làm những việc liên quan tới nhập xuất, kiểm tra, media, file ... thì hầu như phải sử dụng `try catch` nhiều. Nó giúp cho việc đảm bảo chương trình của bạn không bị crash. Tất nhiên, nhiều lúc bạn phải cần biến đổi từ kiểu giá trị này tới một số kiểu giá trị mà có khả năng sinh ra lỗi. Khi đó bạn hãy dùng `tryMap` như một cứu cánh.

Khi gặp lỗi trong quá trình biến đổi thì tự động cho vào `completion` hoặc `error` . Bạn vẫn có thể quản lí nó và không cần quan tâm gì tới bắt `try catch` ...

Xem ví dụ sau:

```swift
Just("Đây là đường dẫn tới file XXX nè")
        .tryMap { try FileManager.default.contentsOfDirectory(atPath: $0) }
        .sink(receiveCompletion: { print("Finished ", $0) },
              receiveValue: { print("Value ", $0) })
    .store(in: &subscriptions)
```

Giải thích:

* Just là 1 publisher, sẽ phát ra ngay giá trị khởi tạo
* sử dụng `tryMap` để biến đổi input là `string` (hiểu là đường dẫn của 1 file nào đó) thành đối tượng là `file` (data)
* Trong closure của `tryMap` thì tiến hành đọc file với đường dẫn kia
* Nếu có lỗi (trong trường hợp ví dụ) thì sẽ nhận được ở `completion` với giá trị là `failure`

OKE, rất khoẻ phải không nào. Giờ thì yêu Combine cmnr!

##### `flatMap`

Trước tiên thì ta cần hệ thống lại một chú về em `map` và em `flatMap`

* `map` là toán tử biến đổi 1 phần tử ngày thành 1 phần tử khác. Ví dụ: Int -> String...
* `flatMap` là toán tử biến đổi 1 `publisher` này thành 1 `publisher` khác
  * Mới hoàn toàn
  * Khác với thèn publisher gốc kia

Thường sử dụng `flatMap` để truy cập vào các thuộc tính trong của 1 publisher. Để hiểu thì bạn xem minh hoạ đoạn code sau:

Trước tiên tạo 1 struct là `Chatter`, trong đó có `name` và `message`.  Chú ý, message là một `CurrentValueSubject`, nó chính là `publisher`.

```swift
public struct Chatter {
    public let name: String
    public let message: CurrentValueSubject<String, Never>
    public init(name: String, message: String) {
        self.name = name
        self.message = CurrentValueSubject(message)
    }
}
```

Ta tạo các đối tượng sau, là 2 nhân vật sẽ tham gia đàm thoại với nhau

```swift
let teo = Chatter(name: "Tèo", message: " --- TÈO đã vào room ---")
let ti = Chatter(name: "Tí", message: " --- TÍ đã vào room ---")
```

Tạo room chát là một publisher với `PassthroughSubject` với Input là `Chatter` và ko bao giờ lỗi. Tiến hành subscribe nó. Nhưng trước tiên là phải sử dụng `flatMap` để biến đổi pulisher với kiểu input `Chatter` thành publisher với kiểu input `String`. Chúng ta chỉ subscribe publisher String đó thôi.

```swift
let chat = PassthroughSubject<Chatter, Never>()
    
    chat
        .flatMap { $0.message }
        .sink { print($0) }
        .store(in: &subscriptions)
```

OKE, chát thôi

```swift
//let's go chat
    
    //1 : Tèo vảo room
    chat.send(teo)
    //2 : Tèo hỏi
    teo.message.value = "TÈO: Tôi là ai? Đây là đâu?"
    //3 : Tí vào room
    chat.send(ti)
    //4 : Tèo hỏi thăm
    teo.message.value = "TÈO: Tí khoẻ không."
    //5 : Tí trả lời
    ti.message.value = "TÍ: Tao không khoẻ lắm. Bị Thuỷ đậu cmnr mày."
    
    let thuydau = Chatter(name: "Thuỷ đậu", message: " --- THUỶ ĐẬU đã vào room ---")
    //6 : Thuỷ đậu vào room
    chat.send(thuydau)
    thuydau.message.value = "THUỶ ĐẬU: Các anh gọi em à."
    
    //7 : Tèo sợ
    teo.message.value = "TÈO: Toang rồi."
```

Bạn run code vào xem kết quả. Mình sẽ giải thích như sau:

* `chat` là 1 publisher, chúng ta send các giá trị của nó đi (Chatter). Đó là các phần tử được join vào room
* Vì mỗi phần tử đó có thuộc tính là 1 publisher (messgae). Nên khi subscribe nếu không dùng `flatMap` thì sẽ ko nhận được giá trị từ các stream của các publisher join vào trước.
* `flatMap` giúp cho việc hợp nhất các stream của các publisher thành 1 stream và đại diện chung là 1 publisher mới với kiểu khác các publisher kia.
* Tất nhiên, khi các publisher riêng lẻ send các giá trị đi, thì `chat` vẫn nhận được và hợp chất chúng lại cho subcriber của nó.

Cuối câu chuyện bạn cũng thấy là `THUỶ ĐẬU` đã join vào. Vì vậy, muốn khống chế số lượng publisher thì sử dụng thêm tham số `maxPublishers` 

```swift
     chat
        .flatMap(maxPublishers: .max(2)) { $0.message }
        .sink { print($0) }
        .store(in: &subscriptions)
```

OKE, em nó đã bị cấm cửa. Nếu không có giá trị `max` thì nó tương đường với `unlimited`.

##### Tạm kết cho `MAP`

* `map` dùng để biến đối giá trị này thành giá trị khác (kiểu giá trị)
* Map key paths : dùng để biến đổi các thuộc tính của 1 đối tượng, thành cái gì đó mới hoặc cho vui cũng được
* `tryMap` dùng để biến đổi như map, nhưng sử dụng vào với các kiểu dữ liệu có nguy cơ sinh ra lỗi. Auto chúng sẽ vào `completion`
* `flatMap` dùng để biến đổi 1 publisher này thành 1 publisher khác. Bên cạnh đó còn quản lí các stream của các publisher trong đó. Hiểu nôm na là hợp nhất các stream thành 1 steam và khống chế số lượng các steam lắng nghe.

#### 1.4. Replacing upstream output

Cái này nghe cái tên thì cũng đoán ra được ít nhiều phần nào rồi. Đôi khi một số kiểu dữ liệu cho phép việc vắng mặt giá trị (Optional) hoặc khi giá trị là `nil`. Combine cung cấp cho chúng ta các toán tử để thay thế như sau

##### `replaceNil(with:)`

```swift
["A",  nil, "B"].publisher
        .replaceNil(with: "-")
        .sink { print($0) }
        .store(in: &subscriptions)
```

Đơn giản là publisher phát ra giá trị nào nil thì sẽ thay thế bằng giá trị nào đó được chỉ định. Tuy nhiên chúng sẽ là kiểu Optional và muốn code sạch đẹp hơn thì bạn phải khử Optional đó. Ví dụ:

```swift
["A",  nil, "B"].publisher
        .replaceNil(with: "-")
        .map({$0!})
        .sink { print($0) }
        .store(in: &subscriptions)
```

##### `replaceEmpty(with:)`

Khi mà publisher không chịu phát gì hết thì sao? Khi đó toán tử `replaceEmpty` sẽ chèn thêm giá trị nếu pulisher không phát đi bất cứ gì mà lại complete.

```swift
let empty = Empty<Int, Never>()
    // 2
    empty
        .replaceEmpty(with: 1)
        .sink(receiveCompletion: { print($0) },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
```

#### 1.5 `scan(_:_:)`

Chuyển đổi từng phần tử trên upstream của publisher. Bằng cách cung cấp phần tử hiện tại là một closure với giá trị cuối cùng kèm theo.

Nghe qua thì khá mơ hồ, tạm thời bạn qua ví dụ sau:

```swift
let pub = (0...5).publisher
    
    pub
        .scan(0) { $0 + $1 }
        .sink { print ("\($0)", terminator: " ") }
        .store(in: &subscriptions)
```

Giải thích:

* Tạo 1 publisher bằng cách biến đổi 1 array integer từ 0 tới 5 thông qua toán tử `publisher`
* Biển đổi từng phần tử của `pub` bằng toán tử `scan` với giá trị khởi tạo là `0`
* Scan sẽ phát ra các phần tử mới bằng cách kết hợp 2 giá trị lại
* Cái khởi tạo là đầu tiên -> cái nhận được là thứ 2 -> cái tạo ra mới đc phát đi và trở thành lại cái đầu tiên.