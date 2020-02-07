# 3. Navigation

Đọc qua cái tên thì có thể bạn suy nghĩ đó là UINavigationController. Thì cái này không phải nha. Phần này sẽ tổng hợp các cách điều hướng View/ViewController cho các trường hợp chung nhất.

### 3.1. Presenting a view controller as a Future

Nó cũng tương tự cách bạn tạo `call back` bằng Future. Nếu bạn quên thì có thể quay lại phần 2 để đọc. Còn bây giờ công việc của chúng ta như thế nào?

Sẽ sử dụng 1 loại publisher đặc biệt là `AnyPublisher`. Loại này là loại chung chung, nó đã che dấu đi chi tiết về nó rồi. Bạn sẽ bắt đầu công việc như sau:

* Toạ một function để trả về `AnyPublisher`

```swift
func alert(title: String, text: String?) -> AnyPublisher<Void, Never> {
}
```

Bạn sẽ thấy, Input của publisher là `Void`. Nó có nghĩa thông báo lại là đã hoàn thành tác vụ hay là chưa.

* Implement code logic UI Controll

```swift
func alert(title: String, text: String?) -> AnyPublisher<Void, Never> {
    let alertVC = UIAlertController(title: title, message: text, preferredStyle: .alert)
   
  }
```

Đơn giản, cần gì thì tạo cái đó ra.

* Tạo 1 publisher là `Future`. Có vẻ tương lai này hot quá.

```swift
func alert(title: String, text: String?) -> AnyPublisher<Void, Never> {
    let alertVC = UIAlertController(title: title, message: text, preferredStyle: .alert)
    
    return Future { resolve in
      alertVC.addAction(UIAlertAction(title: "Close", style: .default, handler: { _ in
        resolve(.success(()))
      }))
      
      self.present(alertVC, animated: true, completion: nil)
    }.handleEvents(receiveCancel: {
      self.dismiss(animated: true)
    }).eraseToAnyPublisher()
  }
```

Future này cũng giống như cái bên phần 2. Ý nghĩa như thế này.

- Output của Future là 1 closue
- Bạn sẽ show alert ở đây, bên cạnh đó bạn cài đặt cho button `closure` với việc phát đi `success`
- Sử dụng toán tử `handleEvents` với tham số `receiveCancel`. Có nghĩa khi kết thúc Future thì sẽ `dismiss` alert.
- Cuối cùng, quan trọng nhất là `eraseToAnyPublisher` --> xoá đi dấu viết `Future`, biến nó thành 1 Publisher

Tiếp theo việc implement function đó như thế nào?

```swift
self.alert(title: "Error", text: error.localizedDescription)
            .sink { _ in
              // tự sướng trong này
          }
          .store(in: &self.subscriptions)
```

Khá là đơn giản phải không nào. Bạn có thể áp dụng tương tự với việc điều kiển các custom View.

### 3.2. Talking to other view controller

Việc điều hướng không phải là quan trọng nhất. Mà là sự tương tác giữa 2 View Controller khi điều hướng. Okay, mình sẽ cho 1 ví dụ đơn giản như sau để mô tả:

Cho ViewControlle A và B, trong A có functon goto tới B. Như thường lệ ta sẽ có

```swift
// A class
func gotoB() {
	let vc = B()
	
	self.navigationController?.pushViewController(vc, animated: true)
}
```

**Chúng ta sẽ có vấn đề đầu tiên là truyền dữ liệu từ A sang B.** 

Giải quyết cái này khá là đơn giản, bạn chỉ cần gán các giá trị cho các thuộc tính của B. Hoặc gọi function setup/config data cho B với đối số là các giá trị mà bạn muốn truyền từ A sang B

**Mọi việc sẽ phức tạp khi chiều truyền dữ liệu là từ B sang A.**

Trước đây, để giải quyết vấn đề này thì chúng ta sử dụng con trỏ.

> Tạo con trỏ A trong class B.

Nói cho nó sang chãnh chứ Swift thì dùng `Protocol` thôi, hay các delegate và datasouce. Rồi chúng ta tiến hoá lên việc `call back` bằng closure.

Vâng, tất cả vẫn là Non-Combine code. Giờ chúng ta đang ở trong thời đại mới rồi. Nên phải sử dụng được Combine Code vào để giải quyết vấn đề truyền dữ liệu này.

