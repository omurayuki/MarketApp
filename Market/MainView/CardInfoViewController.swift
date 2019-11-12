import UIKit
import Stripe

protocol CardInfoControllerDelegate: NSObject {
    
    func didClickDone(_ token: STPToken)
    func didClickCancel()
}

class CardInfoViewController: UIViewController {

    @IBOutlet weak var doneButtonOutlet: UIButton!
    
    let paymentCardTextField = STPPaymentCardTextField()
    
    weak var delegate: CardInfoControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        paymentCardTextField.delegate = self
        view.addSubview(paymentCardTextField)
        paymentCardTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraint(NSLayoutConstraint(item: paymentCardTextField, attribute: .top, relatedBy: .equal, toItem: doneButtonOutlet, attribute: .bottom, multiplier: 1, constant: 30))
        view.addConstraint(NSLayoutConstraint(item: paymentCardTextField, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: -20))
        view.addConstraint(NSLayoutConstraint(item: paymentCardTextField, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 20))
        

    }
    @IBAction func doneButtonPressed(_ sender: Any) {
        processCard()
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        delegate?.didClickCancel()
        dismissView()
    }
    
    private func dismissView() {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func processCard() {
        let cardParams = STPCardParams()
        cardParams.number = paymentCardTextField.cardNumber
        cardParams.expMonth = paymentCardTextField.expirationMonth
        cardParams.expYear = paymentCardTextField.expirationYear
        cardParams.cvc = paymentCardTextField.cvc
        
        STPAPIClient.shared().createToken(withCard: cardParams) { (token, error) in
            if error == nil {
                self.delegate?.didClickDone(token!)
                self.dismissView()
            } else {
                print(error!.localizedDescription)
            }
        }
    }
}

extension CardInfoViewController: STPPaymentCardTextFieldDelegate {
    
    func paymentCardTextFieldDidChange(_ textField: STPPaymentCardTextField) {
        doneButtonOutlet.isEnabled = textField.isValid
    }
}
