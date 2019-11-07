import UIKit

class ItemsTableViewController: UITableViewController {
    
    var category: Category?
    
    var itemArray: [Item] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        self.title = category?.name
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if category != nil {
            loadImage()
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return itemArray.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ItemTableViewCell
        cell.generateCell(itemArray[indexPath.row])
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "itemToAddItem" {
            let vc = segue.destination as! AddItemViewController
            vc.category = category!
        }
    }
    
    private func loadImage() {
        downloadItemsFromFirebase(withCategoryId: category!.id) { allItems in
            self.itemArray = allItems
            self.tableView.reloadData()
        }
    }
}
