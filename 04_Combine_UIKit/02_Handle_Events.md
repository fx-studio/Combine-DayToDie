# 2. Handle Events

Sẽ liệt kê các cách tương tác với sự kiện người dùng trong Combine code. Có vài cái sẽ lặp bên khác.

### 2.1. Emit Data

Như đề cập bên phần 1, thì chúng ta không cần thiết phải custom lại action này. Vẫn giữ nguyên việc bắt sự kiện của UIKit thông qua IBAction.

Tại function đó, chúng ta chỉ cần sử dụng `publisher` phát đi một giá trị nào đó phù hợp với yêu cầu. Các chuỗi hành động khác sẽ xảy ra. Chúng đã được cài đặt trong các `subscription` rồi.

### 2.2. handleEvents

Đây là toán tử `handleEvents` của 1 `publisher` khi thực hiện `emit`. Bạn có thể lợi dụng nó để có những hành động khác diễn ra sau khi data được phát đi.

### 2.3. call back with Future

Đây là cách đơn giản để bạn có thể phản ứng lại sự kiện người dùng với Combine code, nhưng lại kết hợp được với Non-Combine code. Đó chính là sử dụng `Future`.

#### Tại sao?

* Đối tượng `Future` là một publisher
* Nó chỉ phải ra duy nhất 1 lần (có thể thành công hoặc thất bại)
* Có thể lợi dụng trong các function Non-Combine code của UIKit (các function lâu ni của chúng ta). Nhằm return về một đối tượng Future.

Các bước thực hiện như sau:

**Bước 1** : Cài đặt

Bạn xem 1 đoạn code ví dụ cho class PhotoWriter.

```swift
class PhotoWriter {
  enum Error: Swift.Error {
    case couldNotSavePhoto
    case generic(Swift.Error)
  }
  
  static func save(_ image: UIImage) -> Future<String, PhotoWriter.Error> {
    return Future { resolve in
      do {
        // thực hiện thao tác ở đây, nếu thành công
        resolve(.success("xxxxxx"))
      } catch {
        // thất bại với lỗi chung chung
        resolve(.failure(.generic(error)))
      }
    }
  }
  
}
```

Bạn sẽ thấy, PhotoWriter là một class như bao class bình thường khác mà bạn vẫn dùng lâu nay trong IOS. Công việc của bạn là sẽ viết 1 function với giá trị trả về là 1 publisher. 

Vì:

* Với publisher bạn có thể subscribe tại chỗ khác
* Phần code tương tác vẫn là Non-Combine code
* Giữ được cấu trúc lâu nay của project

Lựa chon `Future` vì bạn chỉ cần dùng nó 1 lần và không bận tâm gì tới hậu quả hay quán khứ. Tương lai mới quan trọng. Nó cần 2 giá trị:

* success
* failure

**Bước 2** : Subscribe

Tiếp tục ở 1 nơi nào đó, và bạn xem tiếp code ví dụ sau

```swift
@IBAction func actionSave() {
    guard let image = imagePreview.image else { return }
    
    PhotoWriter.save(image)
      .sink(receiveCompletion: { [unowned self] completion in
        if case .failure(let error) = completion {
          self.showMessage("Error", description: error.localizedDescription)
        }
        
        self.actionClear()
        
      }) { [unowned self] id in
        self.showMessage("Saved with id: \(id)")
      }
      .store(in: &subscriptions)
    
  }
```

Vẫn là hình ảnh quen thuộc với `IBAction`. Tại function này ta thực hiện việc gọi lệnh `save` ảnh. Vì function save trả về 1 publisher. Nên ta cần phải `subscribe` nó để xử lý.

Sử dụng `SINK` để subscribe nó. Quan tâm tới 2 closure `completion` và `value`. Future sẽ trả về 1 trong 2 đó. Tiếp tục handle các thao tác tương ứng với dữ liệu nhận được

Cuối cùng, là `store` lại subscription.

#### Có điều gì đặc biệt ở đây, khi mà bạn có thể return về 1 enum có success và failure?

Câu trả lời đó là:

> Bất đồng bộ.

Mình sẽ giúp bạn hồi tưởng bí thuật lại như thế này:

> Khi bạn xử lý 1 công việc theo kiểu bất đồng bộ. Thì mối quan tâm lớn nhất đó là nhận lại được kết quả.

* **Protocol** hay chính là Delegation Parttern là cái sẽ được ưu tiên sử dụng. Đơn giản nhưng không dễ hiểu. Đầu óc phải tưởng tượng ra một chút thì mới hình dung ra được luồng sự kiện di chuyển.
* **Closure** dùng làm tham số trong function. Với cái tên hay được đặt là `completion` hay `call back`. Dùng khá nhiều trong mô hình MVVM, phục vụ cho tương tác giữa View và ViewModel. Nó đơn giản hơn, dễ hiểu hơn và code xử lý tập trung đúng chỗ. Không suy nghĩ đau đầu về việc tìm cái đường di chuyển của nó.

Với **Combine** thì sao:

> Việc `call back` bây giờ chính là `emit data` 

