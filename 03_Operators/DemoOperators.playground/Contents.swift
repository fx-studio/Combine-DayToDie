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


example(of: "prepend(Output...)") {
    let publisher = [3, 4].publisher
    
    publisher
        .prepend(1, 2)
        .prepend(-2, -1, 0)
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "prepend(Sequence)") {
  // 1
  let publisher = [5, 6, 7].publisher
  
  // 2
  publisher
    .prepend([3, 4])
    .prepend(Set(1...2))
    .prepend(stride(from: 6, to: 11, by: 2))
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
}

example(of: "prepend(Publisher)") {
  // 1
  let publisher1 = [3, 4].publisher
  let publisher2 = [1, 2].publisher
  
  // 2
  publisher1
    .prepend(publisher2)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
}

example(of: "prepend(Publisher) #2") {
  // 1
  let publisher1 = [3, 4].publisher
  let publisher2 = PassthroughSubject<Int, Never>()
  
  // 2
  publisher1
    .prepend(publisher2)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)

  // 3
  publisher2.send(1)
  publisher2.send(2)
  publisher2.send(completion: .finished)
}

example(of: "append(Output...)") {
  // 1
  let publisher = [1].publisher

  // 2
  publisher
    .append(2, 3)
    .append(4)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
}

example(of: "append(Output...) #2") {
  // 1
  let publisher = PassthroughSubject<Int, Never>()

  publisher
    .append(3, 4)
    .append(5)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
  
  // 2
  publisher.send(1)
  publisher.send(2)
  publisher.send(completion: .finished)
}

example(of: "append(Sequence)") {
  // 1
  let publisher = [1, 2, 3].publisher
    
  publisher
    .append([4, 5]) // 2
    .append(Set([6, 7])) // 3
    .append(stride(from: 8, to: 11, by: 2)) // 4
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
}

example(of: "append(Publisher)") {
  // 1
  let publisher1 = [1, 2].publisher
  let publisher2 = [3, 4].publisher
  
  // 2
  publisher1
    .append(publisher2)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
}

example(of: "switchToLatest") {
  // 1
  let publisher1 = PassthroughSubject<Int, Never>()
  let publisher2 = PassthroughSubject<Int, Never>()
  let publisher3 = PassthroughSubject<Int, Never>()

  // 2
  let publishers = PassthroughSubject<PassthroughSubject<Int, Never>, Never>()

  // 3
  publishers
    .switchToLatest()
    .sink(receiveCompletion: { _ in print("Completed!") },
          receiveValue: { print($0) })
    .store(in: &subscriptions)

  publishers.send(publisher1)
  publisher1.send(1)
  publisher1.send(2)
    
    publishers.send(publisher2)
    publisher1.send(3)
    publisher2.send(4)
    publisher2.send(5)
    
    publishers.send(publisher3)
    publisher2.send(6)
    publisher3.send(7)
    publisher3.send(8)
    publisher3.send(9)
}

example(of: "merge(with:)") {
  // 1
  let publisher1 = PassthroughSubject<Int, Never>()
  let publisher2 = PassthroughSubject<Int, Never>()

  // 2
  publisher1
    .merge(with: publisher2)
    .sink(receiveCompletion: { _ in print("Completed") },
          receiveValue: { print($0) }).store(in: &subscriptions)

  // 3
  publisher1.send(1)
  publisher1.send(2)

  publisher2.send(3)

  publisher1.send(4)

  publisher2.send(5)

  // 4
  publisher1.send(completion: .finished)
  publisher2.send(completion: .finished)
}

example(of: "combineLatest") {
  // 1
  let publisher1 = PassthroughSubject<Int, Never>()
  let publisher2 = PassthroughSubject<String, Never>()

  // 2
  publisher1
    .combineLatest(publisher2)
    .sink(receiveCompletion: { _ in print("Completed") },
          receiveValue: { print("P1: \($0), P2: \($1)") })
    .store(in: &subscriptions)

  // 3
  publisher1.send(1)
  publisher1.send(2)
  
  publisher2.send("a")
  publisher2.send("b")
  
  publisher1.send(3)
  
  publisher2.send("c")

  // 4
  publisher1.send(completion: .finished)
  publisher2.send(completion: .finished)
}

example(of: "zip") {
  // 1
  let publisher1 = PassthroughSubject<Int, Never>()
  let publisher2 = PassthroughSubject<String, Never>()

  // 2
  publisher1
    .zip(publisher2)
    .sink(receiveCompletion: { _ in print("Completed") },
          receiveValue: { print("P1: \($0), P2: \($1)") })
    .store(in: &subscriptions)

  // 3
  publisher1.send(1)
  publisher1.send(2)
  publisher2.send("a")
  publisher2.send("b")
  publisher1.send(3)
  publisher2.send("c")
  publisher2.send("d")

  // 4
  publisher1.send(completion: .finished)
  publisher2.send(completion: .finished)
}

