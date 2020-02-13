import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

//MARK: Never
example(of: "Never sink") {
  Just("Hello")
    .sink { print($0) }
    .store(in: &subscriptions)
  
}

enum MyError: Error {
  case ahihi
}

example(of: "setFailureType") {
  Just("Hello")
    .setFailureType(to: MyError.self)
    .sink(receiveCompletion: { completion in
      
      switch completion {
      case .failure(.ahihi):
        print("Finished with Oh No!")
      case .finished:
        print("Finished successfully!")
      }
      
    }, receiveValue: { value in
      print("Got value: \(value)")
    })
    .store(in: &subscriptions)
}

example(of: "assign") {
  // 1
  class Person {
    let id = UUID()
    var name = "Unknown"
  }

  // 2
  let person = Person()
  print("1", person.name)

  Just("Shai")
    .handleEvents( // 3
      receiveCompletion: { _ in print("2", person.name) }
    )
    .assign(to: \.name, on: person) // 4
    .store(in: &subscriptions)
}


example(of: "assertNoFailure") {
  // 1
  Just("Hello")
    .setFailureType(to: MyError.self)
    //.tryMap { _ in throw MyError.ahihi }
    .assertNoFailure() // 2
    .sink(receiveValue: { print("Got value: \($0) ")}) // 3
    .store(in: &subscriptions)
}

//MARK: try*
example(of: "tryMap") {
  enum NameError: Error {
    case tooShort(String)
    case unknown
  }
  
  let names = ["Scott", "Marin", "Shai", "Florent"].publisher
  
  // map
  names
    .map { value in
      return value.count
   }
  .sink(receiveCompletion: { print("🔵 Completed with \($0)") }, receiveValue: { print("🔵 Got Value: \($0)") })
  .store(in: &subscriptions)
  
  // tryMap
  names
    .tryMap { value -> Int in
      
      let length = value.count
      
      guard length >= 5 else { throw NameError.tooShort(value) }
      
      return value.count
   }
  .sink(receiveCompletion: { print("🔴 Completed with \($0)") }, receiveValue: { print("🔴Got Value: \($0)") })
  .store(in: &subscriptions)
  
  
}

//MARK: Mapping Error
example(of: "Mapping Error") {
  enum NameError: Error {
    case tooShort(String)
    case unknown
  }
  
  Just("Hello")
    .setFailureType(to: NameError.self)
    //.map { $0 + " World!" }
    .tryMap { throw NameError.tooShort($0) }
    .mapError { $0 as? NameError ?? .unknown }
    .sink(receiveCompletion: { completion in
      
      switch completion {
      case .finished:
        print("Done!")
      case .failure(.tooShort(let name)):
        print("\(name) is too short!")
      case .failure(.unknown):
          print("An unknown name error occurred")
      }
      
    }, receiveValue: { print("Got value \($0)") })
    .store(in: &subscriptions)
}

//MARK: API Failure
example(of: "Joker API") {
  
  // Define class
 class DadJokes {
  struct Joke: Codable {
    let id: String
    let joke: String
  }
  
  enum Error: Swift.Error, CustomStringConvertible {
    case network
    case jokeDoesntExist(id: String)
    case parsing
    case unknown

    var description: String {
      switch self {
      case .network:
        return "Request to API Server failed"
      case .parsing:
        return "Failed parsing response from server"
      case .jokeDoesntExist(let id):
        return "Joke with ID \(id) doesn't exist"
      case .unknown:
        return "An unknown error occurred"
      }
    }
  }
    
    // call api
    func getJoke(id: String) -> AnyPublisher<Joke, Error> {
      guard id.rangeOfCharacter(from: .letters) != nil else {
        return Fail<Joke, Error>(error: .jokeDoesntExist(id: id))
                .eraseToAnyPublisher()
      }
      
      let url = URL(string: "https://icanhazdadjoke.com/j/\(id)")!
      var request = URLRequest(url: url)
      request.allHTTPHeaderFields = ["Accept": "application/json"]
      
      return URLSession.shared
        .dataTaskPublisher(for: request)
      //.map(\.data)
        .tryMap { data, _ -> Data in
          guard let obj = try? JSONSerialization.jsonObject(with: data),
                let dict = obj as? [String: Any],
                dict["status"] as? Int == 404 else {
            return data
          }
          throw DadJokes.Error.jokeDoesntExist(id: id)
        }
        .decode(type: Joke.self, decoder: JSONDecoder())
        .mapError { error -> DadJokes.Error in
          switch error {
          case is URLError:
            return .network
          case is DecodingError:
            return .parsing
          default:
            return error as? DadJokes.Error ?? .unknown
          }
        }
        .eraseToAnyPublisher()
    }
    
  }
  
  //API
  let api = DadJokes()
  let jokeID = "9prWnjyImyd"
  let badJokeID = "123456"
  // 5
  api
    .getJoke(id: jokeID)
    .sink(receiveCompletion: { print($0) },
          receiveValue: { print("Got joke: \($0)") })
    .store(in: &subscriptions)
}
