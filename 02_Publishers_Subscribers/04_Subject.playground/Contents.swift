import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

/// Bạn đã tìm hiểu về cách thức hoạt động của các Publisher và Subcriber rồi. Tiếp đó bạn cũng đã học qua về Custom một Subcriber. Còn Custom một Publisher thì ntn. Phần này sẽ học sau. Nhưng tiếp tục với thứ gần gũi hơn đó là Subject
/// Đây cũng là một khái niệm, một thực thể ... quan trọng trong RxSwift. Nó là đối tượng trung gian để các mã không Combine có thể gởi giá trị tới các mã Combine. Xem ví dụ sau:

example(of: "PassthroughSubject") {
    //1:
    /// Định nghĩa một Error, cái này là phương pháp handle error đơn giản nhất cho từng trường hợp riêng lẻ
    enum MyError: Error {
        case test
    }
    
    //2:
    /// Custom một Subcriver như bài trước. Với Input là String và Error là MyError
    final class StringSubcriber: Subscriber {
        typealias Input = String
        typealias Failure = MyError
        
        func receive(subscription: Subscription) {
            subscription.request(.max(2))
        }
        
        func receive(_ input: String) -> Subscribers.Demand {
            print("A: Received value", input)
            //3
            /// Điều chỉnh lại dựa theo giá trị nhận được. Trong đó:
            /// - .none là không thay đổi gì hết
            /// - .max(1) là yêu cầu thêm 1 giá trị nữa từ publisher
            return input == "World" ? .max(1) : .none
        }
        
        func receive(completion: Subscribers.Completion<MyError>) {
            print("A: Received completion", completion)
        }
    }
    
    //4: Tạo một đối tượng Subcriber --> Ta tạm thời gọi là A
    let subscriber = StringSubcriber()
    
    //5: Tạo thêm 1 Subject
    let subject = PassthroughSubject<String, MyError>()
    
    //6: Đối tượng Subcriber thực hiện subscribe tới Subject
    subject.subscribe(subscriber)
    
    //7: taoh thêm 1 subscription khác, sử dụng SINK --> Ta tạm thời gọi là B
   let subscription = subject .sink(
        receiveCompletion: { completion in
          print("B: Received completion (sink)", completion)
        },
        receiveValue: { value in
          print("B: Received value (sink)", value)
        }
    )
    
    /*
     PassthoughtSubject cho phép phát các giá trị đi.
     Cũng như các loại Publisher khác thì cũng cần phải khai báo kiểu Input & Error. Khi các subcriber có cùng kiểu thì có thể subcribe tới được.
     */
    
    //8: Dùng Subject vừa tạo để phát giá trị đi. Khúc này bắt đầu nỗ não của bạn.
    /*
     Bạn gởi đi 'Hello' thì cả 2 A & B đều nhận được. Tuy nhiên, A sẽ so sánh input và yêu cầu thêm 1 giá trị nữa với .max(1) --> lúc này A request là 3. Còn B bình thường
     Bạn gởi tiếp 'World' thì B nhận cả 2 và A cũng nhận được 2
     */
    subject.send("Hello")
    subject.send("World")
    /*
     A so sánh input và sẽ request = .none. B vẫn âm thầm nhận
     */
    
    //subject.send("FX")
    
    //9
    subscription.cancel()
    /*
     Khi bạn 'cancel' subscription thì chuyện hay sẽ bắt đầu.
     */
    subject.send("Still there?")
    /*
     Khi bạn gởi thêm 1 input sau khi gởi 'cancel' thì B sẽ không nhận nữa (vì đã cancel rồi). Nhưng mà A vẫn muốn nhận thêm. Quan sát bạn thử gởi thêm một giá trị `FX` trước khi B cancel thì A chĩ nhận tối đa 3 input và inpur cuối cùng `still there` sẽ ko nhận.
     ==> ĐÓ chính là ý nghĩa của của request
     */
    
    //11
    //subject.send(completion: .failure(MyError.test))
    /*
     Khi bơm một completion là error thì sẽ nhận được Error và cũng sẽ kết thúc
     */
    
    //10: Khi gởi 'completion' thì các subcriber cũng sẽ kết thúc và ko nhận thêm giá trị nào nữa
    subject.send(completion: .finished)
    subject.send("How about another one?")
}

