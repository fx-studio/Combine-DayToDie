# Hello Combine

### Asynchronous programming

- Khi bạn thực hiện code của minh trên single-thread thì mọi việc rất đơn giản. Bạn nắm được tất cả các trạng thái và thứ tự thực thi của code. Nhưng với những những ngôn ngữ multi-threaded thì bất đồng bộ trong việc điều hướng UI Framework …
- Nó tuỳ thuộc vào môi trường thực thi của nó là như thế nào … nên khó mà đoán đươc khi các thread chaỵ đồng thời

### Foundation and UIKit/AppKit 

- Apple đã âm thâm cải tiến và phát triển Asynchronous Programming trong nhiều năm.

- Họ đã tạo ra rất nhiều cơ chế mà bạn có thể sử dụng ở nhiều cấp độ khác nhau để taọ và thực thi các mã bất đồng bộ.

- Một số thức kinh điển như sau:

- - `NotificationCenter`

  - - Thực thi 1 đoạn mã bất cứ khi nào sự kiện mà bạn quan tâm xảy ra

  - `The delegation pattern`

  - - Cho phép bạn xác định 1 đối tượng hoạt động thay mặt hoặc phối hợp với một đối tượng khác

  - `Grand Cental Dispatch` & `Operations`

  - - Trường tượng hoá trong việc thực hiện từng phần của công việc
    - Lên lịch thực hiện từng phần theo nhiều cách khác nhau trong ngăn xếp (tuần tự hay ưu tiên)

  - `Closures`

  - - Tạo ra các đoạn mã có thể tách rời và chuyển cho các đối tượng khác thực thi ở một nơi nào đó

- Để viết 1 chương trình bất đồng bộ thì rất tốt. Nhưng về riêng code bất đồng bộ thì rất khó theo dõi, tái sử dụng và không đôngf nhất về cú pháp … 

- Combine : 

- - nhằm mục đích giới thiệu 1 ngôn ngữ mới trong hệ sinh tái của Swift, giúp bạn đêm lại trật tự cho thế giới hỗn loạn của lập trình bất đồng bộ.
  - Apple đã tích hợp combine vào sâu trong Foudation, từ Timer tới các cốt lõi như CoreData …
  - Và có thể tích hợp vào code riêng của banh

- Quan trong là sự kết hợp ăn ý giữa SwiftUI & Combine
- Combine là sự kết hợp, các api của nó với các api đã có. Nên sẽ không ảnh hưởng gì nhiều nếu code của bạn đã xây dựng bất đồng bộ bằng những thứ trước đây.
- Tuy nhiên, chúng vẫn đảm bảo sự động tốt nhất cho dù cách mới hay cách cũ.

### Foundation of Combine

- Về Declarative, Reactive Programming thì ko còn mới nữa, nó đã ra đời cách đây khác lâu. Nhưng trong 1 thập kỉ gần đây thì đánh dấu sự trở lại lạnh mẽ của nó.

- 2009 Microsoft đã đưa ra khái niệm về Reative Extention

