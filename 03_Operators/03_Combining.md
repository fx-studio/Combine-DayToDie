## 3. Combining Operators

Tới phần này thì thế giới sẽ không còn đơn giản nữa. Chúng ta sẽ giải quyết bài toán bằng kết hợp nhiều thứ lại với nhau. 

Ví dụ như bài toán login siêu kinh điển trong thế giới Reactive thì các username và password là các publisher. Chỉ khi nào đủ 2 giá trị thì mới tiến hành login đc.

Bắt đầu thôi!

### 3.1. Prepending

#### `prepend(Outupt...)`

Toán này cung cấp trước các giá trị cho 1 publisher. Và publisher sẽ phát các giá trị đó đi trước tiên. Sau đó mới tới các giá trị mà publisher phát. Về kiểu dữ liệu thì trùng với kiểu input của publisher.

```swift
let publisher = [3, 4].publisher
    
    publisher
        .prepend(1, 2)
        .prepend(-2, -1, 0)
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
```

Xem đoạn code trên ta thấy:

* Có thể gọi `prepend` nhiều lần
* Ko giới hạn số lượng giá trị truyền vào
* Cái sau sẽ in ra trước, nghĩa là:  -2 -> -1 -> 0 -> 1 -> 2 -> 3 -> 4

#### `prepend(Sequence)`

Tương tự như trên, lần này thay vì các giá trị riêng lẻ. Chúng ta sẽ ném cho nó 1 array hoặc set.

Xem code ví dụ sau:

```swift
let publisher = [5, 6, 7].publisher
  
  publisher
    .prepend([3, 4])
    .prepend(Set(1...2))
    .prepend(stride(from: 6, to: 11, by: 2))
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
```

#### `prepend(Publisher)`

2 toán tử trên thì bạn cần có dữ liệu có sẵn và không chủ động trong việc thay đổi. Còn với toán tử này sử dụng 1 publisher để chuẩn bị thì mọi việc có vẻ vui hơn. Chúng ta theo dõi đoạn code sau:

```swift
	let publisher1 = [3, 4].publisher
  let publisher2 = [1, 2].publisher
  
  publisher1
    .prepend(publisher2)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
```

Nhìn qua thì khá dễ hiểu. `publisher1` được chuẩn bị các giá trì từ `publisher2`. Nó sẽ in hết giá trị của publisher2 ra mới đến publisher1

Tiếp tục nào:

```swift
  let publisher1 = [3, 4].publisher
  let publisher2 = PassthroughSubject<Int, Never>()
  
  publisher1
    .prepend(publisher2)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)

  publisher2.send(1)
  publisher2.send(2)
  publisher2.send(completion: .finished)
```

Đoạn code này sẽ khá là huyền diệu khi `publisher2` bây giờ là 1 subject. Khi là subject thì nó có thể tuỳ ý phát giá trị.

Khi sử dụng `prepend` thì tới khi nào publisher trong tham số, có completion thì các giá trị của nó mới đc phát đi. Sau đó mới tới các giá trị của publisher chính.

Trong đoạn code đó, thì 1 và 2 sẽ được nhận được. Nếu ko có completion thì các giá trị 3 và 4 sẽ không được phát. 

> Toán tử này đọc qua thì rất là hay, nhưng ngẫm chưa ra áp dụng vào bài toán thực tiễn ntn. Chắc suy nghĩ sau.

### 3.2. Appending

Ngược lại với `prepend` thì `append` bổ sung các giá trị ra phía sau cùng cho publisher. Điều quan trọng là các giá trị đó sẽ được phát sau khi publisher phát đi completion.

Cũng có 3 kiểu toán tử

#### `append(Output)`

* Bổ sung thêm các giá trị cho trước vào sau cùng của publisher
* Cái add vào trước sẽ phát trước

```swift
let publisher = [1].publisher

  publisher
    .append(2, 3)
    .append(4)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
```

Thêm 1 ví dụ cho thấy việc các giá trị bổ sung sau chỉ được phát đi khi publisher đó phát đi completion

```swift
let publisher = PassthroughSubject<Int, Never>()

  publisher
    .append(3, 4)
    .append(5)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
  
  publisher.send(1)
  publisher.send(2)
  publisher.send(completion: .finished)
```

#### `append(Sequence)`

* Bổ sung thêm 1 array hay set các giá trị sau cùng

```swift
let publisher = [1, 2, 3].publisher
    
  publisher
    .append([4, 5])
    .append(Set([6, 7]))
    .append(stride(from: 8, to: 11, by: 2))
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
```

