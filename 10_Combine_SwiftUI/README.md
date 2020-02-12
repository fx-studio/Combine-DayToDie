# Combine vs. SwiftUI

## 10.1. Giới thiệu

SwiftUI là nền tảng mới mà Apple đưa ra. Phát triển ứng dụng thông qua việc khai báo giao diện. Đây là một sự thay đổi lớn kể từ UIKit.

### Declarative syntax

Bạn xem thử 1 đoạn code của SwiftUI

```swift
HStack(spacing: 10) { 
	Text("My photo") 
	Image("myphoto.png")
		.padding(20)
		.resizable()
}
```

Giao diện được khai báo và các phần tử trong giao diện cũng được khai báo. Các thuộc tính được sét theo các toán tử được gọi tiếp sau các UI Control.

Hai mô hình trên vốn khá rộng, thậm chí khá là mơ hồ nhưng để định nghĩa thì có thể gói gọn 1 cách tương phản rõ ràng như sau:

- **Imperative Programming**: nói với "machine" làm thế nào để giải quyết nó và kết quả bạn muốn là gì.
- **Declarative Programming**: nói với "machine" bạn muốn gì xảy ra và máy tính tính toán làm thế nào để làm ra nó.

Có rất nhiều lợi điểm mà Declarative mang lại, mình tạm thời xin phép không trình bày ở đây, Và theo xu thế thời đại đó là sự trỗi dậy của Declarative Programming và Apple cũng không đứng ngoài cuộc chơi này khi cung cấp cho bạn vũ khí lơi hại nhất:

> Combine + SwiftUI

### Cross-platform

Tham vọng của Apple rất là lớn. SwiftUI đưa ra không chỉ để giải quyết một vấn đề cho IOS mà nó nó sẽ đưa ra giao diện thích hợp cho toàn bộ nền tảng và các thiết bị trong hệ sinh thái của Apple.

> Code 1 lần, tự động chạy đẹp trên mọi thiết bị và mọi nền tảng.

### New memory model

Với UIKit thì bạn phải cần quản lý giữa dữ liệu của bạn với giao diện của bạn. Giữ cho chúng đồng bộ với nhau. View Controller sẽ đảm đương công việc kết nối đó.

Còn khi bạn sử dụng SwiftUI, thì sẽ có một cách tiếp cận mới trong việc quản lý giao diện. Lúc này bạn có thể nghỉ ngơi và tạm thời quên đi ViewController hay Controller nào đó. SwiftUI sẽ đảm đương công việc chính đó là `rendered` lại giao diện dưa theo dữ liệu của bạn.

Từ một nguồn dữ liệu chính, thì mọi sự biến đổi lên nó cũng sẽ tác động lên UI một cách tự động. Bạn sẽ liên tưởng tới gì, đó chính là các `publisher` sẽ tiến hành phát đi dữ liệu. Dữ liệu sẽ thay đổi dựa theo các `function` (hay toán tử) được cài đặt.

Công việc cuối cùng là bạn xây dựng nên 1 lớp trừu tượng cho giao diện của bạn sẽ như thế nào với dữ liệu. Phần còn lại các framework sẽ giải quyết.

Tóm lại:

* Ngừng việc suy nghĩ phải update lại UI sau mỗi lần tương tác
* Thiết kế UI sẽ ntn đối với dữ liệu
* Chăm sóc dữ liệu của bạn kĩ hơn

### Memory management

Dù muốn hay không muốn làm thì đây vẫn là công việc quan trọng nhất và chiếm nhiều tâm tư tình cảm vào nó. SwiftUI cho bạn một ý tưởng mới trong việc quản lý. Bạn không cần phải có 1 bản sao dữ liệu lưu trữ lên giao diện và phải tốn công sức duy trì cả 2.

> SwiftUI sẽ biến giao diện của bạn thành function cho trạng thái của model.

Với MVC truyền thống bạn sẽ thấy phải duy trì một lúc cả 3 nơi (View - ViewController - Model) cho cùng 1 dữ liệu. Ví dụ:

* Bạn có dữ liệu cho họ tên, nó sẽ lưu trữ ở Model của bạn dưới dạng String
* Còn giao diện của bạn sẽ phải lưu trữ dữ liệu đó trong thược tính `text` của một UILable dùng để hiển thị họ tên đó
* Ngoài ra, bạn phải cập nhất lại giá trị của `text` mỗi khi họ tên có sự thay đổi.