- 2012 [Rx.Net](http://Rx.Net) ra đời, kéo Theo 1 loạt sau đó như: RxJS, RxKotlin, RxScale, RxPHP …

- Với nền tảng Apple thì chúng ta có third-party là RxSwift

- Với combine thì

- - của apple
  - định nghiệm 1 chuẩn riêng
  - vẫn giống như Rx
  - gọi là Reactive Streams (méo hiểu nó là gì nữa)
  - về concept thì vẫn mãng tính chất cốt lõi như Rx

### Combine basics

- 3 thành phần quan trọng cần tìm hiểu là

- - Publishers
  - Opertors
  - Subscribers

- Tất nhiều để làm tốt combine thì phải cần thêm các thành phần nữa, phần nàỳ sẽ bổ sung sau

### Publishers

- Là kiểu phát ra các GIÁ TRỊ theo thời gian cho 1 hoặc nhiều thành phần quan tâm tới.

- Bất kì loại publishers nào hay với bất kì login nào thì 1 publisher sẽ phát là 3 loại giá trị:

- - giá trị đầu ra theo giá trị ban đầu của đâu ra
  - Successful completion
  - A completion with error

- Khi phát ra completion (bất chấp là success hay error) thì không thể phát ra các giá trị khác nữa.

- Tư tưởng: ko cần tìm ra 1 tool tốt để thực hiện công việc thì hãy tạo ra nó.

- Với 1 Publishers Protocol thì có 2 kiểu 

- - Publisher.Output

  - - Kiểu giá trị mà nó phát ra
    - ví dụ nếu là Int thì chỉ phát ra Int chứ ko phát ra đc các kiểu khác như String, Date …

  - Publisher.Failure

  - - kiểu được phát ra khi có error
    - nếu ko dùng thì hay chắc chắn ko lỗi thì là Never()

- Khi bạn đăng kí cho 1 publisher thì bạn đã chắc chắn về kiểu và error của nó rồi

### Operators

- Là các method được khai báo dựa trên Publiser Protocol mà trả về cùng hoặc một publisher mới

- Rất hữu ích khi bạn kết hợp các phương thức lần lược để sinh ra một publisher mới

- Các khái niệm và cách thức thực thi vẫn mang giá trị như Rx

- - Đầu vào của opertator này là đầu ra của operator trước đó
  - Các operator được thực thi liên tiếp
  - Không có các mã nào chen ngang và tạo thành 1 luồng xuyên suốt cho bạn

### Subscribers

- Cuối cùng trong chuổi đăng ký (subscription) đó là Subscribers

- Subscriber sẽ làm 1 cái gì đó đối với 

- - sự kiện xảy ra
  - mỗi giá trị được phát ra

- Hiện tại thì combine cung cấp 2 kiểu Subscribers cơ bản để tương tác với data streams

- - Sink subscriber

  - - kiểu closure
    - tương tác trực tiếp với kiểu output nhận được trong completion

  - Assign subscriber

  - - Không cần custom code
    - Liên kết đầu ra với các thuộc tính trên model
    - Hay điều kiển các thành phần của UI

- Khi muốn cần dữ liệu khác thì thay đổi subscribers vẫn đơn giản hơn là publisher về khoản này thì Combine có vẻ dễ tiếp cận hơn so với RxSwift nhiều

###  Subscriptions

- Về Subscriptions là 1 khái niệm được dùng để nói về 1 chuỗi từ publisher -> operator —> subscribers

- Khi add 1 subscriber vào cuối 1 subscription thì hoàn thành 1 subscription

- Phải có subscriber thì publisher mới phát giá trị output, nếu ko có thì ko phát (rất quan trọng)

- Điều thú vị nữa là chỉ cần khai báo các subscription 1 lần và bạn ko cần quan tâm tới các đoạn code của mình nữa.

- Nếu full combine, bạn có thể mô tả logic ứng dụng thông qua việc khai báo và sau khi khai báo hoàn tất chỉ cần hệ thống thực thi mọi thứ mà không cần tới việc pull data hay call back giữa các đối tượng.

- Compile code của bạn với subscription thì coi như đã xong. Subscription sẽ tự động gọi theo bất đồng bộ khi có sự kiện xảy ra và sẽ phản ứng theo đó.

- Về việc quản lý bộ nhớ thì bạn không cần quan tâm nhiều và Combine cung cấp cho bạn 1 giao thức Cancellable Protocol

- - Được tích hợp cho cả publisher và subscriber
  - Khi đối tượng được huỷ thì auto giải phóng tất cả khỏi bộ nhớ
  - Cancel sẽ tìm hiểu thêm

### What's the benefit of Combine code over "standard" code?

- Các điểm lợi ích mà Combine mang lại:

- - Combine được tích hợp với hệ thống
  - Các style code cũ vẫn ok khi kết hợp với combine
  - Khi các phần bất đồng bộ được thiết kế theo kiểu interface thì mang lại sức mạnh rất lớn
  - Operator có tính kết hợp cao
  - Testing oke 

###  App architecture

- Combine là framework chứ ko phải struct project nên nó cũng như bao framwork khác. Nó được tích hợp nhằm tối ưu chứ ko thay đổi cấu trúc của project của bạn
- Các mô hình MVC, MVVM hay VIPER vẫn hoạt động ổn với Combine
- Và Combine vẫn kết hợp ổn với các code cũ
- Bộ đôi SwiftUI + Combine là sự kết hợp khá ăn ý cho Reactive Programming

### Book projects

- Playground
- Xcode Project