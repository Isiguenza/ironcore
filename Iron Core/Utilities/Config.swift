import Foundation

struct Config {
    static let neonDataAPIURL = "https://ep-soft-frost-ah5hpy9a.apirest.c-3.us-east-1.aws.neon.tech/neondb"
    static let neonAuthURL = "https://ep-soft-frost-ah5hpy9a.neonauth.c-3.us-east-1.aws.neon.tech/neondb/auth"
    
    static var dataAPIRestURL: String {
        return "\(neonDataAPIURL)/rest/v1"
    }
}
