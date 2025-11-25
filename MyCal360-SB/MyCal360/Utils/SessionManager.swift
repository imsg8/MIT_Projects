//
//  SessionManager.swift
//  MyCal360
//
//  Created by Shivang Gulati on 23/11/25.
//

import UIKit

class SessionManager {
    static let shared = SessionManager()
    
    private let sessionExpiryKey = "session_expiry_date"
    private let userIdKey = "user_id"
    private let sessionDuration: TimeInterval = 3 * 24 * 60 * 60 // 3 days in seconds
    
    private init() {}
    
    // MARK: - Save Session
    func saveSession(userId: String) {
        let expiryDate = Date().addingTimeInterval(sessionDuration)
        UserDefaults.standard.set(userId, forKey: userIdKey)
        UserDefaults.standard.set(expiryDate, forKey: sessionExpiryKey)
        print("✅ Session saved. Expires: \(expiryDate)")
    }
    
    // MARK: - Check if Session is Valid
    func isSessionValid() -> Bool {
        guard let expiryDate = UserDefaults.standard.object(forKey: sessionExpiryKey) as? Date,
              let userId = UserDefaults.standard.string(forKey: userIdKey),
              !userId.isEmpty else {
            print("⚠️ No session found")
            return false
        }
        
        let isValid = Date() < expiryDate
        if isValid {
            print("✅ Session valid until: \(expiryDate)")
            // Extend session on activity
            extendSession()
        } else {
            print("❌ Session expired")
            clearSession()
        }
        
        return isValid
    }
    
    // MARK: - Extend Session (reset expiry on activity)
    func extendSession() {
        guard let userId = UserDefaults.standard.string(forKey: userIdKey) else { return }
        let newExpiryDate = Date().addingTimeInterval(sessionDuration)
        UserDefaults.standard.set(newExpiryDate, forKey: sessionExpiryKey)
        print("🔄 Session extended until: \(newExpiryDate)")
    }
    
    // MARK: - Get Stored User ID
    func getUserId() -> String? {
        return UserDefaults.standard.string(forKey: userIdKey)
    }
    
    // MARK: - Clear Session (logout)
    func clearSession() {
        UserDefaults.standard.removeObject(forKey: userIdKey)
        UserDefaults.standard.removeObject(forKey: sessionExpiryKey)
        UserDefaults.standard.removeObject(forKey: "user_email")
        UserDefaults.standard.removeObject(forKey: "user_name")
        UserDefaults.standard.removeObject(forKey: "last_login_date")
        FamilyStore.shared.signOut()
        AuthSession.shared.currentUser = nil
        print("🚪 Session cleared")
    }
    
    // MARK: - Get Remaining Time
    func getRemainingSessionTime() -> String {
        guard let expiryDate = UserDefaults.standard.object(forKey: sessionExpiryKey) as? Date else {
            return "No active session"
        }
        
        let remaining = expiryDate.timeIntervalSinceNow
        if remaining <= 0 { return "Expired" }
        
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        
        if hours > 24 {
            let days = hours / 24
            return "\(days) day\(days == 1 ? "" : "s")"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }
}
