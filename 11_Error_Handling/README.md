# Error Handling

Các phần trước thì toàn bộ đều xử lý thành công. Chưa có trường hợp nào lỗi hay subscription mà nhận được complete là error. Phần này sẽ giải quyết hết cho bạn.

Trước tiên thì quan tâm lại chỗ cú pháp của 1 Publisher như thế nào:

> Publisher < Output, Failure >

Giờ chuyển hướng tấn công sang `Failure` nào!

## 11.1. Never

### Never

Nếu type của Failure là `Never` thì publisher của bạn không bao giờ lỗi. Bạn muốn dừng lại publisher đó khi nào gọi completion successfully.

Ví dụ:

```swift
Just("Hello")
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
```

Có gì khác lạ ở đây không nào?

> Combine + Xcode nó thông minh, sẽ suggestion bạn `sink` chỉ nhận value thôi. Vì ko có lỗi.

### `setFailureType`

Để thêm type cho `Failure` thì bạn dùng toán tử `setTypeFailure`. Xem code ví dụ cho Just trên.

```swift
Just("Hello")
    .setFailureType(to: MyError.self)
    .sink(receiveCompletion: { completion in
      
      switch completion {
      case .failure(.ahihi):
        print("Finished with Oh No!")
      case .finished:
        print("Finished successfully!")
      }
      
    }, receiveValue: { value in
      print("Got value: \(value)")
    })
    .store(in: &subscriptions)
```

Lúc này nên bạn dùng `sink` cho Just thì sẽ phải sử dụng function với phiên bản đầy đủ cho completion và value nhận được.

###  `assign(to:on:)`

Đây là cách để subscribe tới 1 publisher nhưng giá trị sẽ được đẩy thẳng về 1 property của 1 đối tượng. Cái này cũng sử dụng cho trường hợp không bao giờ lỗi.

```swift
// 1
  class Person {
    let id = UUID()
    var name = "Unknown"
  }

  // 2
  let person = Person()
  print("1", person.name)

  Just("Shai")
    .handleEvents( // 3
      receiveCompletion: { _ in print("2", person.name) }
    )
    .assign(to: \.name, on: person) // 4
    .store(in: &subscriptions)
```

Trong đó:

1. Định nghĩa class
2. Tạo đối tượng
3. Nhận sự kiện với completion. Do assign thì ko biết lúc nào nó kết thúc
4. assign gía trị tới property name của đối tượng

### `assertNoFailure`

Một pha bẻ lái nữa tới từ Combine. Nếu bạn muốn bảo vệ publisher của mình và đảm bảo rằng nó không thể fail thì sử dụng toán tử `assertNoFailure`. 

Khá buồn là nó không ngăn chặn được failure từ publisher, nhưng bù lại nó gây `crash` cho chương trình bằng `fatalError`. Moá, thâm vãi nồi!

```swift
Just("Hello")
    .setFailureType(to: MyError.self)
    //.tryMap { _ in throw MyError.ahihi }
    .assertNoFailure() // 2
    .sink(receiveValue: { print("Got value: \($0) ")}) // 3
    .store(in: &subscriptions)
```

Và khi cố gắng tiếp tục với `tryMap` để ném lỗi ra lại thì chương trình sẽ crash. Vì nó đã được nhận khai báo là không bao giờ lỗi nữa.

> Mợt mỏi với tụi này quá. Giờ sang phần chính thôi

## 11.2. Dealing with failure

### try* Operators

Đây là các toán tử bắt đầu với từ khoá `try` .Khá là thú vị, nhưng có thể giải quyết 1 thèn `tryMap` trước. Các thèn khác tương tự. Cũng vì các toán tử này thường ném đi ra 1 error.

Xem ví dụ cho cả 2

```swift
// define error 
enum NameError: Error {
    case tooShort(String)
    case unknown
  }
  
 // publisher
  let names = ["Scott", "Marin", "Shai", "Florent"].publisher
  
  // map
  names
    .map { value in
      return value.count
   }
  .sink(receiveCompletion: { print("🔵 Completed with \($0)") }, 
        receiveValue: { print("🔵 Got Value: \($0)") })
  .store(in: &subscriptions)
  
  // tryMap
  names
    .tryMap { value -> Int in
      
      let length = value.count
      
      guard length >= 5 else { throw NameError.tooShort(value) }
      
      return value.count
   }
  .sink(receiveCompletion: { print("🔴 Completed with \($0)") }, 
        receiveValue: { print("🔴Got Value: \($0)") })
  .store(in: &subscriptions)
```

### `mapError`

Chúng ta bắt đầu như sau:

```swift
enum NameError: Error {
    case tooShort(String)
    case unknown
  }
  
  Just("Hello")
    .setFailureType(to: NameError.self)
    .map { $0 + " World!" }
    .sink(receiveCompletion: { completion in
      
      switch completion {
      case .finished:
        print("Done!")
      case .failure(.tooShort(let name)):
        print("\(name) is too short!")
      case .failure(.unknown):
          print("An unknown name error occurred")
      }
      
    }, receiveValue: { print("Got value \($0)") })
    .store(in: &subscriptions)
```

Không có gì khó hiểu ở đây hết. Các error đều được bắt ở completion. Có điều bạn chú ý thì kiểu của completion lúc này là:

```swift
let completion: Subscribers.Completion<NameError>
```

Nó chỉ đích danh tới `NameError`. OKE, giờ ta đổi từ `map` thành `tryMap`.

