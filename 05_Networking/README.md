# Networking

Cũng tới được phần mà bạn sẽ sử dụng khá nhiều. Tương tác với các API và Webservice để lấy dữ liệu phục vụ cho app thì là điều hầu như thiết yếu trong bất cứ ứng dụng nào. Phần này sẽ nặng về lý thuyết và các cách để bạn tương tác. Demo mang tính chất chung chung mà thôi và xoay quanh 2 thực thể:

* URLSession
* JSON

> Bắt đầu thôi!

### 5.1 URLSession extension

```swift
let ituneURL = "https://rss.itunes.apple.com/api/v1/us/apple-music/coming-soon/all/10/explicit.json"
var subscriptions = Set<AnyCancellable>()

func demo1() {
  guard let url = URL(string: ituneURL) else { return }
  
  URLSession.shared
    .dataTaskPublisher(for: url)
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
          print("Retrieving data failed with error \(error)")
        }
      }) { data, response in
      print("Retrieved data of size \(data.count), response = \(response)")
    }.store(in: &subscriptions)
}
```

Chúng ta bắt đầu với demo thứ nhất, xử lý đơn giản cho việc tương tác với một API. Giải thích:

* `ituneURL` và `subscriptions` dùng để chuẩn bị. Các bài trước bạn đã đọc qua chúng khá nhiều rồi
* `URLSession.shared` để sử dụng đối tượng mà nó cung cấp (là 1 singleton)
* `dataTaskPublisher` là dạng nâng cấp của `dataTask` lúc xưa. Apple đã cung cấp nó để tăng cường sức mạnh của class này để nó có thể dùng tốt với reactive programming.
  * Nó tạo ra 1 publisher là chính
* Công việc tiếp theo của mình là subscribe tới publisher đó. thông qua `sink`
  * `completion` sẽ có 1 trong 2 trạng thái là `success` hoặc `failure`
  * `value` sẽ nhận được 2 đối số là `data` và `response`
* `store` lại subscription đó vào sãnh AnyCancelable để dễ bề thủ tiêu

> Đó là cách đơn giản đầu tiên

### 5.2. Codable support

Thời đại 4.0 này thì việc parse bằng tay thì quả thật kinh khung. Nên Apple nó cũng support tới phần việc này cho bạn rồi. Sử dụng `Foudation` framework, có support cho JSON về `JSONEncoder` và `JSONDecoder`.

Trước tiên bạn có phải thiết kế lại dữ liệu cho phù hợp

```swift
struct Music: Codable {
  var name: String
  var id: String
  var artistName: String
  var artworkUrl100: String
}

struct MusicResults: Codable {
  var results: [Music]
  var updated: String
}

struct FeedResults: Codable {
  var feed: MusicResults
}
```

Cái này tuỳ thuộc vào mỗi api với cấu trúc json khác nhau. Chú ý phải kế thừa protocol `Codable`. OKE, tiếp tục với function gọi API.

```swift
func demo2() {
  guard let url = URL(string: ituneURL) else { return }
  
  //1 create subscription
  URLSession.shared
    .dataTaskPublisher(for: url)
    .tryMap({ data, _ in
      try JSONDecoder().decode(FeedResults.self, from: data)
    })
    .sink(receiveCompletion: { completion in
      if case .failure(let error) = completion {
        print("Retrieving data failed with error \(error)")
      }
    }) { object in
      let items = object.feed.results
      for item in items {
        print("\(item.id) - \(item.name)")
      }
  }.store(in: &subscriptions)
}
```

Bạn sẽ thấy chút thay đổi sau:

* `tryMap` đây là toán tử biến đổi dữ liệu `Data` thành 1 đối tượng `FeedResults`. Vì nó có thể gây lỗi nên cần phải dùng `try`
* Vẫn là subscribe như thưởng với `sink`. Nhưng lần này `vaule` nhận được là 1 object với kiểu là `FeedResults` rồi

Tất nhiên chúng ta không dừng lại đây, tiếp tục nâng cấp đoạn code của mình.

```swift
  URLSession.shared
    .dataTaskPublisher(for: url)
//    .tryMap({ data, _ in
//      try JSONDecoder().decode(FeedResults.self, from: data)
//    })
    .map(\.data)
    .decode(type: FeedResults.self, decoder: JSONDecoder())
    .sink(receiveCompletion: { completion in
      if case .failure(let error) = completion {
        print("Retrieving data failed with error \(error)")
      }
    }) { object in
      let items = object.feed.results
      for item in items {
        print("\(item.id) - \(item.name)")
      }
  }.store(in: &subscriptions)
```

* Không sử dụng `tryMap` chuyển sang dùng `decode` là 1 toán tử mà Combine cung cấp cho bạn.
* Khá đơn giản khi bạn chỉ cần cung cấp các đối số phù hợp. Còn lại Combine sẽ giải quyết hết.
* Trước `decode` thì phải dùng `map` vì `dataTaskPublisher` phát ra 1 tuple (data, response). Mà chúng ta cần sử dụng mỗi `data` thôi

### 5.3. multiple subscribers

Vấn đề tiếp theo chắc gặp nhiều lần rồi. Là có 1 cái link mà phải gọi đi gọi lại nhiều lần. Như vậy sẽ tốn tài nguyên và bộ nhớ của máy. 

* Toán tử `share()` có thể giải quyết. Nhưng bạn cần phải hoàn thành và setup xong tất cả các subscriber trước khi nhận được data. Điều này thì khá hên xui đó à.

Giải pháp ở đây sử dụng toán tử `multicast`

* Lưu trữ lại 
* Tạo ra 1 subject `ConnectablePublisher`, để phát ra giá trị
* Cho phép nhiều subscriber subscribe vào trước khi gọi `connect`

Xem code ví dụ sau:

```swift
func demo3() {
  guard let url = URL(string: ituneURL) else { return }
  let publisher = URLSession.shared
    .dataTaskPublisher(for: url)
    .map(\.data)
    .multicast { PassthroughSubject<Data, URLError>() }
  
  //1
  publisher
    .sink(receiveCompletion: { completion in
      if case .failure(let err) = completion {
        print("Sink1 Retrieving data failed with error \(err)")
      }
    }, receiveValue: { object in
      print("Sink1 Retrieved object \(object)")
    })
    .store(in: &subscriptions)
  
  //2
  publisher
    .sink(receiveCompletion: { completion in
      if case .failure(let err) = completion {
        print("Sink2 Retrieving data failed with error \(err)")
      }
    }, receiveValue: { object in
      print("Sink2 Retrieved object \(object)")
    })
  .store(in: &subscriptions)
  
  // connect
  publisher.connect().store(in: &subscriptions)
}
```

* `multicast` sẽ biến đổi cái gì đó thành 1 subject với kiểu là `PassthroughSubject<Data, URLError>`
* tiến hành nhiều `subscribe` tơí subject
* `connect` sau khi đã sắp xếp hết các subscriber

---

