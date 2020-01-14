import Combine
import Foundation

//example(of: "Future") {
//  func futureIncrement(
//    integer: Int,
//    afterDelay delay: TimeInterval) -> Future<Int, Never> {
//    Future<Int, Never> { promise in
//      print("Original")
//      DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
//        promise(.success(integer + 1))
//      }
//    }
//  }
//
//  // 1
//  let future = futureIncrement(integer: 1, afterDelay: 3)
//
//  // 2
//  future
//    .sink(receiveCompletion: { print($0) },
//          receiveValue: { print($0) })
//    .store(in: &subscriptions)
//
//  future
//    .sink(receiveCompletion: { print("Second", $0) },
//          receiveValue: { print("Second", $0) })
//    .store(in: &subscriptions)
//}

/*
 Phần này chắc hơi khó hiểu vì trong sách không nói nhiều mấy và đoạn code không chạy được vì phần `store` khá là cà khịa mình. Còn sẽ tóm tắt như sau:
 
 - là một class
 - là một Publisher
 - Đối tượng này sẽ phát ra một giá trị duy nhất và kết thúc. Có thể là fail
 - Nó sẽ thực hiện một lời hứa `Promise` -> là 1 closure với kiểu Result, nên sẽ có 1 trong 2 trường hợp:
    - Success : phát ra Output
    - Failure : phát ra Error
 - Khi hoạt động
    - Lần subscribe đầu tiên thì nó sẽ thực hiện đầy đủ các thủ tục. Và phát ra giá trị -> kết thúc hoặc thất bại
    - Lần subcribe tiếp theo thì chỉ phát ra giá trị cuối cùng. Bỏ qua các bước thủ thục khác.
 */