#### `append(Publisher)`

* Bổ sung thêm các giá trị của 1 publisher khác
* Cách này có thể xem như chống việc publisher gốc bị die. (Vui thôi, chứ ý nghĩa sử dụng nó sẽ khác)

```swift
	let publisher1 = [1, 2].publisher
  let publisher2 = [3, 4].publisher
  
  publisher1
    .append(publisher2)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
```

### 3.3. Advanced combining

Giờ chuyển sang các toán tử cao cấp hơn. Hứa hẹn sẽ giúp ích nhiều trong project hay các bài toán thực tiễn.

#### `switchToLastest`

Dùng trong trường hợp kết hợp nhiều publisher. Và bạn chỉ cần publisher nào cuối cùng phát ra giá trị thì nhận nó.

Xem đoạn code ví dụ sau:

```swift
	// 1
  let publisher1 = PassthroughSubject<Int, Never>()
  let publisher2 = PassthroughSubject<Int, Never>()
  let publisher3 = PassthroughSubject<Int, Never>()

  // 2
  let publishers = PassthroughSubject<PassthroughSubject<Int, Never>, Never>()

  // 3
  publishers
    .switchToLatest()
    .sink(receiveCompletion: { _ in print("Completed!") },
          receiveValue: { print($0) })
    .store(in: &subscriptions)

  // 4
  publishers.send(publisher1)
  publisher1.send(1)
  publisher1.send(2)

  // 5
  publishers.send(publisher2)
  publisher1.send(3)
  publisher2.send(4)
  publisher2.send(5)

  // 6
  publishers.send(publisher3)
  publisher2.send(6)
  publisher3.send(7)
  publisher3.send(8)
  publisher3.send(9)

  // 7
  publisher3.send(completion: .finished)
  publishers.send(completion: .finished)
```

Giải thích:

1. Tạo các publisher với Input là Int
2. Tạo 1 publisher để gọp các publisher kia, với Input chính là publisher với kiểu input là Int
3. sử dụng toán tử `switchToLastest` cho `publishers` và tiến hành subscription nó để in các giá trị nhận được
4. `publishers` send đi `publisher1` --> `publisher1` send đi 1 và 2 --> nhận được 1 & 2
5. `publishers` send đi `publisher2` --> 1 phát 3, không nhận đc 3 --> 2 phát 4 & 5, nhận đc 4 & 5
6. sau khi send `publisher3` đi thì 2 phát 6 sẽ ko nhận đc
7. gởi kết thúc

> Qua ví dụ trên thì chúng ta sẽ thấy với toán tự này chúng ta sẽ nhận được giá trị cuối cùng được gởi đi. Các giá trị của các publisher khác trước đó nếu phát ra thì sẽ không nhận được.

Đoạn code ví dụ cho việc áp dụng vào bài toán thực tiễn trong ứng dụng. Khi nhấn vào nút download thì sẽ download 1 image. Nếu như nhấn liên tiếp rất nhiều lần thì sẽ lấy cái cuối cùng. 

```swift
let url = URL(string: "https://source.unsplash.com/random")!

  // 1
  func getImage() -> AnyPublisher<UIImage?, Never> {
      return URLSession.shared
                       .dataTaskPublisher(for: url)
                       .map { data, _ in UIImage(data: data) }
                       .print("image")
                       .replaceError(with: nil)
                       .eraseToAnyPublisher()
  }

  // 2
  let taps = PassthroughSubject<Void, Never>()

  taps
    .map { _ in getImage() } // 3
    .switchToLatest() // 4
    .sink(receiveValue: { _ in })
    .store(in: &subscriptions)

  // 5
  taps.send()

  DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
    taps.send()
  }
  DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) {
    taps.send()
  }
```

Ví dụ trên với 3 lần gọi download ảnh. Nhưng sẽ đc chạy 2 lần. Lần thứ 2 bị cancel rồi.

#### `merge(with:)`

Cái này khá dễ hiểu. Nó chung bạn kết hợp nhiều publisher lại thành 1 publisher. Mỗi thèn trong đó cứ tự do phát và subcriber sẽ nhận được hết. Xem code ví dụ nha

```swift
	let publisher1 = PassthroughSubject<Int, Never>()
  let publisher2 = PassthroughSubject<Int, Never>()

  publisher1
    .merge(with: publisher2)
    .sink(receiveCompletion: { _ in print("Completed") },
          receiveValue: { print($0) }).store(in: &subscriptions)

  publisher1.send(1)
  publisher1.send(2)

  publisher2.send(3)

  publisher1.send(4)

  publisher2.send(5)

  publisher1.send(completion: .finished)
  publisher2.send(completion: .finished)
```

