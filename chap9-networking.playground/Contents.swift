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

URLSession.shared.dataTaskPublisher(for: url).sink(receiveCompletion: { completion in
  switch completion {
    case .finished:
      print("Finished fetching from GitHub")
    case .failure(let error):
      print("Errored GitHub: \(error)")
  }
}) { data, response in
  let httpResponse = response as! HTTPURLResponse
  print("Response \(httpResponse.statusCode)")
  print("Response headers \(httpResponse.allHeaderFields)")
  print("Data size \(data.count)")
}.store(in: &subscriptions)
  
URLSession.shared
  .dataTaskPublisher(for: url)
  .map (\.data)
  .decode(type: GitHubUser.self, decoder: JSONDecoder())
  .sink(receiveCompletion: { completion in
  switch completion {
    case .finished:
      print("Finished fetching from GitHub")
    case .failure(let error):
      print("Errored GitHub: \(error)")
  }
}) { user in
  print("GitHubUser = \(user)")
}.store(in: &subscriptions)
