import UIKit
import Combine

var subscriptions = Set<AnyCancellable>()

example(of: "collect") {
    ["A", "B", "C", "D", "E"].publisher
        .collect()
        .sink(receiveCompletion: { print($0) },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
    
}

example(of: "map") {
    // 1
    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut
    // 2
    [22, 07, 2020, 999999].publisher // 3
        .map {
            formatter.string(for: NSNumber(integerLiteral: $0)) ?? "" }
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "map key paths") {
    //1
    let publisher = PassthroughSubject<Coordinate, Never>()
    
    //2
    publisher
        //3
        .map(\.x, \.y)
        .sink { (x, y) in
            //4
            print("The coodinate at (\(x), \(y)) is in quadrant", quadrantOf(x: x, y: y))
    }
        .store(in: &subscriptions)
    
    publisher.send(Coordinate(x: 10, y: -8))
    publisher.send(Coordinate(x: 0, y: 5))
}

example(of: "tryMap") {
    Just("Đây là đường dẫn tới file XXX nè")
        .tryMap { try FileManager.default.contentsOfDirectory(atPath: $0) }
        .sink(receiveCompletion: { print("Finished ", $0) },
              receiveValue: { print("Value ", $0) })
    .store(in: &subscriptions)
}

example(of: "flatMap") {
    let teo = Chatter(name: "Tèo", message: " --- TÈO đã vào room ---")
    let ti = Chatter(name: "Tí", message: " --- TÍ đã vào room ---")
    
    let chat = PassthroughSubject<Chatter, Never>()
    
    chat
        .flatMap(maxPublishers: .max(2)) { $0.message }
        .sink { print($0) }
        .store(in: &subscriptions)
    
    //let's go chat
    
    //1 : Tèo vảo room
    chat.send(teo)
    //2 : Tèo hỏi
    teo.message.value = "TÈO: Tôi là ai? Đây là đâu?"
    //3 : Tí vào room
    chat.send(ti)
    //4 : Tèo hỏi thăm
    teo.message.value = "TÈO: Tí khoẻ không."
    //5 : Tí trả lời
    ti.message.value = "TÍ: Tao không khoẻ lắm. Bị Thuỷ đậu cmnr mày."
    
    let thuydau = Chatter(name: "Thuỷ đậu", message: " --- THUỶ ĐẬU đã vào room ---")
    //6 : Thuỷ đậu vào room
    chat.send(thuydau)
    thuydau.message.value = "THUỶ ĐẬU: Các anh gọi em à."
    
    //7 : Tèo sợ
    teo.message.value = "TÈO: Toang rồi."
}

example(of: "replaceNil") {
    ["A",  nil, "B"].publisher
        .replaceNil(with: "-")
        .map({$0!})
        .sink { print($0) }
        .store(in: &subscriptions)
}

example(of: "replaceEmpty(with:)") {
    // 1
    let empty = Empty<Int, Never>()
    // 2
    empty
        .replaceEmpty(with: 1)
        .sink(receiveCompletion: { print($0) },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "scan") {
    let pub = (0...5).publisher
    
    pub
        .scan(0) { $0 + $1 }
        .sink { print ("\($0)", terminator: "-->") }
        .store(in: &subscriptions)
}

example(of: "Filter") {
    let numbers = (1...10).publisher
    
    numbers
        .filter { $0.isMultiple(of: 3) }
        .sink { n in
            print("\(n) is a multiple of 3!")
        }
        .store(in: &subscriptions)
}

example(of: "removeDuplicates") {
    // 1
    let words = "hey hey there! want to listen to mister mister ?" .components(separatedBy: " ")
        // 2
        .publisher
    words
        .removeDuplicates()
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "compactMap") {

    let strings = ["a", "1.24", "3", "def", "45", "0.23"].publisher

    strings
        .compactMap { Float($0) }
        .sink(receiveValue: {  print($0) })
        .store(in: &subscriptions)
}

example(of: "ignoreOutput") {

    let numbers = (1...10_000).publisher

    numbers
        .ignoreOutput()
        .sink(receiveCompletion: { print("Completed with: \($0)") }, receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "first(where:)") {
  // 1
  let numbers = (1...9).publisher
  
  // 2
  numbers
    .print("numbers")
    .first(where: { $0 % 2 == 0 })
    .sink(receiveCompletion: { print("Completed with: \($0)") },
          receiveValue: { print($0) })
    .store(in: &subscriptions)
}

example(of: "last(where:)") {
  let numbers = PassthroughSubject<Int, Never>()
  
  numbers
    .last(where: { $0 % 2 == 0 })
    .sink(receiveCompletion: { print("Completed with: \($0)") },
          receiveValue: { print($0) })
    .store(in: &subscriptions)
  
  numbers.send(1)
  numbers.send(2)
  numbers.send(3)
  numbers.send(4)
  numbers.send(5)
  numbers.send(completion: .finished)
}

example(of: "dropFirst") {
 
    let numbers = (1...10).publisher //["a","b","c","e","f","g","h","i","k","l","m","n"].publisher

    numbers
        .dropFirst(8)
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "drop(while:)") {

  let numbers = (1...10).publisher
  
  numbers
    .drop(while: {
      print("x")
      return $0 % 5 != 0
    })
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
}

example(of: "drop(untilOutputFrom:)") {
  // 1
  let isReady = PassthroughSubject<Void, Never>()
  let taps = PassthroughSubject<Int, Never>()
  
  // 2
  taps
    .drop(untilOutputFrom: isReady)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
  
  // 3
  (1...15).forEach { n in
    taps.send(n)
    
    if n == 3 {
      isReady.send()
    }
  }
}

example(of: "prefix") {
  // 1
  let numbers = (1...10).publisher
  
  // 2
  numbers
    .prefix(2)
    .sink(receiveCompletion: { print("Completed with: \($0)") },
          receiveValue: { print($0) })
    .store(in: &subscriptions)
}

example(of: "prefix(while:)") {
  // 1
  let numbers = (1...10).publisher
  
  // 2
  numbers
    .prefix(while: { $0 < 7 })
    .sink(receiveCompletion: { print("Completed with: \($0)") },
          receiveValue: { print($0) })
    .store(in: &subscriptions)
}

example(of: "prefix(untilOutputFrom:)") {
  // 1
  let isReady = PassthroughSubject<Void, Never>()
  let taps = PassthroughSubject<Int, Never>()
  
  // 2
  taps
    .prefix(untilOutputFrom: isReady)
    .sink(receiveCompletion: { print("Completed with: \($0)") },
          receiveValue: { print($0) })
    .store(in: &subscriptions)
  
  // 3
  (1...15).forEach { n in
    taps.send(n)
    
    if n == 5 {
      isReady.send()
    }
  }
}
