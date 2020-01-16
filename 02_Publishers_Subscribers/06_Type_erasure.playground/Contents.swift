import UIKit
import Combine

var subscriptions = Set<AnyCancellable>()

example(of: "Type erasure") {
    //1: Tạo 1 Passthrough Subject
    let subject = PassthroughSubject<Int, Never>()
    
    //2: Tạo tiếp 1 publisher từ subject trên, bằng cách gọi function để sinh ra 1 erasure publisher
    let publisher = subject.eraseToAnyPublisher()
    
    //3: Subscribe đối tượng type-erased publisher đó
    publisher
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
    
    //4: dùng Subject phát 1 giá trị đi
    subject.send(0)
    
    //5: dùng erased publisher để phát --> ko đc : vì không có function này
    //publisher.send(1)
}

/*
    Ý NGHĨA của TYPE ERASURE
 - Đôi khi bạn muốn subscride một publisher mà không cần biết quá nhiều về chi tiết của nó
 - Type-erased publisher thì đại diện là AnyPublisher và cũng có quan hệ họ hàng với Publisher.
 - Có thể mô tả như bạn có trải nghiệm déjà vu trong mơ. Nhưng sau này bạn sẽ thấy lại nó ở đâu đó, vì thực sự bạn đã thấy nó và nó đã xoá khỏi bộ nhớ của bạn
 - Ngoài ra, ta còn có AnyCancellable cũng là 1 type-erased class
 - Để tạo ra 1 type-erased publisher thì bạn sử dụng 1 subject và gọi 1 function `eraseToAnyPublisher()`
 - Với AnyPublisher, thì không thể gọi function `send(_:)` được. Class này đã bọc và ẩn đi nhiều phương thức & thuộc tính của Publisher.
 - Trong thực tế thì cũng không nên lạm dụng hay khuyến khích dùng nhiều kiểu này. Vì đôi khi bạn cần khai báo và xác định rõ kiểu giá trị nhận được
 */
