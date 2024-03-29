import UIKit
import JGProgressHUD
import Stripe

class BasketViewController: UIViewController {

    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var basketTotalLabel: UILabel!
    @IBOutlet weak var basketTotalItem: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var checkOutButtonOutlet: UIButton!
    //MARK: - Vars
    var basket: Basket?
    var allItems: [Item] = []
    var purchasedItemIds : [String] = []
    
    let hud = JGProgressHUD(style: .dark)
    var totalPrice = 0
    
    
    //MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = footerView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //TODO: Check if user is logged in
        if MUser.currentUser() != nil {
            loadBasketFromFirestore()
        } else {
            self.updateTotalLabels(true)
        }

    }
    
    @IBAction func checkOutButtonPressed(_ sender: Any) {
        if MUser.currentUser()!.onBoard {
//            finishPayment(token: Constants.)
            showPaymentOptions()

        } else {
            self.showNotification(text: "Please complete you profile!", isError: true)
        }
    }
    
    //MARK: - Download basket
    private func loadBasketFromFirestore() {
        
        downloadBasketFromFirestore(MUser.currentId()) { (basket) in
            
            self.basket = basket
            self.getBasketItems()
        }
    }
    
    private func getBasketItems() {
        
        if basket != nil {
            
            downloadItems(basket!.itemIds) { (allItems) in
                
                self.allItems = allItems
                self.updateTotalLabels(false)
                self.tableView.reloadData()
            }
        }
    }
    
    //MARK: - Helper functions
    
    private func updateTotalLabels(_ isEmpty: Bool) {
        
        if isEmpty {
            basketTotalLabel.text = "0"
            basketTotalItem.text = returnBasketTotalPrice()
        } else {
            basketTotalLabel.text = "\(allItems.count)"
            basketTotalItem.text = returnBasketTotalPrice()
        }
        
        
        //TODO: Update the button status
        checkoutButtonStatusUpdate()
    }
    
    private func returnBasketTotalPrice() -> String {
        
        var totalPrice = 0.0
        
        for item in allItems {
            totalPrice += item.price
        }
        
        return "Total price: " + convertToCurrency(totalPrice)
    }
    
    private func showItemView(withItem: Item) {
        let itemVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "itemView") as! ItemViewController
        itemVC.item = withItem
        self.navigationController?.pushViewController(itemVC, animated: true)
    }
    
    private func checkoutButtonStatusUpdate() {
        checkOutButtonOutlet.isEnabled = allItems.count > 0
        if checkOutButtonOutlet.isEnabled {
            checkOutButtonOutlet.backgroundColor = .systemBlue
        } else {
            disableCheckoutButton()
        }
    }
    
    private func disableCheckoutButton() {
        checkOutButtonOutlet.isEnabled = false
        checkOutButtonOutlet.backgroundColor = .systemRed
    }
    
    private func removeItemFromBasket(itemId: String) {
        for i in 0..<basket!.itemIds.count {
            if itemId == basket?.itemIds[i] {
                basket?.itemIds.remove(at: i)
                return
            }
        }
    }
    
    func tempFunction() {
        for item in allItems {
            print("we have ", item.id)
            purchasedItemIds.append(item.id)
        }
    }
    

    private func emptyTheBasket() {
        
        purchasedItemIds.removeAll()
        allItems.removeAll()
        tableView.reloadData()
        
        basket!.itemIds = []
        
        updateBasketInFirestore(basket!, withValues: [kITEMIDS : basket!.itemIds]) { (error) in
            
            if error != nil {
                print("Error updating basket ", error!.localizedDescription)
            }
            
            self.getBasketItems()
        }
        
    }
    
    private func addItemsToPurchaseHistory(_ itemIds: [String]) {
        
        if MUser.currentUser() != nil {
            
            print("item ids , ", itemIds)
            let newItemIds = MUser.currentUser()!.purchasedItemIds + itemIds
            
            updateCurrentUserInFirestore(withValues: [kPURCHASEDITEMIDS : newItemIds]) { (error) in
                
                if error != nil {
                    print("Error adding purchased items ", error!.localizedDescription)
                }
            }
        }
        
    }
    
    private func finishPayment(token: STPToken) {
        self.totalPrice = 0
        for item in allItems {
            purchasedItemIds.append(item.id)
            self.totalPrice += Int(item.price)
        }
        self.totalPrice = self.totalPrice * 100
        StripeClient.shared.createAndConfirmPayment(token, amount: totalPrice) { error in
            if error == nil {
                self.emptyTheBasket()
                self.addItemsToPurchaseHistory(self.purchasedItemIds)
                self.showNotification(text: "Payment successful", isError: false)
            } else {
                self.showNotification(text: error!.localizedDescription, isError: true)
                self.showNotification(text: "Payment not successful", isError: true)
            }
        }
    }
    
    private func showNotification(text: String, isError: Bool) {
        if isError {
            self.hud.indicatorView = JGProgressHUDErrorIndicatorView()
        } else {
            self.hud.indicatorView = JGProgressHUDSuccessIndicatorView()
        }
        self.hud.textLabel.text = text
        self.hud.indicatorView = JGProgressHUDErrorIndicatorView()
        self.hud.show(in: self.view)
        self.hud.dismiss(afterDelay: 2.0)
    }
    
    private func showPaymentOptions() {
        let alertController = UIAlertController(title: "Payment Options", message: "Choose prefared payment options", preferredStyle: .actionSheet)
        let cardAAction = UIAlertAction(title: "Pay with card", style: .default) { action in
            let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "cardInfoVC") as! CardInfoViewController
            vc.delegate = self
            self.present(vc, animated: true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cardAAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension BasketViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ItemTableViewCell
        
        cell.generateCell(allItems[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let itemToDelete = allItems[indexPath.row]
            allItems.remove(at: indexPath.row)
            tableView.reloadData()
            
            removeItemFromBasket(itemId: itemToDelete.id)
            updateBasketInFirestore(basket!, withValues: [kITEMIDS: basket?.itemIds]) { error in
                if error != nil {
                    print("error updating the basket", error!.localizedDescription)
                }
                self.getBasketItems()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showItemView(withItem: allItems[indexPath.item])
    }
}

func downloadItems(_ withIds: [String], completion: @escaping (_ itemArray: [Item]) ->Void) {
    
    var count = 0
    var itemArray: [Item] = []
    
    if withIds.count > 0 {
        
        for itemId in withIds {
            
            FirebaseReference(.Items).document(itemId).getDocument { (snapshot, error) in
                
                guard let snapshot = snapshot else {
                    completion(itemArray)
                    return
                }
                
                if snapshot.exists {
                    
                    itemArray.append(Item(_dictionary: snapshot.data()! as NSDictionary))
                    count += 1
                    
                } else {
                    completion(itemArray)
                }
                
                if count == withIds.count {
                    completion(itemArray)
                }
                
            }
        }
    } else {
        completion(itemArray)
    }
    
}

extension BasketViewController: CardInfoControllerDelegate {
    
    func didClickDone(_ token: STPToken) {
        finishPayment(token: token)
    }
    
    func didClickCancel() {
        showNotification(text: "Payment Canceled", isError: true)
    }
}
