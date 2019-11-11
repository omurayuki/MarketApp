import UIKit

class PurchasedHistoryTableViewController: UITableViewController {
    
    var itemArray : [Item] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loadItems()
    }

    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return itemArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ItemTableViewCell
        
        cell.generateCell(itemArray[indexPath.row])

        return cell
    }
    
    
    //MARK: - Load items
    
    private func loadItems() {
        
        downloadItems(MUser.currentUser()!.purchasedItemIds) { (allItems) in
            
            self.itemArray = allItems
            print("we have \(allItems.count) purchased items")
            self.tableView.reloadData()
        }
    }
}
