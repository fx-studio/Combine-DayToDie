# 5. API

Về lý thuyết bài này đã được trình bài tại phần [Networking](././05_Networking) rồi. Nên bạn xem qua tại đó để nắm được các điểm cần thiết. Chúng ta cũng sử dụng URL lấy các bài hát mới nhất từ itune.

> Các này là cách sơ khai nhất, nên bạn đọc kĩ hướng dẫn trước khi sử dụng.

### 5.1. Models

Tạo các lớp Model dựa theo cấu trúc JSON và sử dụng `Codable Protocol` để phục vụ cho việc decode.

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

Ta có `FeedResust` có thuộc tính là `feed`, nó là kiểu dữ liệu `MusicResult`. Trong MusicResult lại có thuộc tính `results` là 1 array `Music`. Các đối tượng tượng Music lại có các property như trên.

Bạn cần chú ý là các tên của property trung với các key trong JSON trả về.

### 5.2. API Publisher

Nhiệm vụ hàng đầu của chúng là biến 1 núi công việc với kết quả trả về thành 1 publisher. Đơn giản phải không nào.

Tạo 1 function như thế này:

```swift
func fetchData() -> AnyPublisher<[Music], Error> {

}
```

Áp dụng kiến thức từ bài trước, chúng ta sẽ hoàn thành function này trong 1 nốt nhạc

```swift
func fetchData() -> AnyPublisher<[Music], Error> {
    let url = URL(string: ituneURL)!
    
    return URLSession.shared
      .dataTaskPublisher(for: url)
      .map(\.data)
      .decode(type: FeedResults.self, decoder: JSONDecoder())
      .mapError { $0 as Error }
      .map { $0.feed.results }
      .eraseToAnyPublisher()
  }
```

Trong đó:

* `dataTaskPublisher` tạo ra 1 publisher từ việc connect api
* `map` bỏ qua response, dùng mỗi `data`
* `decode` parse cho nhanh với kiểu `FeedResults` và dùng JSONDecoder
* `mapError` bắt error cho vui
* `map` tiếp lần nữa, vì muốn kết quả nhận được với publisher có output là Array Music
* `eraseToAnyPublisher` xoá sạch quá khứ

OKE, DONE. Sang phần sử dụng nào!

### 5.3. Subscription

Chuẩn bị 1 array để làm dữ liệu cho UITableView hay UICollectionView. Sử dụng `didSet` để reload.

```swift
var musics: [Music] = [] {
    didSet {
      self.tableView.reloadData()
    }
  }
```

Chuẩn bị 1 store lưu trữ các subscription. Nó sẽ tự giải phóng khi cả ViewController giải phóng.

```swift
private var subscriptions = Set<AnyCancellable>()
```

Tại function `viewDidLoad`, tiến hành subscription tới function `fetchData`. 

```swift
fetchData()
      .receive(on: DispatchQueue.main)
      .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
          print("❌ :  \(error.localizedDescription)")
        }
        }) { musics in
          self.musics = musics
        }
      .store(in: &subscriptions)
```

Trong đó:

* `receive` thực hiện ở `Main Queue`, nếu không sẽ crash app
* dùng `sink` để bắt đầy đủ `error` và `value`
  * show error
  * cập nhật giá trị cho array
* `store` để lưu trữ lại subscription

Cách thứ 2 là dùng `assign`

```swift
    fetchData()
      .receive(on: DispatchQueue.main)
      .catch{ _ in Empty() }
      .assign(to: \.musics, on: self)
      .store(in: &subscriptions)
```

Cách này đơn giản hơn, vì nó trực tiếp thay đổi tới thuộc tính của View Controller. Tuy nhiên, bạn phải trả 1 cái giá rất đắt là không handle được error. Vì với `assign` thì kết quả nhận được sẽ:

* Không bao giờ có lỗi
* Trả về rỗng

Tiếp tục update UI như bao lần code trước đây

```swift
//MARK: Tablebiew delegate & datasource
extension MusicViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    musics.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    
    let item = musics[indexPath.row]
    cell.textLabel?.text = item.name
    
    return cell
  }
  
}
```

---

Tới đây thì mình trình bày cách đơn giản nhất để bản có thể quẩy với Combine trong việc Fetch dữ liệu từ API và đưa nó lên UI của app bạn.