**Giải pháp như thế nào?**

Theo tư tưởng của Combine thì:

> B sẽ là publisher và A sẽ là subscriber

Nói thế chứ ai đời nào biến cả 1 UIViewController thành 1 publisher. Quá nhiều thứ dư thừa. Chúng ta chỉ cần dữ liệu nào cần thiết mà thôi. Cụ thể là chúng ta tạo ra các các `property` là các publisher.

Quay lại ví dụ giả tưởng trên, ta khai báo thêm các đoạn code sau trong class B:

```swift
private var selectedPhotosSubject = PassthroughSubject<UIImage, Never>()

var selectedPhotos: AnyPublisher<UIImage, Never> {
    return selectedPhotosSubject.eraseToAnyPublisher()
  }
```

* `selectedPhotosSubject` là 1 subject đóng vai trò lưu trữ và gởi dữ liệu đi. Nó cũng ko cần quan tâm ai subscribe tới nữa. Quan trọng là nó `private`
* `selectedPhotos` là một `AnyPublisher`, cái này giống như phát ngôn viên chính thức của class B về vấn đề lấy các ảnh
* `eraseToAnyPublisher` giúp cho việc biến đổi subject thành publisher

Và tại class B đó, muốn gởi dữ liệu đi thì thực hiện như sau:

```swift
self.selectedPhotosSubject.send(image)
```

Khi không muốn gởi gì hết đi, kết thúc câu chuyện tình này thì code như sau

```swift
selectedPhotosSubject.send(completion: .finished)
```

**Nhận dữ liệu như thế nào?**

Còn 1/2 câu chuyện nữa cần giải quyết. Tới đây thì bạn quay lại function gotoB tại Class A. Việc tiếp theo là bạn phải subscribe tới publisher của B. Xem tiếp ví dụ code

```swift
func gotoB() {
	let vc = B()
  
  let photos = vc.selectedPhotos
  
  newPhotos
    .map { 
      // Biến đổi thành dữ liệu mong muốn
    }
     // subscribe
    .assign(to: , on: )
    // lưu trữ
    .store(in: &subscriptions)
	
	self.navigationController?.pushViewController(vc, animated: true)
}
```

Bạn sẽ thấy:

* tạo 1 đối tượng tham chiếu tới publisher của B
* nếu cần biến đổi dữ liệu thì sử dụng `map`
* sau đó là `subscribe` , có thể dùng `assign` hoặc `sink`
* cuối cùng là lưu trữ

> Cài đặt trước các hành động, mọi thứ sẽ phản ứng lại đúng như ý đồ của chúng ta. Đó là tư tưởng code của Combine để giải quyết vấn đề này.

### 3.3. multiple subscriptions

Bạn hay nghe câu nói:

> Đời không như là mơ.

Thì cũng như code vậy, nó không đơn giản mỗi function thực hiện 1 nhiệm vụ. Hay 1 VC chỉ cần giải quyết 1 vấn đề. Mà đôi khi từ 1 dữ liệu chung, bạn cần phải giải quyết nhiều việc nữa. Quay về câu chuyện tình giữa A và B.

```swift
func gotoB() {
	let vc = B()
  
  let photos = vc.selectedPhotos
  
  // subscription #1
  newPhotos
    .map { ... }
    .assign(to: , on: )
    .store(in: &subscriptions)
  
  // subscription #2
  newPhotos
    .filter { ... }
    .assign(to: , on: )
    .store(in: &subscriptions)
	
	self.navigationController?.pushViewController(vc, animated: true)
}
```

Bạn thấy ta có 2 subscription cho publisher `selectedPhotos` của B. Vấn đề là bạn có thể đảm bảo tính toàn vẹn của publisher đó không. Khi có rất nhiều `operator` biến đổi được sử dụng

Việc này thì trong liệu sự của Apple rồi. Edit lại dòng code sau:

```swift
let newPhotos = photos.selectedPhotos.share()
```

Toán tử `share()` có đề cập trong phần operator. Khi đó thì nhiều subscription tới cùng 1 publisher và cũng cùng trỏ tới publisher gốc. Giúp publisher gốc  khi `emit` dữ liệu cho nhiều subscriber thì dữ liệu được giở đi an toàn hơn.

