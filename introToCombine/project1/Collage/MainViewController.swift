/// Copyright (c) 2020 Razeware LLC
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

final class MainViewController: UIViewController {
  
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
      .print("imageCollage")
      .handleEvents(receiveOutput: { [weak self] photos in
        self?.updateUI(photos: photos)
      })
      .map { UIImage.collage(images: $0, size: collageSize) }
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
    PhotoWriter.save(image: image).sink { [weak self] result in
      if case .failure(let error) = result {
        self?.showMessage("Error", description: error.localizedDescription)
      }
      
      self?.actionClear()
    } receiveValue: { [weak self] id in
      self?.showMessage("Saved Image with Id: \(id)")
    }.store(in: &subscriptions)
  }
  
  @IBAction func actionAdd() {
//    images.value = images.value + [UIImage(named: "IMG_1907.jpg")!]
    
    let viewController = storyboard?.instantiateViewController(identifier: "PhotosViewController") as? PhotosViewController
    guard let pvc = viewController else { return }
    
    // Subscribe to selected images
    let newPhotos = pvc
      .selectedPhoto
      .prefix(while: { [unowned self] _ in
        self.images.value.count < 6
      })
      .share()
    
    newPhotos
      .map { self.images.value + [$0] }
      .assign(to: \.value, on: images)
      .store(in: &subscriptions)
    
    newPhotos
      .filter { _ in self.images.value.count == 6 }
      .flatMap { [unowned self] _ in self.alert(title: "Limit Reached", message: "Only 6 pictures are allowed") }
      .sink { [unowned self] _ in
        self.navigationController?.popViewController(animated: true)
      }.store(in: &subscriptions)
    
    newPhotos
      .ignoreOutput()
      .delay(for: 2.0, scheduler: DispatchQueue.main)
      .sink { [unowned self] _ in
        self.updateUI(photos: self.images.value)
      } receiveValue: { _ in }
      .store(in: &subscriptions)

    pvc
      .$selectedPhotosCount
      .filter { $0 > 0 && self.images.value.count <= 5 }
      .map { "Selected \($0) photos" }
      .assign(to: \.title, on: self)
      .store(in: &subscriptions)
    
    navigationController?.pushViewController(pvc, animated: true)
  }
  
  private func showMessage(_ title: String, description: String? = nil) {
//    Old Non combine way
//    let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
//    alert.addAction(UIAlertAction(title: "Close", style: .default, handler: { alert in
//      self.dismiss(animated: true, completion: nil)
//    }))
//    present(alert, animated: true, completion: nil)
    
    alert(title: title, message: description)
      .sink{ _ in }
      .store(in: &subscriptions)
  }
}