```swift
Just("Hello")
    .setFailureType(to: NameError.self)
    //.map { $0 + " World!" }
    .tryMap { throw NameError.tooShort($0) }
    .sink(receiveCompletion: { completion in
      
      switch completion {
      case .finished:
        print("Done!")
      case .failure(.tooShort(let name)):
        print("\(name) is too short!")
      case .failure(.unknown):
          print("An unknown name error occurred")
      }
      
    }, receiveValue: { print("Got value \($0)") })
    .store(in: &subscriptions)
```

Lúc này thì xuất hiện lỗi ở trình biên dịch. Vì kiểu của completion lúc này đã khác rồi.

```swift
let completion: Subscribers.Completion<Error>
```

Như vậy nó sẽ quy các lỗi về lỗi chung chung của Swift. Điều này kiến chúng ta phải mệt mỏi trong việc xác định rõ lỗi thuộc loại gì và ở đâu?

Giải quyết tiếp với toán tử `mapError`.

```swift
Just("Hello")
    .setFailureType(to: NameError.self)
    //.map { $0 + " World!" }
    .tryMap { throw NameError.tooShort($0) }
    .mapError { $0 as? NameError ?? .unknown }
    .sink(receiveCompletion: { completion in
      
      switch completion {
      case .finished:
        print("Done!")
      case .failure(.tooShort(let name)):
        print("\(name) is too short!")
      case .failure(.unknown):
          print("An unknown name error occurred")
      }
      
    }, receiveValue: { print("Got value \($0)") })
    .store(in: &subscriptions)
```

OKE, mọi việc lại hoạt động ổn định. Qua đây ta thấy được `mapError` sẽ:

* bắt các error phát ra
* biến đổi nó về thành 1 kiểu chỉ định nào đó
* có thể ép kiểu của cả error

## 11.3. **Designing your fallible APIs**

Chúng ta sẽ bắt đầu bằng code của 1 class khá dài cho việc handle api với error

```swift
 class DadJokes {
  struct Joke: Codable {
    let id: String
    let joke: String
  }
  
  enum Error: Swift.Error, CustomStringConvertible {
    case network
    case jokeDoesntExist(id: String)
    case parsing
    case unknown

    var description: String {
      switch self {
      case .network:
        return "Request to API Server failed"
      case .parsing:
        return "Failed parsing response from server"
      case .jokeDoesntExist(let id):
        return "Joke with ID \(id) doesn't exist"
      case .unknown:
        return "An unknown error occurred"
      }
    }
  }
    
    // call api
    func getJoke(id: String) -> AnyPublisher<Joke, Error> {
      guard id.rangeOfCharacter(from: .letters) != nil else {
        return Fail<Joke, Error>(error: .jokeDoesntExist(id: id))
                .eraseToAnyPublisher()
      }
      
      let url = URL(string: "https://icanhazdadjoke.com/j/\(id)")!
      var request = URLRequest(url: url)
      request.allHTTPHeaderFields = ["Accept": "application/json"]
      
      return URLSession.shared
        .dataTaskPublisher(for: request)
      //.map(\.data)
        .tryMap { data, _ -> Data in
          guard let obj = try? JSONSerialization.jsonObject(with: data),
                let dict = obj as? [String: Any],
                dict["status"] as? Int == 404 else {
            return data
          }
          throw DadJokes.Error.jokeDoesntExist(id: id)
        }
        .decode(type: Joke.self, decoder: JSONDecoder())
        .mapError { error -> DadJokes.Error in
          switch error {
          case is URLError:
            return .network
          case is DecodingError:
            return .parsing
          default:
            return error as? DadJokes.Error ?? .unknown
          }
        }
        .eraseToAnyPublisher()
    }
    
  }
```

Trong đó phần define

* struct `joker` để define dữ liệu cho đối tượng sẽ dùng parse data trả về
* enum `Error` để định nghĩa các trường hợp error (cả chung lẫn riêng)
* `CustomStringConvertible` giúp cho việc sử dụng thân thiện error với `description`

```swift
func getJoke(id: String) -> AnyPublisher<Joke, Error> { ... }
```

function chính gọi API và trả về error. Phần đầu là tạo request từ URL. Trong đó ý nghĩa các toán tử như sau:

* `dataTaskPublisher` biến việc tương tác đó thành publisher
* `map()` để lấy phần data. Tuy nhiên với toán tử này thì mình sẽ không thấy được lỗi.
* `decode` sẽ parse data thành kiểu mình muốn thông qua JSONDecoder
* `mapError` sẽ bắt lỗi, biến lỗi thành kểu mình mong muốn để dễ quản lý. Vì lỗi có thể do nhiều nguyên nhân
  * URL
  * Connect thất bại
  * Parse JSON thất bại
  * Hoặc chung chung
* `eraseToAnyPublisher` xoá sạch dấu vết
* `tryMap` một số công việc sẽ có lỗi như parse JSON, nên sử dụng toán tử này. Ngoài ra, còn bắt trước một số lỗi nữa, như bài ví dụ là `status_code`
* `Fail` dùng để tạo ra 1 publisher mà ném đi `failure`

Sử dụng như bình thường

```swift
let api = DadJokes()
  let jokeID = "9prWnjyImyd"
  let badJokeID = "123456"
  // 5
  api
    .getJoke(id: badJokeID)
    .sink(receiveCompletion: { print($0) },
          receiveValue: { print("Got joke: \($0)") })
    .store(in: &subscriptions)
```

Hoán vị 2 cái `jokeID` và `badJokeID` để xem kết quả.