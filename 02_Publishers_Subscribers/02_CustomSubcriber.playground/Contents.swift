import UIKit
import Combine
/*
 Tiến hành thử với 1 ví dụ về custom Subcriber
 */
example(of: "Custom Subscriber") {
    // 1
    let publisher = (1...6).publisher
    
    //10
    //let publisher = ["A", "B", "C", "D", "E", "F"].publisher
    
    // 2
    final class IntSubscriber: Subscriber {
        // 3
        typealias Input = Int
        typealias Failure = Never
        
        // 4
        func receive(subscription: Subscription) {
            subscription.request(.max(3))
            
        }
        // 5
        func receive(_ input: Int) -> Subscribers.Demand {
            print("Received value", input)
            return .none
            
            //8
            //return .unlimited
            
            //9
            //return .max(1)
        }
        
        // 6
        func receive(completion: Subscribers.Completion<Never>) {
            print("Received completion", completion)
        }
    }
    
    // 7
    let subscriber = IntSubscriber()
    publisher.subscribe(subscriber)
}

/*
 Giải thích:
 1: Tạo 1 publisher với output là Int từ 1 range
 2: Tạo 1 class là `IntSubcriber` kế thừa từ `Subscribe`
 3: Implement những gì mà protocol yêu cầu
     - Input : Int
     - Failure : Never (ko bao giờ lỗi)
 4: Bắt đầu với việc nhận giá trị thì implement method `receive(subscription:)`, được gọi bởi publisher. Sử dụng `request()` của subscription để yêu cầu publisher gởi giá trị về
 5: in từng giá trị nhận được và return về `.none` nghĩa là không có thay đổi yêu cầu gì hết (tương đương với `request(.max(0))`)
 6: khi nhận được 1 completion và kết thúc
 7: Tạo 1 đối tượng subcriber và subscribe tới publisher. Khi đó publisher sẽ phát và nhận được 3 giá trị theo như đã request ở trên
 8: điểu chỉnh 1 chút, từ `.none` thành `.unlimited` thì sẽ in hết cả 6 giá trị, mặc dù request là `max = 3` --> với việc nhận được giá trị thì Subscriber cũng có thể điều chỉnh việc request đối với publisher
 9: Lại thay đổi từ `.unlimited` thành `.max(1)` thì vẫn nhận được hết tất cả giá trị. Điều này có nghĩa khi return là `max(1)` thì yêu cầu nhận thêm 1 phần tử nữa từ publisher
 10: thay đổi publisher thành 1 array String thì trình biên dịch sẽ báo lỗi về type của Input. Muốn chạy được thì thay đổi lại kiểu Input
 */