example(of: "CurrentValueSubject") {
    // 1: Cũng là một loại PUBLISHER. Nhưng SUBJECT này cho phép bạn:
    /*
        - Khởi tạo với một giá trị ban đầu.
        - Định nghĩa kiểu dữ liệu cho input và error
        - Khi một đối tượng subcriber thực hiện subcribe tới hoặc khi có một subscription mới --> Subject sẽ phát đi giá trị ban đầu (lúc khởi tạo) hoặc giá trị cuối cùng của nó.
        - Auto nhận được giá trị khi subscription, chứ ko phải lúc nào phát thì mới nhận. --> đây là điều khác biệt với PassThoughtSubject
     */
    let subject = CurrentValueSubject<Int, Never>(0)
    
    // 2: tạo 1 subscription trong đó:
    /*
        - in giá trị của Subject bằng hàm print()
        - sink và in giá trị nhận được ra
        - lưu trữ lại subscription --> là ntn thì tìm hiểu sau, giờ méo hiểu nó
        - Mặc định lúc này sẽ nhận được giá trị `0` đầu tiên
     */
    subject
        .sink(receiveValue: { print("- 1st subscription: ", $0) })
        .store(in: &subscriptions) //3
    
    // 4: gởi các giá trị đi --> nhận được các giá trị 1 & 2
    subject.send(1)
    subject.send(2)
    
    //in giá trị của subject --> code này ko có Combine gì hết
    print("Subject Value ", subject.value)
    
    //chỉ cần set giá trị mới --> auto Subject sẽ phát đi giá trị cho các subscription hay các subcriber biết
    subject.value = 3
    print("Subject Value ", subject.value)
    
    // tạo 1 subscription mới và nó sẽ nhận được giá trị cuối cũng của Subject là 3
    subject
        .print()
        .sink(receiveValue: { print("- 2nd subscription:", $0) })
        .store(in: &subscriptions)
    
    // Kết thúc chuỗi ngày đau khổ của subject
    //subject.value = .finished
    subject.send(completion: .finished)
    
    // những cố gắng vô ích tiếp sau. Khi phát đi completion thì tất cả sẽ kết thúc
    subject
    .sink(receiveValue: { print("- 3rd subscription:", $0) })
    .store(in: &subscriptions)
    
    subject.value = 5
    print("Subject Value ", subject.value)
}

/*
 BÀI HỌC KINH NGHIỆM Ở ĐÂY LÀ:
 - Với các PUBLISHER đã tìm hiểu (như Notification hay array chuyển đổi thành publisher) thì bạn sẽ phát một lần đi tất cả các giá trị mà nó đang nắm giữ
 - Với FUTURE thì sẽ phát ra duy nhất một lần mà thôi, giá trị có thể là giá trị hoặc completion hoặc lỗi
 - Với JUST cũng như vậy, nhưng nó sẽ phát đi các giá trị được cung cấp vào lúc khởi tạo đối tượng JUST và chỉ phát ra như vậy
 - Với SUBJECT thì ta có nhiều loại, nhiều class và dùng được cho nhiều trường hợp:
     + PassThoughtSubject --> có phép gởi nhiều, từng giá trị (bất chấp). Muốn gởi giá trị nào thì người lập trình có thể tuỳ ý mà không bị các hạn chế của các đối tượng publisher trên
     + CurrentValueSubject --> tương tự như cái trên. Mà khi có 1 subscription mới tới thì nó sẽ luôn phát đi giá trị cuối cùng của nó. Nếu lúc mới khởi tạo thì nó sẽ phát đi giá trị được khởi tạo đi. --> đảm bảo lúc nào cũng có giá trị để nhận
 */
