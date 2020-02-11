import Foundation
import PlaygroundSupport
import Combine

struct API {
  /// API Errors.
  enum Error: LocalizedError {
    case addressUnreachable(URL)
    case invalidResponse
    
    var errorDescription: String? {
      switch self {
      case .invalidResponse: return "The server responded with garbage."
      case .addressUnreachable(let url): return "\(url.absoluteString) is unreachable."
      }
    }
  }
  
  /// API endpoints.
  enum EndPoint {
    static let baseURL = URL(string: "https://hacker-news.firebaseio.com/v0/")!
    
    case stories
    case story(Int)
    
    var url: URL {
      switch self {
      case .stories:
        return EndPoint.baseURL.appendingPathComponent("newstories.json")
      case .story(let id):
        return EndPoint.baseURL.appendingPathComponent("item/\(id).json")
      }
    }
  }

  /// Maximum number of stories to fetch (reduce for lower API strain during development).
  var maxStories = 10

  /// A shared JSON decoder to use in calls.
  private let decoder = JSONDecoder()
  
  private let apiQueue = DispatchQueue(label: "API", qos: .default, attributes: .concurrent)
  
  // Phương thức đầu tiên để gọi API đơn lẻ --> giá trị trả về là 1 Publisher
  func story(id: Int) -> AnyPublisher<Story, Error> {
    // Sử dụng URLSession với dataTaskPublisher
    return URLSession.shared
      .dataTaskPublisher(for: EndPoint.story(id).url)
      // thực hiện ở queue tạo ra
      .receive(on: apiQueue)
      // sử dụng phần data, bỏ đi responce
      .map(\.data)
      // parse theo kiểu Story với JSONDecocer
      .decode(type: Story.self, decoder: decoder)
      // bắt lỗi --> nếu có lỗi thì trả về 1 kiểu Empty không có gì hết
      .catch { _ in Empty<Story, Error>() }
      // biến đổi về lại publisher
      .eraseToAnyPublisher()
  }
  
  func mergedStories(ids storyIDs: [Int]) -> AnyPublisher<Story, Error> {
    // Làm giảm đi số phần tử trong array ban đầu với prefix
    let storyIDs = Array(storyIDs.prefix(maxStories))
    
    // để kiện để tiếp tục xử lý
    precondition(!storyIDs.isEmpty)
    
    // Tạo publiser đầu tiên với id đầu tiên của storyIDs
    let initialPublisher = story(id: storyIDs[0])
    
    // tạo 1 array mới bằng cách bỏ qua id đầu tiên trong array storyIDs
    let remainder = Array(storyIDs.dropFirst())
    
    // Trả giá trị trả về là 1 Publisher
    // Sử dụng hàm reduce của Swift --> cần cung cấp giá trị đầu tiên là 1 publisher
    // Việc thực hiện sẽ trong closure với 2 tham số:
    //      - Result
    //      - id (là element của array)
    return remainder.reduce(initialPublisher) { (combined, id) in
      // tại mỗi bước thì merger publisher mới đó vào combined result
      return combined
      .merge(with: story(id: id)) // Tạo 1 publisher mới với id mới --> gọi func trên kia
      .eraseToAnyPublisher() // biến đổi thành AnyPublisher
    }
  }
  
  // Lấy các story mới nhất --> trả về 1 publisher với output là array story
  func stories() -> AnyPublisher<[Story], Error> {
    
    // vẫn sử dụng đối tượng huyền thoại này
    return URLSession.shared
      // tạo publisher với endpoint
      .dataTaskPublisher(for: EndPoint.stories.url)
      // sử dụng data, bỏ đi responce
      .map(\.data)
      // biến data thành array int với JSONDecoder
      .decode(type: [Int].self, decoder: decoder)
      // điểm mới sáng tạo khi handle error tại đây
      /*
       - Khi gặp error thì sẽ map đó thành Error
       - addressUnreachable --> Url có vấn đề --> dataTaskPublisher sẽ phát ra URLError
       - invalidResponse --> không đọc được json --> JSONDecoder phát ra cái vẹo gì đó ko biết nữa
       */
      .mapError { error -> API.Error in
        switch error {
        case is URLError:
          return Error.addressUnreachable(EndPoint.stories.url)
        default:
          return Error.invalidResponse
        }
    }
    // loại trừ đi các trường hợp rỗng
    .filter { !$0.isEmpty }
      // Vì có thể có nhiều giá trị là array Int được phát ra --> hợp nhất chúng lại --> làm phẵng
    .flatMap { storyIDs in
      // sinh ra 1 publisher (stream) --> nhiều lần thì nhiều publisher
      return self.mergedStories(ids: storyIDs)
    }
      // thay vì nhận mỗi lần 1 giá trị, thì cứ gom tụi nó lại, tới lúc publisher đó completion --> sẽ phát đi 1 giá trị với với publisher tạo ra từ scan
    .scan([]) { (stories, story) in
      return stories + [story]
    }
      // sắp xếp lại cho đẹp
    .map { $0.sorted() }
      // xoá sạch quá khứ
    .eraseToAnyPublisher()
    
  }
  
}

// Call the API here
let api = API()
var subscriptions = [AnyCancellable]()

//api.story(id: -5)
//  .sink(receiveCompletion: { print($0) }, receiveValue: { print($0) })
//  .store(in: &subscriptions)

//api.mergedStories(ids: [1000, 1001, 1002])
//  .sink(receiveCompletion: { print($0) }, receiveValue: { print($0) })
//  .store(in: &subscriptions)

api.stories()
.sink(receiveCompletion: { print($0) },
receiveValue: { print($0) }) .store(in: &subscriptions)


// Run indefinitely.
PlaygroundPage.current.needsIndefiniteExecution = true

/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.
