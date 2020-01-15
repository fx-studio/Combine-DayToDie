# Publishers & Subscribers

Phần này bạn sẽ tìm hiểu về cơ bản 2 thực thế chính trong Combine:

- Publisher
- Subscriber

### Nội dung

- Phần 01 : Publisher & Subscriber
  - Khái niệm Publisher
  - Đối tượng Notification dùng như một Publisher
  - Khái niệm về Subcriber
  - SINK & ASSIGN
  - JUST
  - CANCELLABLE
  - Quy tắc ứng xử giữa 2 thèn đó
- Phần 02: Custom Subscriber
  - Tạo 1 class kế thừa từ Subscriber
  - Implement các func và các type cần thiết
  - ý nghĩa của `request` & các giá trị của request
- Phần 03: Future
  - Nói về một loại Publisher
  - Đặc trưng là phát 1 lần duy nhất rồi ngủm
- Phần 04: Subject
  - Ý nghĩa của Subject và nó cũng là 1 loại Publisher
  - Là thực thể kết nối giữa code Combine và Non-Combine
  - PassthroughSubject : lúc nào phát thì sẽ nhận được giá trị
  - CurrentValueSubject : không quan tâm lúc nào phát, chỉ cần subscription là có giá trị (cuối cùng)

---

### BÀI HỌC KINH NGHIỆM Ở ĐÂY LÀ

- Với các `PUBLISHER` đã tìm hiểu (như Notification hay array chuyển đổi thành publisher) thì bạn sẽ phát một lần đi tất cả các giá trị mà nó đang nắm giữ
- Với `FUTURE` thì sẽ phát ra duy nhất một lần mà thôi, giá trị có thể là giá trị hoặc completion hoặc lỗi
- Với `JUST` cũng như vậy, nhưng nó sẽ phát đi các giá trị được cung cấp vào lúc khởi tạo đối tượng JUST và chỉ phát ra như vậy
- Với `SUBJECT` thì ta có nhiều loại, nhiều class và dùng được cho nhiều trường hợp:
  - **PassThoughtSubject** --> có phép gởi nhiều, từng giá trị (bất chấp). Muốn gởi giá trị nào thì người lập trình có thể tuỳ ý mà không bị các hạn chế của các đối tượng publisher trên
  - **CurrentValueSubject** --> tương tự như cái trên. Mà khi có 1 subscription mới tới thì nó sẽ luôn phát đi giá trị cuối cùng của nó. Nếu lúc mới khởi tạo thì nó sẽ phát đi giá trị được khởi tạo đi. --> đảm bảo lúc nào cũng có giá trị để nhận

