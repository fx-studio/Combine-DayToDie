# 1. ViewController

Một số vấn đề sau khi sử dụng trong ViewController. Tất nhiên bạn cần tuân thủ theo nguyên tắt chung (tư tưởng của Combine)

> Mọi thứ sẽ được khai báo. Sự hoạt động là các đối tượng sẽ phản ứng lại hành động của người dùng. Hoặc tự biến đổi theo mục đích của người dùng cần.

### 1.1. `import`

Mặc dù Combine đã được Apple âm thầm gài gắm vào nhiều framework. Nhưng để sử dụng full tính năng của nó thì cần import đúng thư viện.

Mở file code nên là gõ

```swift
import Combine
```

OKE, DONE!

### 1.2. Subscriptions

Làm việc với app thì vấn đề đầu tiên đó là quản lý bộ nhớ. Với phong cách lập trình theo Reactive Programming của RxSwift hay Asynchronous Programming của Combine đó là quản lý các `subscriptions` của các subscribers tới các publisher.

Muốn quán lý chúng, bạn cần khai báo 1 property cho ViewController

```swift
private var subscriptions = Set<AnyCancellable>()
```

Đây là:

- Nơi lưu trữ các subscription của các subscriber
- Nó là kiểu `AnyCancellable` 
- Nghe cái tên là cũng tự hiểu rồi, nó sẽ auto release khi View Controller kết thúc vòng đời của nó.

Bạn sẽ sử dụng nó khi nào:

* Khi ViewController bị pop ra khởi navigationcontroller chứa nó
* Khi ViewController bị dismiss
* ...

> Để cho dễ liên tưởng thì bên RxSwift có anh chàng `disposebag` , thì cái này tương tự vậy.

### 1.3. Publishers

Đây chính là trái tim của toàn bộ ViewController. Ví dụ ViewController của bạn, lấy chủ thể là 1 tập các `images`. Các hành động của người dùng tương tác lên tập các `images` sẽ kéo theo các tác động khác tới nhiều đối tượng khác.

Lựa chọn ở đây thì bạn sẽ phải chọn kiểu của Publisher thuộc 1 trong 2 kiểu sau:

* **CurrentValueSubject**
  * u điểm của nó khi có subscription tới thì subscriber sẽ có ngay dữ liệu liền
  * Hiệu quả khi lưu trữ dữ liệu
  * cần cung cấp giá trị của Input ban đầu khi khai báo subject này
* **PassthroughSubject**
  * Ưu điểm là có cái gì là ném cái đó đi. Chứ không quan tâm phải gởi dữ liệu ngay từ đầu cho subscriber
  * Hiệu quả trong việc gởi các sự kiện hoặc call back
  * Không cần cung cấp giá trị ban đầu cho việc khai báo subject này

Cả 2 đều là subject. Nó có nhiều ưu điểm như sau:

* Lưu trữ đc dữ liệu
* Kết nối đc phần Combine code với Non-Combine code
* Có thể phát đi các giá trị theo mong muốn
* Nhiều subscriber có thể subscribe tới
* Tự do trong việc sử dụng kiểu dữ liệu cho Input
* Handle Error một cách dễ dàng

Ví dụ:

```swift
private let images = CurrentValueSubject<[UIImage], Never>([])
```

Một subject với Input là `Array [UIImage` và không bao giờ có lỗi. Phát giá trị của nó như thế nào?

```swift
// tạo dữ liệu mới
let newImages = images.value + [UIImage(named: "xxx.jpg")!]

// emit data
images.send(newImages)

// emit tiếp
images.send([])
```

Việc cuối cùng là bạn đặt nó ở đâu?

> Khi người dùng tác động vào app. Thì App sẽ phản ứng lại hành động của người dùng.

Theo trên thì bạn cần đặt các lệnh `emit data` ở các `IBAction` , đó là nói nhận sự kiện của người dùng. Và bạn chỉ cần quan tâm tới chủ thể `subject` chính của mình mà thôi.

Ví dụ:

```swift
@IBAction func actionAdd() {
    let newImages = images.value + [UIImage(named: "xxx.jpg")!]
    
    images.send(newImages)
  }

@IBAction func actionClear() {
    images.send([])
  }
```

> Tới đây, thì nhiều bạn sẽ liên tưởng tởi RxSwift hay họ hàng nhà Rx. Là nó có `button.tag` , còn Combine sao không có? Việc gì phải dùng nó ở `IBAction`?

Phần này mình xin phép không lý giải, nhưng bạn nên hiểu là bạn đang sử dụng Combine trên nên tảng nào. Với UIKit thì hay để UIKit quản lý các `action` của nó, còn Combine giúp bạn biến đổi thể giới còn lại.