example(of: "min") {
  // 1
  let publisher = [1, -50, 246, 0].publisher

  // 2
  publisher
    .print("publisher")
    .min()
    .sink(receiveValue: { print("Lowest value is \($0)") })
    .store(in: &subscriptions)
}

example(of: "min non-Comparable") {
  // 1
  let publisher = ["12345",
                   "ab",
                   "hello world"]
    .compactMap { $0.data(using: .utf8) } // [Data]
    .publisher // Publisher<Data, Never>

  // 2
  publisher
    .print("publisher")
    .min(by: { $0.count < $1.count })
    .sink(receiveValue: { data in
      // 3
      let string = String(data: data, encoding: .utf8)!
      print("Smallest data is \(string), \(data.count) bytes")
    })
    .store(in: &subscriptions)
}

example(of: "max") {
  // 1
  let publisher = ["A", "F", "Z", "E"].publisher

  // 2
  publisher
    .print("publisher")
    .max()
    .sink(receiveValue: { print("Highest value is \($0)") })
    .store(in: &subscriptions)
}

example(of: "first") {
  // 1
  let publisher = ["A", "B", "C"].publisher

  // 2
  publisher
    .print("publisher")
    .first()
    .sink(receiveValue: { print("First value is \($0)") })
    .store(in: &subscriptions)
}

example(of: "first(where:)") {
  // 1
  let publisher = ["J", "O", "H", "N"].publisher

  // 2
  publisher
    .print("publisher")
    .first(where: { "Hello World".contains($0) })
    .sink(receiveValue: { print("First match is \($0)") })
    .store(in: &subscriptions)
}

example(of: "last") {
  // 1
  let publisher = ["A", "B", "C"].publisher

  // 2
  publisher
    .print("publisher")
    .last()
    .sink(receiveValue: { print("Last value is \($0)") })
    .store(in: &subscriptions)
}

example(of: "output(at:)") {
  // 1
  let publisher = ["A", "B", "C"].publisher

  // 2
  publisher
    .print("publisher")
    .output(at: 1)
    .sink(receiveValue: { print("Value at index 1 is \($0)") })
    .store(in: &subscriptions)
}

example(of: "output(in:)") {
  // 1
  let publisher = ["A", "B", "C", "D", "E"].publisher

  // 2
  publisher
    .output(in: 1...3)
    .sink(receiveCompletion: { print($0) },
          receiveValue: { print("Value in range: \($0)") })
    .store(in: &subscriptions)
}

example(of: "count") {
  // 1
  let publisher = ["A", "B", "C"].publisher

  publisher
    .print("publisher")
    .count()
    .sink(receiveValue: { print("I have \($0) items") })
    .store(in: &subscriptions)
}

example(of: "contains") {
  // 1
  let publisher = ["A", "B", "C", "D", "E"].publisher
  let letter = "F"

  // 2
  publisher
    .print("publisher")
    .contains(letter)
    .sink(receiveValue: { contains in
      // 3
      print(contains ? "Publisher emitted \(letter)!"
                     : "Publisher never emitted \(letter)!")
    })
    .store(in: &subscriptions)
    
}

example(of: "contains(where:)") {
  // 1
  struct Person {
    let id: Int
    let name: String
  }

  // 2
  let people = [
    (456, "Scott Gardner"),
    (123, "Shai Mishali"),
    (777, "Marin Todorov"),
    (214, "Florent Pillet")
  ]
  .map(Person.init)
  .publisher

  // 3
  people
    .contains(where: { $0.id == 800 || $0.name == "Marin Todorov" })
    .sink(receiveValue: { contains in
      // 4
      print(contains ? "Criteria matches!"
                     : "Couldn't find a match for the criteria")
    })
    .store(in: &subscriptions)
}

example(of: "allSatisfy") {
  // 1
  let publisher = stride(from: 0, to: 5, by: 2).publisher

  // 2
  publisher
    .print("publisher")
    .allSatisfy { $0 % 2 == 0 }
    .sink(receiveValue: { allEven in
      print(allEven ? "All numbers are even"
                    : "Something is odd...")
    })
    .store(in: &subscriptions)
}

example(of: "reduce") {
  // 1
  let publisher = ["Hel", "lo", " ", "Wor", "ld", "!"].publisher

  publisher
    .print("publisher")
    .reduce("") { accumulator, value in
    // 2
          accumulator + value
        }
    .sink(receiveValue: { print("Reduced into: \($0)") })
    .store(in: &subscriptions)
}
