import Foundation
import Combine

enum TimeoutError: Error {
    case timedOut
}

var subscriptions = Set<AnyCancellable>()

public func example(of description: String,
                    action: () -> Void) {
  print("\n——— Example of:", description, "———")
  action()
}

extension Date {
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }

    init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

func printDate() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.S"
    return formatter.string(from: Date())
}

//////////////////////////////////////////////////////////////

func delay() {
    let valuesPerSecond = 1.0
    let delayInSeconds = 2.0

    let sourcePublisher = PassthroughSubject<Date, Never>()
    let delayedPublisher = sourcePublisher.delay(for: .seconds(delayInSeconds), scheduler: DispatchQueue.main)

    //subscription
    sourcePublisher
        .sink(receiveCompletion: { print("Source complete: ", $0) }) { print("Source: ", $0)}
        .store(in: &subscriptions)

    delayedPublisher
       .sink(receiveCompletion: { print("Delay complete: \($0) - \(Date()) ") }) { print("Delay: \($0) - \(Date()) ")}
       .store(in: &subscriptions)

    DispatchQueue.main.async {
        Timer.scheduledTimer(withTimeInterval: 1.0 / valuesPerSecond, repeats: true) { _ in
            sourcePublisher.send(Date())
        }
    }
}

func collect() {
    let valuesPerSecond = 1.0
    let collectTimeStride = 4
    let collectMaxCount = 2

    let sourcePublisher = PassthroughSubject<Int, Never>()

    let collectedPublisher = sourcePublisher
            .collect(.byTime(DispatchQueue.main, .seconds(collectTimeStride)))
            .flatMap { dates in dates.publisher }
    
    let collectedPublisher2 = sourcePublisher
        .collect(.byTimeOrCount(DispatchQueue.main, .seconds(collectTimeStride), collectMaxCount))
        .flatMap { dates in dates.publisher }
    
    //subscription
    sourcePublisher
        .sink(receiveCompletion: { print("\(Date()) - 🔵 complete: ", $0) }) { print("\(Date()) - 🔵: ", $0)}
        .store(in: &subscriptions)

    collectedPublisher
       .sink(receiveCompletion: { print("\(Date()) - 🔴 complete: \($0)") }) { print("\(Date()) - 🔴: \($0)")}
       .store(in: &subscriptions)
    
    collectedPublisher2
        .sink(receiveCompletion: { print("\(Date()) - 🔶 complete: \($0)") }) { print("\(Date()) - 🔶: \($0)")}
        .store(in: &subscriptions)
    
    DispatchQueue.main.async {
        sourcePublisher.send(0)
        
        var count = 1
        Timer.scheduledTimer(withTimeInterval: 1.0 / valuesPerSecond, repeats: true) { _ in
            sourcePublisher.send(count)
            count += 1
        }
    }
}

func debounce() {
    //data
    let typingHelloWorld: [(TimeInterval, String)] = [
      (0.0, "H"),
      (0.1, "He"),
      (0.2, "Hel"),
      (0.3, "Hell"),
      (0.5, "Hello"),
      (0.6, "Hello "),
      (2.0, "Hello W"),
      (2.1, "Hello Wo"),
      (2.2, "Hello Wor"),
      (2.4, "Hello Worl"),
      (2.5, "Hello World")
    ]
    
    //subject
    let subject = PassthroughSubject<String, Never>()
    
    //debounce publisher
    let debounced = subject
        .debounce(for: .seconds(1.0), scheduler: DispatchQueue.main)
        .share()
    
    //subscription
    subject
        .sink { string in
            print("\(printDate()) - 🔵 : \(string)")
        }
        .store(in: &subscriptions)
    
    debounced
        .sink { string in
            print("\(printDate()) - 🔴 : \(string)")
        }
        .store(in: &subscriptions)
    
    //loop
    let now = DispatchTime.now()
    for item in typingHelloWorld {
        DispatchQueue.main.asyncAfter(deadline: now + item.0) {
            subject.send(item.1)
        }
    }
}

func throttle() {
    //data
    let typingHelloWorld: [(TimeInterval, String)] = [
      (0.0, "H"),
      (0.1, "He"),
      (0.2, "Hel"),
      (0.3, "Hell"),
      (0.5, "Hello"),
      (0.6, "Hello "),
      (2.0, "Hello W"),
      (2.1, "Hello Wo"),
      (2.2, "Hello Wor"),
      (2.4, "Hello Worl"),
      (2.5, "Hello World")
    ]
    
    //subject
    let subject = PassthroughSubject<String, Never>()
    
    //debounce publisher
    let throttle = subject
        .throttle(for: .seconds(1.0), scheduler: DispatchQueue.main, latest: true)
        .share()
    
    //subscription
    subject
        .sink { string in
            print("\(printDate()) - 🔵 : \(string)")
        }
        .store(in: &subscriptions)
    
    throttle
        .sink { string in
            print("\(printDate()) - 🔴 : \(string)")
        }
        .store(in: &subscriptions)
    
    //loop
    let now = DispatchTime.now()
    for item in typingHelloWorld {
        DispatchQueue.main.asyncAfter(deadline: now + item.0) {
            subject.send(item.1)
        }
    }
    
}

func timeout() {
    let subject = PassthroughSubject<Void, TimeoutError>()
    
    let timeoutSubject = subject.timeout(.seconds(5), scheduler: DispatchQueue.main, customError: {.timedOut})
    
    subject
        .sink(receiveCompletion: { print("\(printDate()) - 🔵 completion: ", $0) }) { print("\(printDate()) - 🔵 : event")}
        .store(in: &subscriptions)
    
    timeoutSubject
        .sink(receiveCompletion: { print("\(printDate()) - 🔴 completion: ", $0) }) { print("\(printDate()) - 🔴 : event")}
        .store(in: &subscriptions)
    
    print("\(printDate()) - BEGIN")
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        subject.send()
    }
}

func measureInterval() {
    //data
    let typingHelloWorld: [(TimeInterval, String)] = [
      (0.0, "H"),
      (0.1, "He"),
      (0.2, "Hel"),
      (0.3, "Hell"),
      (0.5, "Hello"),
      (0.6, "Hello "),
      (2.0, "Hello W"),
      (2.1, "Hello Wo"),
      (2.2, "Hello Wor"),
      (2.4, "Hello Worl"),
      (2.5, "Hello World")
    ]
    
    //subject
    let subject = PassthroughSubject<String, Never>()
    //measure
    let measureSubject = subject.measureInterval(using: DispatchQueue.main)
    let measureSubject2 = subject.measureInterval(using: RunLoop.main)
    
    //subscription
    subject
        .sink { string in
            print("\(printDate()) - 🔵 : \(string)")
        }
        .store(in: &subscriptions)
    
    measureSubject
        .sink { string in
            print("\(printDate()) - 🔴 : \(string)")
        }
        .store(in: &subscriptions)
    
    measureSubject2
        .sink { string in
            print("\(printDate()) - 🔶 : \(string)")
        }
        .store(in: &subscriptions)
    
    
    //loop
    let now = DispatchTime.now()
    for item in typingHelloWorld {
        DispatchQueue.main.asyncAfter(deadline: now + item.0) {
            subject.send(item.1)
        }
    }
}

measureInterval()


