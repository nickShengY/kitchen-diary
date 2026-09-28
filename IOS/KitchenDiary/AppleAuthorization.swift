import AuthenticationServices
import CryptoKit
import FirebaseAuth
import Security
import UIKit

/// A fresh nonce binds the Apple response to this request. Tokens stay in memory.
@MainActor final class AppleAuthorization: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    struct Result {
        let credential: AuthCredential
        let authorizationCode: String
    }
    private var continuation: CheckedContinuation<Result, Error>?
    private var nonce: String?
    private var controller: ASAuthorizationController?
    private var window: UIWindow?

    static func randomNonce() throws -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
            throw AccountService.AccountError.configuration
        }
        return bytes.map { String(format: "%02x", $0) }.joined()
    }
    static func digest(_ nonce: String) -> String {
        SHA256.hash(data: Data(nonce.utf8)).map { String(format: "%02x", $0) }.joined()
    }
    func authorize() async throws -> Result {
        guard continuation == nil,
              let window = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
                .flatMap(\.windows).first(where: \.isKeyWindow) else {
            throw AccountService.AccountError.configuration
        }
        self.window = window
        let nonce = try Self.randomNonce()
        self.nonce = nonce
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.digest(nonce)
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            self.controller = controller
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        window ?? ASPresentationAnchor()
    }
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let apple = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce, let tokenData = apple.identityToken,
              let token = String(data: tokenData, encoding: .utf8),
              let codeData = apple.authorizationCode,
              let code = String(data: codeData, encoding: .utf8) else {
            finish(.failure(AccountService.AccountError.configuration)); return
        }
        finish(.success(Result(credential: OAuthProvider.appleCredential(withIDToken: token, rawNonce: nonce, fullName: apple.fullName), authorizationCode: code)))
    }
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        finish(.failure(error))
    }
    private func finish(_ result: Swift.Result<Result, Error>) {
        let continuation = continuation
        self.continuation = nil; nonce = nil; controller = nil; window = nil
        continuation?.resume(with: result)
    }
}
