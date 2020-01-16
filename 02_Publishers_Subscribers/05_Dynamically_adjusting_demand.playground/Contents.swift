import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

example(of: "Dynamically adjusting Demand") {
    //1: custom subscriber --> new a sub-class Subscriber
    final class IntSubscriber: Subscriber {
        
        //Khai báo thêm kiểu dữ liệu cho Input và kiểu cho Failure
        typealias Input = Int
        typealias Failure = Never
        
        //Khi nhận được 1 subscription ==> Có request hay không
        func receive(subscription: Subscription) {
            subscription.request(.max(2))
        }
        
        // Đây là phần chính cần quan tâm cho việc điều chỉnh request để nhận thêm giá trị
        func receive(_ input: Int) -> Subscribers.Demand {
            print("Received value", input)
            
            switch input {
            case 1:
                return .max(2)
            case 3:
                return .max(1)
            default:
                return .none
            }
        }
        
        func receive(completion: Subscribers.Completion<Never>) {
            print("Received completion", completion)
        }
    }
    
    let subscriber = IntSubscriber()
    
    let subject = PassthroughSubject<Int, Never>()
    
    subject.subscribe(subscriber)
    
    subject.send(1)
    subject.send(2)
    subject.send(3)
    subject.send(4)
    subject.send(5)
    subject.send(6)
}

/*
 Ý nghĩa phần này:
 - Cho bạn ngộ ra được việc điều chỉnh yêu cầu từ Subscriber
 - Tự bạn điều chỉnh ra max phù hợp
 */
