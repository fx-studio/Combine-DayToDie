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
  // đây là biến tạo ra để `store` tất cả các subscription. Và khi vòng đời của 1 VC kết thúc thì tất cả chúng nó sẽ bị huỹ --> Khỏi lo lắng vấn đề bộ nhớ.
  
  private let images = CurrentValueSubject<[UIImage], Never>([])
  // Dùng để gởi đi 1 image tới UI Control. Và nếu bạn thường xuyên thực hiện công việc này trong VC thì lời khuyên cho bạn nên sử dụng CurrentValueSubject, vì:
  // - Đảm bảo được luôn có 1 giá trị nhận được khi có 1 subscriber subscribe tới nó
  // - Không fail, không cancel
  
  
  
  // MARK: - View controller
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let collageSize = imagePreview.frame.size
    
    // Bắt đầu subscription nào
    images
      .handleEvents(receiveOutput: { [weak self] photos in
        self?.updateUI(photos: photos)
      })
      // Biến đổi Input của subject là Array[UIImage] thành UIImage
      .map { photos in
        // Đây là extention bọn nó viết giúp việc tạo ra 1 cái ảnh mới từ các ảnh trong array
        UIImage.collage(images: photos, size: collageSize)
      }
      // Sử dụng ASSIGN để subscriber tới thuộc tính image của đối tượng `imagePreview`
      .assign(to: \.image, on: imagePreview)
      //lưu trữ subscription --> để auto huỹ
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
    // reset toàn bộ ảnh thì chỉ cần dùng subject send đi 1 array rỗng
  }
  
  @IBAction func actionSave() {
    guard let image = imagePreview.image else { return }
    
    PhotoWriter.save(image)
      .sink(receiveCompletion: { [unowned self] completion in
        if case .failure(let error) = completion {
          //self.showMessage("Error", description: error.localizedDescription)
          
          self.alert(title: "Error", text: error.localizedDescription)
            .sink { _ in
              // tự sướng trong này
          }
          .store(in: &self.subscriptions)
          
        }
        
        self.actionClear()
        
      }) { [unowned self] id in
        //self.showMessage("Saved with id: \(id)")
        
        self.alert(title: "Error", text: "").sink { _ in
          // tự sướng trong này
        }.store(in: &self.subscriptions)
      }
      .store(in: &subscriptions)
    
  }
  
  @IBAction func actionAdd() {
    //let newImages = images.value + [UIImage(named: "IMG_1907.jpg")!]
    // Sẽ lấy array image từ subject và công thêm 1 image mới
    
    //images.send(newImages)
    // Subject sẽ send cả array image đó đi
    
    ///////
    let photos = storyboard!.instantiateViewController( withIdentifier: "PhotosViewController") as!
    PhotosViewController
    
    let newPhotos = photos.selectedPhotos
    
    newPhotos
      .map { [unowned self] newImage in
        return self.images.value + [newImage]
    }
    .assign(to: \.value, on: images)
    .store(in: &subscriptions)
    
    photos.$selectedPhotosCount
      .filter { $0 > 0 }
      .map { "Selected \($0) photos" }
      .assign(to: \.title, on: self)
      .store(in: &subscriptions)
    
    navigationController!.pushViewController(photos, animated: true)
  }
  
  private func showMessage(_ title: String, description: String? = nil) {
    let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Close", style: .default, handler: { alert in
      self.dismiss(animated: true, completion: nil)
    }))
    present(alert, animated: true, completion: nil)
  }
}
