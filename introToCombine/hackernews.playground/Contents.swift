import PlaygroundSupport
import Combine
import Foundation

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
  
  /// Private JSON parsing queue
  private let apiQueue = DispatchQueue(label: "HackerAPI", qos: .default, attributes: .concurrent)
  
  /// Public Methods
  func story(id: Int) -> AnyPublisher<Story, Error> {
    URLSession.shared.dataTaskPublisher(for: EndPoint.story(id).url)
      .print("API Story \(id)")
      .receive(on: apiQueue)
      .map(\.data)
      .decode(type: Story.self, decoder: decoder)
      .catch { _ in Empty<Story, Error>() }
      .eraseToAnyPublisher()
  }
  
  func stories(ids stories: [Int]) -> AnyPublisher<Story, Error> {
    let idsToFetch = Array(stories.prefix(maxStories))
    guard !idsToFetch.isEmpty else { return Empty<Story, Error>().eraseToAnyPublisher() }
    let first = story(id: idsToFetch[0])
    let remainder = Array(idsToFetch.dropFirst())
    
    return remainder.reduce(first) { combined, id in
      return combined
        .merge(with: story(id: id))
        .eraseToAnyPublisher()
    }
  }
  
  func latest() -> AnyPublisher<[Story], Error> {
    URLSession.shared.dataTaskPublisher(for: EndPoint.stories.url)
      .print("Latest Stories")
      .receive(on: apiQueue)
      .map(\.data)
      .decode(type: [Int].self, decoder: decoder)
      .mapError { error -> API.Error in
        switch error {
          case is URLError:
            return Error.addressUnreachable(EndPoint.stories.url)
          default:
            return Error.invalidResponse
        }
      }
      .filter { $0.isEmpty != true }
      .flatMap { ids in
        stories(ids: ids)
      }
      .scan([]) { stories, story -> [Story] in
        stories + [story]
      }.map { $0.sorted() }
      .eraseToAnyPublisher()
  }
}

struct Story: Codable, CustomDebugStringConvertible, Comparable {
  static func < (lhs: Story, rhs: Story) -> Bool {
    lhs.time < rhs.time
  }
  
  var debugDescription: String {
    return "\(id) - \(title) by \(author)\n"
  }
  
  let author: String
  let id: UInt
  let score: Int
  let title: String
  let url: String
  let time: TimeInterval
  
  enum CodingKeys: String, CodingKey {
    case author = "by", id, score, title, url, time
  }
}

// Call the API here
var subscriptions = Set<AnyCancellable>()
let api = API()

api.story(id: 6969).sink { result in
  print(result)
} receiveValue: { story in
  print(story)
}.store(in: &subscriptions)

api.stories(ids: [1000, 1001, 1002])
  .sink(receiveCompletion: { print($0) },
        receiveValue: { print($0) })
  .store(in: &subscriptions)

api.latest().sink { result in
  print(result)
} receiveValue: { stories in
  print(stories)
}.store(in: &subscriptions)
