/// Hai thư viện đầu tiên cần import
import Foundation
import Combine

/// Tạo support code: Mở thanh Navigation > Chọn Sources > New File > add code vào
example(of: "test playground") {
    print("Hello, I am not Superman.")
}

/// Không biết là gì như đoán chắc là cái sẽ dùng huỹ các đối tượng publishers và subcribers
var subscriptions = Set<AnyCancellable>()

/// PUBLISHERS
/*
    - Trung tâm trái team của Combine
    - Sử dụng Publisher Protocol
    - Là nguồn phát ra các giá trị
 */

/*
 Nếu bạn là coder iOS thời kì trước thì có sự liên tưởng tới `NotificationCenter`. Và đúng như vậy, hiện tại nó có 1 function tên là `publisher(for:object:)`. Khá vui phải không nào.
 */
example(of: "Publisher") {
    //1
    let myNotification = Notification.Name("fxNotification")
    
    //2
    let publisher = NotificationCenter.default.publisher(for: myNotification, object: nil)
    
    //3
    let center = NotificationCenter.default
    
    //4
    let observer = center.addObserver(forName: myNotification, object: nil, queue: nil) { (notification) in
        print("Notification received!")
    }
    
    //5
    center.post(name: myNotification, object: nil)
    
    //6
    center.removeObserver(observer)
}
/*
 Giải thích trên 1 chú:
 1: tự define 1 notification với tên tự đặt
 2: tạo ra 1 publisher bằng function của NotificationCenter --> ví dụ thèn cha nào khác là ngớ ngẫn, khi không dùng tới nó
 3: Sử dung 1 đối tượng default của NotificationCenter
 4: Tạo 1 observer để lắng nghe 1 notification với tên ở trên và 1 closure để tương tác khi nhận được
 5: post 1 notification
 6: remove lăng nghe ra (cực kì quan trọng nha)
 */

/*
 LƯU Ý ĐẦU ĐỜI CHO 1 PUBLISHER
 - Có thể không phát ra giá trị hay nhiều giá trị
 - Tồn tại 3 kiểu: bình thường, completion và error
 - Nếu là completion hay error thì không thể phát thêm được nữa
 */


/// SUBSCRIBER
/*
 - Một Subcriber được tạo ra từ 1 Subcriber Protocol và yêu cầu cung cấp cho nó 1 kiểu dữ liệu.
 - Kiểu này là Output của Publisher.
 - Lưu ý là phải có Subcriber thì Publisher mới phát ra được sự kiện chưa giá trị mong muốn
 */
example(of: "Subcriber") {
    let myNotification = Notification.Name("fxNotification")
    
    let publisher = NotificationCenter.default.publisher(for: myNotification, object: nil)
    
    let center = NotificationCenter.default
    
    //SINK
    let subscription = publisher.sink { _ in
        print("FxNotification received from a publisher!")
    }
    
    //POST
    center.post(name: myNotification, object: nil)
    center.post(name: myNotification, object: nil)
    center.post(name: myNotification, object: nil)
}
/*
 Giải thích ví dụ trên:
 - Vẫn thiết kế như trên, nhưng lần này chúng ta sẽ sử dụng đối tượng Publisher vừa được tạo ra
 - Tạo 1 Subscription từ publiser đó
 - Tạo 1 Subcriber theo kiểu SINK --> tức là dùng 1 closure để xử lý giá trị nhận được
 - Bản chất của ví dụ:
    - Vẫn là NotificationCenter phát ra sự kiện
    - Lần này thì publisher phát và có sự lắng nghe
    - Xử lý giá trị được phát --> print
 */

/*
 SINK
 - là 1 operator tạo ra 1 Subcriber
 - Hiểu vậy cho nhanh
 */

/// Tiếp 1 ví dụ khác nữa
example(of: "Just") {
    //1
    let just = Just("Hello world")
    
    //2
    _ = just
        .sink(receiveCompletion: {
            print("Received completion", $0)
        }, receiveValue: {
            print("Received value", $0)
        })
    
    //3
    _ = just .sink(
      receiveCompletion: {
        print("Received completion (another)", $0)
      },
      receiveValue: {
        print("Received value (another)", $0)
    })
}
/*
 Giải thích ví dụ trên:
 1: Just là class có sẵn của Combine & Tạo ra 1 publisher
 2: Tạo 1 biến mà cũng ko cần quản lý nó nên chơi dấu `_` --> là 1 subcriber bằng cách gọi hàm `.sink(::)`
 3: Tạo thêm 1 cái nữa
 
 - sink đó có nhiều closure cho nhiều tham số
     - nhận được 1 giá trị bình thường
     - nhận được 1 completion
 - có thể tạo nhiều subcribers để cùng lắng nghe tới 1 publisher
 */

/*
 ASSIGN(TO:ON)
 - Một cách khác để có subcriber
 - Cho mình gán giá trị nhận được cho 1 property trong đối tượng (Obsever Property)
 */

example(of: "assign(to:on)") {
    //1
    class MyClass {
        var name: String = "" {
            didSet {
                print(name)
            }
        }
    }
    
    //2
    let obj = MyClass()
    
    //3
    let publisher = ["Apple", "iOS", "Combine"].publisher
    
    //4
    _ = publisher
        .assign(to: \.name, on: obj)
}
/*
 Giải thích:
 1: Tạo 1 class & có 1 Obsever Property cho 1 property của nó
 2: Tạo đối tượng
 3: Tạo 1 Publisher từ 1 array String (publisher này phát ra các output là String)
 4: Subcribe cho publisher theo `assign(to:on)`
     - to : tới thuộc tính nào của đối tượng
     - on : cho đối tượng nào
 */


/// CANCELLABLE
/*
 - Được dùng khi 1 subcriber trong một thời gian dài mà không nhận được dữ liệu từ publisher thì tốt nhất là huỹ nó đi.
 - 1 Subcription trả về 1 `canncellation token` thì cho phép huỹ đăng kí với publisher
 - gọi hàm `cancel()`
 - nếu bạn không sử dụng `cancel()` thì subcriber vẫn có thể huỹ nếu nhận được `completion` hoặc `error`
 */

example(of: "Cancellation") {
    let myNotification = Notification.Name("fxNotification")
    
    let publisher = NotificationCenter.default.publisher(for: myNotification, object: nil)
    
    let center = NotificationCenter.default
    
    //SINK
    let subscription = publisher.sink { _ in
        print("FxNotification received from a publisher!")
    }
    
    //POST
    center.post(name: myNotification, object: nil)
    center.post(name: myNotification, object: nil)
    center.post(name: myNotification, object: nil)
    
    //CANCEL
    subscription.cancel()
    
    center.post(name: myNotification, object: nil) // không nhận được
}

/*
     TỔNG HỢP LẠI CHÚT
 
 [PUBLISHER]                   [SUBSCRIBER]
      | <------- subscribes -------- |
      | ---- gives subscription ---> |
      | <----- requests values ----- |
      | ------- send values -------> |
      | ----- send completion -----> |
      |                              |
      V                              V
 */