Nếu bạn vẫn còn thấy ấm ức thì đợi vài phần nữa, mình sẽ tới `SwiftUI` thì khi đó mọi thứ sẽ được giải quyết.

### 1.4. Subscribe

Trước tiên nếu bạn chưa phân biệt đc các thuật ngữ sau:

* Subscribe
* Subscriber
* Subscription

Thì bạn nên dừng lại, mở lại phần đầu tiên để bổ túc thêm kiến thức.

Trong phần này, thì bạn sẽ giải quyết vấn đề chính khi dùng Combine trong ViewController. Các phần trên bạn sẽ thấy, publisher phát đi 1 giá trị. Và không có gì thay đổi trong ứng dụng của bạn hết. Muốn ...

> Muốn có sự thay đổi, thì bạn cần bắt được dữ liệu phát ra. Đó chính là việc subscribe tới các publisher trong View Controller.

#### Đặt nó ở đâu?

Xin thưa, hết 99.99% thì bạn phải đặc các đoạn code của `subscriber` ở `viewDidLoad`. Đó chính là nơi ViewController sẽ kích hoạt đầu tiên.

Xem ví dụ mẫu:

```swift
images
      .assign(to: \.image, on: imagePreview)
      .store(in: &subscriptions)
```

Trong ví dụ thì bạn sử dụng kiểu subscribe là `assign`. Khi bạn muốn thay đổi 1 thuộc tính của một đối tượng hay thực thể nào đó. Còn một cách khác là `sink` , khi bạn muốn để 1 đoạn code xử lý 1 vấn đề nào đó và nó nằm trong closure của `sink`.

Cuối cùng bạn nên nhớ là `store` cái subscribe đó lại.

#### Cần phải biến đổi kiểu dữ liệu nhận được

Bạn cũng biết món ăn ngon được thì phải cần chế biến đồ ăn, sau đó là nấu. Quá trình đó biến thịt cá .. thành các món đồ ăn thơm ngon bổ dưỡng. Nhân câu chuyện đó thì mình muốn nhắn gởi là:

> Phải có biến đổi dữ liệu và sẽ biến đổi nhiều lần để được dữ liệu mà mình mong muốn.

```swift
images
      .map { photos in
        // Đây là extention bọn nó viết giúp việc tạo ra 1 cái ảnh mới từ các ảnh trong array
        UIImage.collage(images: photos, size: collageSize)
      }
      .assign(to: \.image, on: imagePreview)
      .store(in: &subscriptions)
  }
```

Xem đoạn code trên thì bạn sẽ thấy toán tử `map`. Nó thuộc họ hành nhà Transforming Operator, chuyên đi biến đổi dữ liệu. Trong đoạn code trên thì khi `subject` phát đi 1 array image, nhưng chúng ta cần chính là 1 cái image mà thôi. Nên sẽ viết hàm biến đổ dữ liệu tại đó.

#### Phản ứng lại sự kiện của publisher

Phần trên là thao tác trên `luồng dữ liệu`. Tất nhiên, bạn còn phải thao tác với `luồng sự kiện` nữa. Và trong ứng dụng khi bạn tác động tới 1 UI Control trên giao diện thì có thể hành động đó của bạn sẽ gây ảnh hưởng tới rất nhiều UI Control khác.

Vì vậy, cần phải nắm được thời cơ mà dữ liệu có sự thay đổi. Thời cơ đó chính là lúc

> Subscriber nhận được giá trị đc phát ra bởi Publisher.

Xem tiếp code ví dụ

```swift
images
      .handleEvents(receiveOutput: { [weak self] photos in
        // Viết code ở đây 
        // hoặc
        // Gọi các function khác ở đây                            
      })
      // Biến đổi Input của subject là Array[UIImage] thành UIImage
      .map { photos in
        // Đây là extention bọn nó viết giúp việc tạo ra 1 cái ảnh mới từ các ảnh trong array
        UIImage.collage(images: photos, size: collageSize)
      }
      // Sử dụng ASSIGN để subscriber tới thuộc tính image của đối tượng `imagePreview`
      .assign(to: \.image, on: imagePreview)
      //lưu trữ subscription --> để auto huỹ
      .store(in: &subscriptions)
  }
```

Publisher cung cấp cho bạn toán tử `handleEvents` để phản ứng lại với các data được phát đi. Bạn nên lợi dụng nó thường xuyên hơn.

---

> Tạm thời như vậy là bạn đủ tự tin bỏ Combine vào trong ViewController rồi. Chắc chắn là có nhiều xử lý cao cấp hơn và chúng ta để dành nó cho phần sau nha.

