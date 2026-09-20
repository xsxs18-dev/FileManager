import LocalAuthentication

enum AuthenticationError: LocalizedError {
    case failed(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .failed(let message): return message
        case .cancelled: return String(localized: "Authentication cancelled.")
        }
    }
}

final class AuthenticationService {
    static let shared = AuthenticationService()

    func authenticate(reason: String) async throws {
        let context = LAContext()
        var evaluationError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &evaluationError) else {
            throw AuthenticationError.failed(evaluationError?.localizedDescription ?? String(localized: "Authentication not available."))
        }
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            if !success {
                throw AuthenticationError.failed(String(localized: "Authentication failed."))
            }
        } catch let laError as LAError {
            switch laError.code {
            case .userCancel, .systemCancel, .appCancel:
                throw AuthenticationError.cancelled
            default:
                throw AuthenticationError.failed(laError.localizedDescription)
            }
        } catch let error as AuthenticationError {
            throw error
        } catch {
            throw AuthenticationError.failed(error.localizedDescription)
        }
    }
}
