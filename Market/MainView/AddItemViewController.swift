import UIKit
import Gallery
import JGProgressHUD
import NVActivityIndicatorView

class AddItemViewController: UIViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    
    var category: Category!
    var gallery: GalleryController!
    let hud = JGProgressHUD(style: .dark)
    var activityIndicator: NVActivityIndicatorView?
    
    var itemImages: [UIImage?] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(category.id)
    }
    
    @IBAction func doneBarButtonItemPressed(_ sender: Any) {
        dismissKeyboard()
        
        if fieldsAreCompleted() {
            saveToFirebase()
        } else {
            print("error")
            
        }
    }
    
    @IBAction func cameraButtonPressed(_ sender: Any) {
        itemImages = []
        showImageGallery()
    }
    
    @IBAction func backgroundTapped(_ sender: Any) {
        dismissKeyboard()
    }
    
    private func fieldsAreCompleted() -> Bool {
        return (titleTextField.text != "" && priceTextField.text != "" && descriptionTextView.text != "")
    }
    
    private func dismissKeyboard() {
        self.view.endEditing(false)
    }
    
    private func popTheView() {
        self.navigationController?.popViewController(animated: true)
    }
    
    private func saveToFirebase() {
        let item = Item()
        item.id = UUID().uuidString
        item.name = titleTextField.text!
        item.categoryId = category.id
        item.description = descriptionTextView.text!
        item.price = Double(priceTextField.text!)
        
        if itemImages.count > 0 {
            uploadImages(images: itemImages, itemId: item.id) { (imageLinkArray) in
                item.imageLinks = imageLinkArray
                saveItemToFirestore(item)
                self.popTheView()
            }
        } else {
            saveItemToFirestore(item)
            popTheView()
        }
    }
    
    private func showImageGallery() {
        self.gallery = GalleryController()
        self.gallery.delegate = self
        Config.tabsToShow = [.imageTab, .cameraTab]
        Config.Camera.imageLimit = 6
        self.present(self.gallery, animated: true, completion: nil)
    }
}

extension AddItemViewController: GalleryControllerDelegate {
    
    func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
        if images.count > 0 {
            Image.resolve(images: images) { resolvedImages in
                self.itemImages = resolvedImages
            }
        }
        controller.dismiss(animated: true, completion: nil)
    }
    
    func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func galleryController(_ controller: GalleryController, requestLightbox images: [Image]) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func galleryControllerDidCancel(_ controller: GalleryController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
