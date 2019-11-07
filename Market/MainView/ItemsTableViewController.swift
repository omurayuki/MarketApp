import UIKit

class ItemsTableViewController: UITableViewController {
    
    var category: Category?
    
    var itemArray: [Item] = []

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return itemArray.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "itemToAddItem" {
            let vc = segue.destination as! AddItemViewController
            vc.category = category!
        }
    }
}
