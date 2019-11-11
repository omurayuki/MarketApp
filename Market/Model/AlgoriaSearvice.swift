import Foundation
import InstantSearchClient

class AlgoliaService {
    
    static let shared = AlgoliaService()
    
    let client = Client(appID: kALGORIA_APP_ID, apiKey: kALGORIA_ADMIN_KEY)
    let index = Client(appID: kALGORIA_APP_ID, apiKey: kALGORIA_ADMIN_KEY).index(withName: "item_Name")
    
    private init() {}
}
