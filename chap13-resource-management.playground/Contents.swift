import UIKit
import Combine

struct GitHubUser: Codable {
  let login: String
  let name: String
  let location: String
  let followers: Int
}

let url = URL(string: "https://api.github.com/users/adamahrens")!
var subscriptions = Set<AnyCancellable>()

let sharedNetwork = URLSession.shared
  .dataTaskPublisher(for: url)
  .map (\.data)
  .decode(type: GitHubUser.self, decoder: JSONDecoder())
  .print("shared")
  // Allows one network request to happen and ther result passed to all subscribers
  // However if a new subscriber comes along after this completes it won't replay
  .share()

sharedNetwork.sink(receiveCompletion: { _ in
  print("1. finished")
}) { next in
  print("1. Next\(next))")
}.store(in: &subscriptions)

sharedNetwork.sink(receiveCompletion: { _ in
  print("2. finished")
}) { next in
  print("2. Next\(next))")
}.store(in: &subscriptions)


// Mulitcast for replays
let subject = PassthroughSubject<Data, URLError>()
let ray = URL(string: "https://www.raywenderlich.com")!

let multicast = URLSession.shared.dataTaskPublisher(for: ray).map(\.data).print("Multi").multicast(subject: subject)

// First subscription
multicast.sink(receiveCompletion: { _ in }) { data in
  print("Multi 1. Data \(data)")
}.store(in: &subscriptions)

multicast.sink(receiveCompletion: { _ in }) { data in
  print("Multi 2. Data \(data)")
}.store(in: &subscriptions)

// Connect to upstream publisher
multicast.connect()

subject.send(Data())

DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
  multicast.sink(receiveCompletion: { _ in }) { data in
    print("Multi 3. Data \(data)")
  }.store(in: &subscriptions)
}

// Even if you never subscribe to a Future,
// creating it will call your closure and perform the work
