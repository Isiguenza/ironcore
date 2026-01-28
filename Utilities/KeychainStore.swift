import Foundation
import Security

class KeychainStore {
    static let shared = KeychainStore()
    
    private let service = "com.ironcore.app"
    private let jwtKey = "neon_jwt_token"
    private let userIdKey = "user_id"
    private let userNameKey = "user_name"
    
    private init() {}
    
    func saveJWT(_ jwt: String) throws {
        try save(key: jwtKey, value: jwt)
    }
    
    func getJWT() -> String? {
        return get(key: jwtKey)
    }
    
    func deleteJWT() throws {
        try delete(key: jwtKey)
    }
    
    func saveUserId(_ userId: String) throws {
        try save(key: userIdKey, value: userId)
    }
    
    func getUserId() -> String? {
        return get(key: userIdKey)
    }
    
    func deleteUserId() throws {
        try delete(key: userIdKey)
    }
    
    func saveUserName(_ userName: String) throws {
        try save(key: userNameKey, value: userName)
    }
    
    func getUserName() -> String? {
        return get(key: userNameKey)
    }
    
    func deleteUserName() throws {
        try delete(key: userNameKey)
    }
    
    func clearAll() throws {
        try? deleteJWT()
        try? deleteUserId()
        try? deleteUserName()
    }
    
    private func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingError
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    private func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    private func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

enum KeychainError: Error {
    case encodingError
    case saveFailed(OSStatus)
    case deleteFailed(OSStatus)
}
