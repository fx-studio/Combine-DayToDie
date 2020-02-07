# 4. Logic

Đây là phần sẽ triển khai logic. Với từng project thì yêu cầu chức năng sẽ khác nhau nên phần này chỉ lấy ví dụ của các phần trước để mô tả lại cho bạn hiểu cách hoạt động của các `operators` trong UIKit.

> Nếu bạn chưa nắm đc các operators thì cần phải đọc phần đó trước. Ở đây không đi tắt đón đầu đc.

### 4.1. Updating UI

Yêu cầu đưa ra:

* Chọn ảnh ở class B
* Class A sẽ lưu trữ các ảnh được chọn
* Cập nhật lại giao diện ở class A

Quay lại function huyền thoại kia.

```swift
func gotoB() {
	let vc = B()
  
  let photos = vc.selectedPhotos.share()
  
  // update title
  photos.$selectedPhotosCount
      .filter { $0 > 0 }
      .map { "Selected \($0) photos" }
      .assign(to: \.title, on: self)
      .store(in: &subscriptions)
  
  // publisher
  let newPhotos = photos.selectedPhotos.share()
  
  // store images
  newPhotos
    .map { ... }
    .assign(to: , on: )
    .store(in: &subscriptions)
  
  // update UI
    newPhotos
      .ignoreOutput()
      .delay(for: 2.0, scheduler: DispatchQueue.main)
      .sink(receiveCompletion: { [unowned self] _ in
        self.updateUI(photos: self.images.value)
      }) { _ in }
      .store(in: &subscriptions)
	
	self.navigationController?.pushViewController(vc, animated: true)
}
```

Chú ý đoạn code cho updateUI:

* `ignoreOutput` bỏ qua các giá trị nhận được, chỉ cần quan tâm tới sự kiện thôi
* `delay` để cập nhật UI và cập nhật trên Main Queue
* subscriber bằng `sink` với
  * Completion thì updateUI
  * Nhận value thì không làm gì hết
* `store` lại subscription

DONE!

### 4.2. **Accepting values while a condition is met**

Yêu cầu tiếp theo:

* Maximun là 6 ảnh 
* Nên nếu chọn hơn số lượng quy định thì sẽ bỏ qua việc thêm ảnh.

Xem code ví dụ

```swift
func gotoB() {
	let vc = B()
  
  let photos = vc.selectedPhotos.share()
  
  // update title
  photos.$selectedPhotosCount
      .filter { $0 > 0 }
      .map { "Selected \($0) photos" }
      .assign(to: \.title, on: self)
      .store(in: &subscriptions)
  
  // publisher
    let newPhotos = photos.selectedPhotos
      .prefix(while: { [unowned self] _ in
        return self.images.value.count < 6
    }) .share()
  
  // store images
  newPhotos
    .map { ... }
    .assign(to: , on: )
    .store(in: &subscriptions)
  
  // update UI
    newPhotos
      .ignoreOutput()
      .delay(for: 2.0, scheduler: DispatchQueue.main)
      .sink(receiveCompletion: { [unowned self] _ in
        self.updateUI(photos: self.images.value)
      }) { _ in }
      .store(in: &subscriptions)
	
	self.navigationController?.pushViewController(vc, animated: true)
}
```

Bạn chú ý đoạn code của Publisher `newPhotos`. Phải kiết thèn trùm, vì nó ảnh hưởng tới nhiều subscriber. Đơn giản, thêm toán tử `prefix` để fix chính sách số lượng giá trị nhận được. 

DONE!