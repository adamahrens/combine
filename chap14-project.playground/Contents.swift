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
  
  /// Private JSON Decoding queue
  private let background = DispatchQueue(label: "API", qos: .default, attributes: .concurrent, autoreleaseFrequency: .never, target: nil)
  
  func story(id: Int) -> AnyPublisher<Story, Error> {
    let publisher = URLSession.shared
      .dataTaskPublisher(for: EndPoint.story(id).url)
      .receive(on: background)
      .map(\.data)
      .decode(type: Story.self, decoder: decoder)
      .catch { _ in Empty<Story, Error>() }
      .eraseToAnyPublisher()
    return publisher
  }
  
  func stories() -> AnyPublisher<[Story], Error> {
    let publisher = URLSession.shared
      .dataTaskPublisher(for: EndPoint.stories.url)
      .receive(on: background)
      .map(\.data)
      .decode(type: [Int].self, decoder: decoder).mapError { error -> API.Error in
        switch error {
          case is URLError:
            return Error.addressUnreachable(EndPoint.stories.url)
          default:
            return Error.invalidResponse
        }
    }.filter { !$0.isEmpty }.flatMap { ids in
      return self.mergedStories(ids: ids)
    }.scan([]) { stories, story in
      return stories + [story]
      }.map { $0.sorted() }.eraseToAnyPublisher()
    
    return publisher
  }
  
  func mergedStories(ids: [Int]) -> AnyPublisher<Story, Error> {
    let storyIds = Array(ids.prefix(maxStories))
    precondition(storyIds.isEmpty == false)
    
    let initial = story(id: storyIds[0])
    let remaining = Array(storyIds.dropFirst())
    return remaining.reduce(initial) { combined, nextId in
      return combined.merge(with: story(id: nextId)).eraseToAnyPublisher()
    }
  }
}

let api = API()
var subscriptions = [AnyCancellable]()

api.story(id: 1000).sink(receiveCompletion: { result in
  print("Completion \(result)")
}) { story in
  print("Next Story: \(story)")
}.store(in: &subscriptions)


api.mergedStories(ids: [1000, 1001, 1002]).sink(receiveCompletion: { result in
  print("Completion \(result)")
}) { story in
  print("Next Story: \(story)")
}.store(in: &subscriptions)


api.stories()
  .sink(receiveCompletion: { print($0) }, receiveValue: { print($0) }) .store(in: &subscriptions)


import UIKit
final class StoriesTableViewController: UITableViewController {
  var stories = [Story]() {
    didSet {
      tableView.reloadData()
    }
  }
  
  private let api = API()
  private var subscriptions = [AnyCancellable]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    api.stories()
      .receive(on: DispatchQueue.main)
      .catch { _ in Empty() }
      .assign(to: \.stories, on: self)
      .store(in: &subscriptions)
  }
  
  // MARK: - Table view data source
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return stories.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
    let story = stories[indexPath.row]
    
    cell.textLabel!.text = story.title
    cell.textLabel!.textColor = UIColor.orange
//    cell.detailTextLabel!.text = "By \(story.by)"
    return cell
  }
}

// Run indefinitely.
PlaygroundPage.current.needsIndefiniteExecution = true

PlaygroundPage.current.liveView = StoriesTableViewController()

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
