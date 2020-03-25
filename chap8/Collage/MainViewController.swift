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

import UIKit
import Combine

class MainViewController: UIViewController {
  
  // MARK: - Outlets

  @IBOutlet weak var imagePreview: UIImageView! {
    didSet {
      imagePreview.layer.borderColor = UIColor.gray.cgColor
    }
  }
  
  @IBOutlet weak var buttonClear: UIButton!
  @IBOutlet weak var buttonSave: UIButton!
  @IBOutlet weak var itemAdd: UIBarButtonItem!

  // MARK: - Private properties
  
  private var subscriptions = Set<AnyCancellable>()
  private let images = CurrentValueSubject<[UIImage], Never>([])
  
  // MARK: - View controller
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let collageSize = imagePreview.frame.size
    images
      .handleEvents(receiveOutput: { [weak self] photos in
        self?.updateUI(photos: photos)
      })
      .map { photos in UIImage.collage(images: photos, size: collageSize) }
      .assign(to: \.image, on: imagePreview)
      .store(in: &subscriptions)
  }
  
  private func updateUI(photos: [UIImage]) {
    buttonSave.isEnabled = photos.count > 0 && photos.count % 2 == 0
    buttonClear.isEnabled = photos.count > 0
    itemAdd.isEnabled = photos.count < 6
    title = photos.count > 0 ? "\(photos.count) photos" : "Collage"
  }
  
  // MARK: - Actions
  
  @IBAction func actionClear() {
    images.send([])
  }
  
  @IBAction func actionSave() {
    guard let image = imagePreview.image else { return }
    
    PhotoWriter
      .save(image: image)
      .sink(receiveCompletion: { [weak self] result in
        switch result {
          case .finished:
            print("Finished saving collage to photos")
            self?.actionClear()
          case .failure(let error):
            print(error)
            self?.showMessage("Error", description: error.localizedDescription)
        }
      }) { [weak self] id in
        self?.showMessage("Success", description: "Saved with id \(id)")
      }.store(in: &subscriptions)
  }
  
  @IBAction func randomAdd(_ sender: Any) {
    // Networking
    let request = URLRequest(url: URL(string: "https://source.unsplash.com/random/300x300")!)
    URLSession.shared
      .dataTaskPublisher(for: request)
      .filter { response in
        guard let httpResponse = response.response as? HTTPURLResponse else { return false }
        return httpResponse.statusCode == 200
    }.map { response in
      return UIImage(data: response.data)
    }
    .receive(on: RunLoop.main)
    .sink(receiveCompletion: { result in
      switch result {
        case .failure(let error):
          print(error)
        case .finished:
          print("finished fetching from unsplash")
      }
    }) { [weak self] image in
      if let i = image, let self = self {
        print("We have an image")
        let addedImages = self.images.value + [i]
        self.images.send(addedImages)
      }
    }.store(in: &subscriptions)
  }
  
  @IBAction func actionAdd() {
    let viewController = storyboard?.instantiateViewController(identifier: "PhotosViewController") as! PhotosViewController
    
    // Subscribe to images
    let image = viewController.selectedPhoto
    image.map { [weak self] next in
      let current = self?.images.value ?? []
      return current + [next]
    }
    .assign(to: \.value, on: images)
    .store(in: &subscriptions)
    
    navigationController?.pushViewController(viewController, animated: true)
  }
  
  private func showMessage(_ title: String, description: String? = nil) {
    let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Close", style: .default, handler: { alert in
      self.dismiss(animated: true, completion: nil)
    }))
    present(alert, animated: true, completion: nil)
  }
}
