/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main application delegate.
*/

import UIKit
import AuthenticationServices

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        appleIDProvider.getCredentialState(forUserID: KeychainItem.currentUserIdentifier) { (credentialState, error) in
            switch credentialState {
            case .authorized:
                // The Apple ID credential is valid.
                break
            case .revoked:
                // The Apple ID credential is revoked.
                break
            case .notFound:
                // No credential was found, so show the sign-in UI.
                DispatchQueue.main.async {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    guard let viewController = storyboard.instantiateViewController(withIdentifier: "loginViewController") as? LoginViewController
                        else { return }
                    viewController.modalPresentationStyle = .formSheet
                    viewController.isModalInPresentation = true
                    self.window?.rootViewController?.present(viewController, animated: true, completion: nil)
                }
            default:
                break
            }
        }
        return true
    }
}