Phức cmn tạp! Và SwiftUI sẽ giải quyết việc đó. Và quá nhiều cho lý thuyết rồi, giờ sang phần chính là sử dụng Combine trong SwiftUI.

> Chi tiết về SwiftUI sẽ để ở một chương khác nha.

Một lần nữa mình xin phép sử dụng project mẫu từ Raywenderlich để mô tả trình bày và mô tả những gì xảy ra khi thao tác.

## 10.2. Managing view state

Như trình bày ở trên thì bạn sẽ thấy việc đầu tiên cần giải quyết là quản lý trạng thái của View. Và cũng như mọi lần lập trình trước đây, để View thay đổi trạng thái thì phải cần có sự tác động của người dùng vào giao diện. Như với UIKit thì bạn sẽ bắt lấy sự kiện trong IBAction, sau đó thay đổi dữ liệu lưu trữ rồi cuối cùng cập nhật lại giao diện.

Bên SwiftUI sẽ giống phần đầu tiên, là bắt lấy sự kiện, nhưng sự kiện này đã được khai báo kém theo UI rồi.

```swift
Button("Settings") {
          // Set presentingSettingsSheet to true here
          
        }
```

Nhấn vào button này thì sẽ present Setting View lên. Việc tiếp theo mà Setting View ẩn hay hiện thì cũng phải có chỗ điều khiển nó, nói đúng hơn là nó dựa vào nguồn đó để biết. Tiếp tục thêm dòng lệnh sao vào để khai báo 1 thuộc tính cho View hiện tại.

```swift
@State var presentingSettingsSheet = false
```

Từ khoá mới xuất hiện là `@State`, nó là gì?

* Đưa tầm ảnh hưởng của property đó ra khỏi View của nó
* Đánh dấu property đó lưu trữ dữ liệu cục bộ hay dữ liệu đó thuộc quyền quản lý của View
* Tạo thêm 1 `publisher`, tương tự như từ khoá `@Published`. Muốn gọi nó thì thêm `$` trước tên nó. Và cũng như bao publisher khác thì có thể subscribe hay binding dữ liệu lên UI.

Cuối cùng là cài đặt lên giao diện của bạn thay đổi trạng thái như thế nào đối với biên `@State` đó

```swift
List {
        Section(header: Text(filter).padding(.leading, -10)) {
          // ....
        }.padding()
      }
      // Present the Settings sheet here
        .sheet(isPresented: self.$presentingSettingsSheet, content: {
          SettingsView()
        })      
      )
    }
```

Tham khảo code trên. Và khi bạn swipe để dissmis View thì dữ liệu cũng sẽ cập nhật theo.

## 10.3. Fetching Data

Phần này là bạn bợ nguyên từ Networking và Combine vs. UKit : API

## 10.4. Using `ObservableObject`

Việc tiếp theo là làm sao View biết được Data Model của mình có sự thay đổi. SwiftUI và Combine cung cấp thêm cho bạn một `ObservableObject` protocol, biến nó thành nguồn phát. Nó sẽ tự động báo cho bạn biết sự thay đổi về dữ liệu chi các thuộc tính của nó với từ khoá khai báo kèm theo là `@Published`. Và toán tử để biết sự thay chung cho đối tượng của nó là `objectWillChange`

Bước 1: kế thừa

```swift
class ReaderViewModel: ObservableObject {
```

Bước 2: thêm @Published cho thuộc tính nào muốn phát

```swift
@Published private var allStories = [Story]()

@Published var error: API.Error? = nil
```

Bước 3: biến data model của bạn thành model dynamic

```swift
@ObservedObject var model: ReaderViewModel
```

Với `@ObservedObject` thì:

* Nó không còn là thuộc tính lưu trữ của View. Và dùng nó để binding dữ liệu tới dữ liệu gốc. Việc này tránh việc duplicate dữ liệu
* Nó trở thành external storage. View không còn là chủ nhân của nó nữa rồi
* Tương tự như @State, @Published thì nó là publisher và có thể subscribe

Quay về ví dụ, thì khi có khai báo thêm `@ObservedObject` thì bạn đã biến model của view thành model động. Khi nó hay các thuộc tính của nó update về mặt dữ liệu thì View sẽ biết được sự thay đổi đó và tiến hành render lại UI.

