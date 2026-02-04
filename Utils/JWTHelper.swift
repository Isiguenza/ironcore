import Foundation

struct JWTHelper {
    struct DecodedJWT {
        let header: [String: Any]
        let payload: [String: Any]
        let expirationDate: Date?
        let issuedAt: Date?
        
        var isExpired: Bool {
            guard let expDate = expirationDate else { return false }
            return Date() >= expDate
        }
        
        var isExpiringSoon: Bool {
            guard let expDate = expirationDate else { return false }
            // Consider "expiring soon" if less than 5 minutes remain
            let fiveMinutesFromNow = Date().addingTimeInterval(300)
            return fiveMinutesFromNow >= expDate
        }
        
        var timeUntilExpiration: TimeInterval? {
            guard let expDate = expirationDate else { return nil }
            return expDate.timeIntervalSince(Date())
        }
    }
    
    static func decode(_ jwt: String) -> DecodedJWT? {
        let segments = jwt.components(separatedBy: ".")
        guard segments.count == 3 else {
            print("❌ [JWT] Invalid token format")
            return nil
        }
        
        // Decode header
        guard let headerData = base64UrlDecode(segments[0]),
              let header = try? JSONSerialization.jsonObject(with: headerData) as? [String: Any] else {
            print("❌ [JWT] Failed to decode header")
            return nil
        }
        
        // Decode payload
        guard let payloadData = base64UrlDecode(segments[1]),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            print("❌ [JWT] Failed to decode payload")
            return nil
        }
        
        // Extract expiration (exp) and issued at (iat)
        var expirationDate: Date?
        if let exp = payload["exp"] as? TimeInterval {
            expirationDate = Date(timeIntervalSince1970: exp)
        }
        
        var issuedAt: Date?
        if let iat = payload["iat"] as? TimeInterval {
            issuedAt = Date(timeIntervalSince1970: iat)
        }
        
        return DecodedJWT(
            header: header,
            payload: payload,
            expirationDate: expirationDate,
            issuedAt: issuedAt
        )
    }
    
    private static func base64UrlDecode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let padLength = (4 - base64.count % 4) % 4
        base64.append(String(repeating: "=", count: padLength))
        
        return Data(base64Encoded: base64)
    }
    
    static func printTokenInfo(_ jwt: String) {
        guard let decoded = decode(jwt) else {
            print("❌ [JWT] Could not decode token")
            return
        }
        
        print("📋 [JWT] Token Info:")
        print("   Header: \(decoded.header)")
        print("   Payload: \(decoded.payload)")
        
        if let exp = decoded.expirationDate {
            print("   Expires: \(exp)")
            print("   Is Expired: \(decoded.isExpired)")
            print("   Expiring Soon: \(decoded.isExpiringSoon)")
            if let timeLeft = decoded.timeUntilExpiration {
                print("   Time Left: \(Int(timeLeft / 60)) minutes")
            }
        }
        
        if let iat = decoded.issuedAt {
            print("   Issued: \(iat)")
        }
    }
}
