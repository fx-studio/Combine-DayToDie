# Operators

Hiểu đơn giản thì các Operators chính là các từ vựng, giúp bạn diễn đạt logic/ý nghĩa của mình trong code. Đây là phần khá là lớn trong Combine. Bạn sẽ đối mặt với hằng hà sa số các phép toán. Bạn sẽ phải hiểu chúng để có thể sử dụng thành thạo và biến đổi các đối tượng theo ý muốn của mình.

Kết thúc phần này là 1 project luyện tập. Mục tiêu lớn là phải sử dụng code Combine trong UIKit. Khá là thách thức!

### Nội dung:

* Phần 01 : Transforming Operators
* Phần 02 : Filtering Operators
* Phần 03 : Combining Operators
* Phần 04 : Time Manipulation Operators
* Phần 05 : Sequence Operators
* Phần 06 : Tích hợp với UIKit

---

## 1. Transforming Operators

#### 1.1. publisher

Có nhiều function/method sẽ trả về 1 publisher và nó cũng gọi là operator. Các operator này giúp biến đổi một giá trị nào đó (có thể là Combine hoặc Non-Combine) để tạo thành một. `publisher`. Ví dụ sau:

```swift
["A", "B", "C", "D", "E"].publisher
```

Từ bây giờ, bạn sẽ làm quen nhiều tới việc biến đổi và biến đổi liên tục. Có nghĩa là đầu ra của 1 operator này là đầu vào của một operator khác.

#### 1.2. Collecting values

Tư tưởng lớn ở đây chính là khi bạn mệt mỏi khi phải làm việc với từng giá trị đơn riêng lẻ. Đôi lúc bạn muốn tổng hợp lại và xử lý nhanh gọn 1 lần nhiều giá trị. Thì các operator liên quan tới **collecting** sẽ giúp đỡ bạn.

Các dùng đơn giản, cầm đầu thèn publisher nào đó. và gọi function sau:

* Gôm hết các giá trị lại 1 lần

```swift
.collect()
```

* Gôm theo số lượng chỉ định

```swift
.collect(2)
```

> Về bản chất, nó cũng trả về là một **Publisher** mà thôi. Nên sau đó bạn có thể subscribe như bình thường.