* Tạo ra 2 em publisher
* merge em 2 và em 1
* 2 em thay nhau bắn cho tới khi kết thúc
* Và khi nào cả 2 publisher kết thúc thì mới kết thúc chung

#### `combineLastest`

Với toán tử này thì bạn có thể làm được những điều sau:

* Kết hợp các publisher lại với nhau
* Nhận được một lúc cả 2 giá trị cuối cùng của mỗi publisher
* Giá trị nhận được là sự kết hợp từ các giá trị ở mỗi publisher

Oke, nghe qua thì cũng không hiểu mấy. Nên xem code ví dụ sau:

```swift
	// 1
  let publisher1 = PassthroughSubject<Int, Never>()
  let publisher2 = PassthroughSubject<String, Never>()

  // 2
  publisher1
    .combineLatest(publisher2)
    .sink(receiveCompletion: { _ in print("Completed") },
          receiveValue: { print("P1: \($0), P2: \($1)") })
    .store(in: &subscriptions)

  // 3
  publisher1.send(1)
  publisher1.send(2)
  
  publisher2.send("a")
  publisher2.send("b")
  
  publisher1.send(3)
  
  publisher2.send("c")

  // 4
  publisher1.send(completion: .finished)
  publisher2.send(completion: .finished)
```

Giải thích:

1. Tạo ra 2 publisher với các kiểu input lần lượt là Int & String
2. sử dụng toán tử `combineLastest` cho 2 publisher & subscription như bao lần trước đây
3. sử dụng publisher1 phát 1 và 2 -> ko có gì xảy ra. Vì publisher2 chưa có giá trị nào hết
4. Publisher2 bắn a & b -> nhận được 2,a và 2,b
5. publisher1 bắn 3 -> nhận đc 3,b
6. publisher2 bắn c -> nhận được 3,c
7. Kết thúc cả 2 cùng kết liễu.

#### `zip`

Đây là toán tử khá là thú vị, nó tương tự như kiểu Tuple trong Swift, bằng cách kết hợp nhiều kiểu giá trị lại với nhau. Còn trong Combine thì đó là sự kết hợp các Input của các publisher lại.

Với zip thì nó sẽ chờ nén từng cặp giá trị lại với nhau. Ví dụ:

* pub1 phát 1 & 2
* pub2 phát a & b
* nhận được 2 cái (1,a) & (2,b)

Khi nào đủ Input thì nó sẽ phát cho subscriber các cặp giá trị.

Code ví dụ:

```swift
  let publisher1 = PassthroughSubject<Int, Never>()
  let publisher2 = PassthroughSubject<String, Never>()

  publisher1
    .zip(publisher2)
    .sink(receiveCompletion: { _ in print("Completed") },
          receiveValue: { print("P1: \($0), P2: \($1)") })
    .store(in: &subscriptions)

  publisher1.send(1)
  publisher1.send(2)
  publisher2.send("a")
  publisher2.send("b")
  publisher1.send(3)
  publisher2.send("c")
  publisher2.send("d")

  publisher1.send(completion: .finished)
  publisher2.send(completion: .finished)
```

Giải thích thì đoạn code này mô tả ví dụ trên

### Tóm tắt

* `prepend` :  add thêm các giá trị vào trước
* `append` : add thêm các giá trị vào sau
* `prepend` & `append` có 3 biến thế
  * Nhiều giá trị tĩnh riêng lẽ
  * Array hay Set
  * Publisher (làm trigger)
* `switchToLastest` : chỉ quan tâm tới thèn cuối cùng trong nhiều thèn publisher
* `merge(with:)` : có bao nhiêu giá trị nhận được từ các publisher khác nhau thì hốt hết
* `combineLastest` : khi nào các publisher có đầy đủ giá trị cuối cùng, thì sẽ nhận được từng cặp giá trị cuối cùng đó. Miễn là cứ thèn nào phát trong số các thèn publisher đó phát giá trị đi thì nó sẽ nhận được.
* `zip` : kết hợp từng gặp giá trị lại với nhau, theo thứ tự và đủ số lượng. Không quan tâm thèn nào phát hoặc mặc kệ 1 thèn phát liên tiếp. Thì đủ cặp giá trị theo lần lượt sẽ nhận được. (ko biết diễn tả sao nữa)

---

## Hết

