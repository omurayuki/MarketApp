import Foundation
import UIKit
import InstantSearchClient

class Item {
    
    var id: String!
    var categoryId: String!
    var name: String!
    var description: String!
    var price: Double!
    var imageLinks: [String]!
    
    init() {
        
    }
    
    init(_dictionary: NSDictionary) {
        id = _dictionary[kOBJECTID] as? String
        categoryId = _dictionary[kCATEGORYID] as? String
        name = _dictionary[kNAME] as? String
        description = _dictionary[kDESCRIPTION] as? String
        price = _dictionary[kPRICE] as? Double
        imageLinks = _dictionary[kIMAGELINKS] as? [String]
    }
}

func saveItemToFirestore(_ item: Item) {
    FirebaseReference(.Items).document(item.id).setData(itemDictionaryFrom(item) as! [String: Any])
}

func itemDictionaryFrom(_ item: Item) -> NSDictionary {
    return NSDictionary(objects: [item.id, item.categoryId, item.name, item.description, item.price, item.imageLinks], forKeys: [kOBJECTID as NSCopying, kCATEGORYID as NSCopying, kNAME as NSCopying, kDESCRIPTION as NSCopying, kPRICE as NSCopying, kIMAGELINKS as NSCopying])
}

func downloadItemsFromFirebase(withCategoryId: String, completion: @escaping (_ itemArray: [Item]) -> Void) {
    var itemArray: [Item] = []
    FirebaseReference(.Items).whereField(kCATEGORYID, isEqualTo: withCategoryId).getDocuments { snapshot, error in
        guard let snapshot = snapshot else {
            completion(itemArray)
            return
        }
        
        if !snapshot.isEmpty {
            for itemDict in snapshot.documents {
                itemArray.append(Item(_dictionary: itemDict.data() as NSDictionary))
            }
        }
        
        completion(itemArray)
    }
}

func saveItemToAlgoria(item: Item) {
    let index = AlgoliaService.shared.index
    
    let itemToSave = itemDictionaryFrom(item) as! [String: Any]
    
    index.addObject(itemToSave, withID: item.id, requestOptions: nil) { (content, error) in
        if error != nil {
            print(error!.localizedDescription)
        } else {
            print("added to algoria")
        }
        
    }
}


func searchAlgolia(searchString: String, completion: @escaping (_ itemArray: [String]) -> Void) {
    
    let index = AlgoliaService.shared.index
    var resultIds: [String] = []
    
    let query = Query(query: searchString)
    
    query.attributesToRetrieve = ["name", "description"]
    
    index.search(query) { (content, error) in
        
        
        if error == nil {
            let cont = content!["hits"] as! [[String : Any]]
            
            resultIds = []
            
            for result in cont {
                resultIds.append(result["objectID"] as! String)
            }
            
            completion(resultIds)
        } else {
            print("Error algolia search ", error!.localizedDescription)
            completion(resultIds)
        }
    }
}
