import UIKit
import Combine

let ituneURL = "https://rss.itunes.apple.com/api/v1/us/apple-music/coming-soon/all/10/explicit.json"
var subscriptions = Set<AnyCancellable>()

//Define
struct Music: Codable {
  var name: String
  var id: String
  var artistName: String
  var artworkUrl100: String
}

struct MusicResults: Codable {
  var results: [Music]
  var updated: String
}

struct FeedResults: Codable {
  var feed: MusicResults
}

func demo1() {
  guard let url = URL(string: ituneURL) else { return }
  
  //1 create subscription
  URLSession.shared
    .dataTaskPublisher(for: url)
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
          print("Retrieving data failed with error \(error)")
        }
      }) { data, response in
      print("Retrieved data of size \(data.count), response = \(response)")
    }.store(in: &subscriptions)
}

func demo2() {
  guard let url = URL(string: ituneURL) else { return }
  
  //1 create subscription
  URLSession.shared
    .dataTaskPublisher(for: url)
//    .tryMap({ data, _ in
//      try JSONDecoder().decode(FeedResults.self, from: data)
//    })
    .map(\.data)
    .decode(type: FeedResults.self, decoder: JSONDecoder())
    .sink(receiveCompletion: { completion in
      if case .failure(let error) = completion {
        print("Retrieving data failed with error \(error)")
      }
    }) { object in
      let items = object.feed.results
      for item in items {
        print("\(item.id) - \(item.name)")
      }
  }.store(in: &subscriptions)
}

func demo3() {
  guard let url = URL(string: ituneURL) else { return }
  let publisher = URLSession.shared
    .dataTaskPublisher(for: url)
    .map(\.data)
    .multicast { PassthroughSubject<Data, URLError>() }
    
  //1
  publisher
    .sink(receiveCompletion: { completion in
      if case .failure(let err) = completion {
        print("Sink1 Retrieving data failed with error \(err)")
      }
    }, receiveValue: { object in
      print("Sink1 Retrieved object \(object)")
    })
    .store(in: &subscriptions)
  
  //2
  publisher
    .sink(receiveCompletion: { completion in
      if case .failure(let err) = completion {
        print("Sink2 Retrieving data failed with error \(err)")
      }
    }, receiveValue: { object in
      print("Sink2 Retrieved object \(object)")
    })
  .store(in: &subscriptions)
  
  // connect
  publisher.connect().store(in: &subscriptions)
}

DispatchQueue.main.async {
  demo3()
}