Tiếp theo, cho việc show alerrt lỗi, thì chỉ cần binding tới thuộc tính `error` của model là xong

```swift
.alert(item: self.$model.error, content: { error in
          Alert(title: Text("Network error"),
                message: Text(error.localizedDescription),
                dismissButton: .cancel())
        })
```

## 10.5. **Subscribing to an external publisher**

Khi bạn mệt mỏi với các ObservableObject hay ObservedObject ... và muốn quay về với các cách chân phương truyền thống. Và có 1 phương thức đặc biết trong các View của SwiftUI đó là `onRecive(_)`

Tại đó bạn có thể subscribe tới một publisher nào đó. Mà ko cần tới các cách rắc rối ở trên. Có thể nhiều View khác nhau thì sẽ `onRecive` khác nhau. Hiểu đơn giản, mỗi View có thể lắng nghe tới một publisher nào đó riêng biệt mà ko cần nhìn nhau.

Quay lại ví dụ trên

Bước 1: biến đổi `currentDate` thành kiểu `@State`. Để các UI sử dụng nó sẽ auto cập nhật dữ liệu mỗi khi nó được update

```swift
@State var currentDate = Date()
```

Bước 2: tạo publisher. Trong ví dụ sử dụng timer để tạo 1 vòng lặp thời gian

```swift
private let timer = Timer.publish(every: 10, on: .main, in: .common)
    .autoconnect()
    .eraseToAnyPublisher()
```

Bước 3: subscription

```swift
ForEach(self.model.stories) { story in
          // ...
   // Add timer here
  .onReceive(timer) {
     self.currentDate = $0
  }
}.padding()
```

Cứ sau thời gian cài đặt thì publisher sẽ phát đi dữ liệu. View sẽ nhận được và cập nhật lại giá trị của `currentDat`. Lúc này nó giống như 1 trigger để kích hoạt việc update giao diện.

## 10.6. **System environment**

Môi trường tác động lên app có rất nhiều thứ. Và với SwiftUI thì việc này là lợi thế thì có thể trực tiếp thay đổi UI theo môi trường. Công việc của bạn chỉ cần là cài đặt.

Ví dụ: biển đổi theo light hay dark theme của hệ thống.

Bước 1: khai báo biến môi trường có schemeColor

```swift
@Environment(\.colorScheme) var colorScheme: ColorScheme
```

Bước 2: sử dụng chỗ nào cần sự thay đổi này

```swift
.foregroundColor(self.colorScheme == .light ? .blue : .orange)
```

## 10.7. **Custom environment objects**

Đây mới chính là cái bạn cần phải quan tâm tiếp theo. Bạn có thể hiểu như là tạo ra 1 đối tượng singleton để dùng xuyên suốt toàn bộ project như với UIKit vậy. 

Từ khoá được sử dụng là `@EnvironmentObject`, ví dụ:

```swift
@EnvironmentObject var settings: Settings
```

Thì property setting tự động có được giá trị mới nhất từ môi trường. Và bạn có thể sử dụng nó, gởi nó qua nhiều View khác nhau. Có thể sử dụng trực tiếp hoặc subscribe hoặc binding lên View

> Đối với system environment thì chỉ cần key path trùng là oke.

Và khi bạn thay đổi dự liệu của biến môi trường tại một nơi nào đó. Toàn bộ các View có sử dụng cũng sẽ thay đổi theo. Quán trình này hoàn toàn tự động. Nên bạn không cần phải lo lắng với việc ngồi update hay call back hay observe cho tất cả tụi nó.

---

## Tóm tắt

* `@State` lưu trữ các trạng thái của View
* `@ObservedObject` phụ thuộc vào bên ngoài, từ 1 nguồn phát nào đó
* `ObservableObject Protocol` biến đối tượng thành nguồn phát
* `@Published` chỉ định các thuộc tính trở thành publisher và có thể bắt đc giá trị phát ra
* `.onReceive(_)` dùng để subscribe tới các publisher khác
* `@Environment` liên kết tới các thuộc tích môi trường của hệ thống (màu mè, font, datetime ...)
* `@EnvironmentObject` tự custom riêng thuộc tính môi trường với các đối tượng đc sử dụng qua nhiều View mà vẫn đảm bảo tính toàn vẹn của nó.