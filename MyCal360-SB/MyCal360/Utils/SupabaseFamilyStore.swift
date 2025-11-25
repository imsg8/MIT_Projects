//
//  SupabaseFamilyStore.swift
//  MyCal360
//
//  Created by ChatGPT on 23/11/2025.
//  Supabase-backed replacement for FamilyStore.
//  Replace your local FamilyData.swift with this file (or keep both and rename).
//

import Foundation

// -------------------------
// Config (set these to your values)
struct Supabase {
    static let baseURL = "https://zjswnutnpopqqawyxujb.supabase.co"
    static let publishableKey = "sb_publishable_Tg8SFkKZ6zX_HIiHSC4LOA_TaUcq177"
    // convenience
    static var restURL: String { "\(baseURL)/rest/v1" }
    static var defaultHeaders: [String:String] {
        [
            "apikey": publishableKey,
            "Authorization": "Bearer \(publishableKey)",
            "Content-Type": "application/json",
            // Ask PostgREST to return created/updated rows on POST/PATCH
            "Prefer": "return=representation"
        ]
    }
}

// -------------------------
// Models (local app models kept same)
public struct FamilyMember: Codable, Equatable {
    public var id = UUID()
    public var name: String
    public var age: Int
    public var height: Double
    public var gender: String
    public var weights: [WeightEntry] = []
    
    public init(id: UUID = UUID(), name: String, age: Int, height: Double, gender: String, weights: [WeightEntry] = []) {
        self.id = id
        self.name = name
        self.age = age
        self.height = height
        self.gender = gender
        self.weights = weights
    }
}

public struct WeightEntry: Codable, Equatable {
    public var id: UUID? = nil
    public var date: Date
    public var weight: Double
    
    public init(id: UUID? = nil, date: Date, weight: Double) {
        self.id = id
        self.date = date
        self.weight = weight
    }
}

// -------------------------
// DTOs that mirror Supabase tables (server returns string uuids -> we convert)
private struct MemberDTO: Codable {
    var id: String?
    var user_id: String
    var full_name: String
    var age: Int?
    var height_cm: Double?
    var gender: String?
    var metadata: [String: AnyCodable]?
    var created_at: String?
    var updated_at: String?
    var is_deleted: Bool?
}

private struct WeightDTO: Codable {
    var id: String?
    var member_id: String?
    var user_id: String?
    var entry_date: String     // "YYYY-MM-DD"
    var weight_kg: Double
    var source: String?
    var notes: String?
    var created_at: String?
    var updated_at: String?
    var is_deleted: Bool?
}

// Small helper to allow decoding jsonb -> native (minimal)
private struct AnyCodable: Codable {
    let value: Any
    init(_ value: Any) { self.value = value }
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Bool.self) { value = v; return }
        if let v = try? container.decode(Int.self) { value = v; return }
        if let v = try? container.decode(Double.self) { value = v; return }
        if let v = try? container.decode(String.self) { value = v; return }
        if let v = try? container.decode([String: AnyCodable].self) {
            value = v.mapValues { $0.value }; return
        }
        if let v = try? container.decode([AnyCodable].self) {
            value = v.map { $0.value }; return
        }
        // fallback
        value = try container.decode(String.self)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let v as String: try container.encode(v)
        case let v as Int: try container.encode(v)
        case let v as Double: try container.encode(v)
        case let v as Bool: try container.encode(v)
        case let v as [String: Any]:
            try container.encode(v.mapValues { AnyCodable($0) })
        case let v as [Any]:
            try container.encode(v.map { AnyCodable($0) })
        default:
            try container.encode(String(describing: value))
        }
    }
}

// -------------------------
// FamilyStore backed by Supabase
final class FamilyStore {
    static let shared = FamilyStore()

    private init() {}

    /// current user id (must be set via configureForUser or externally)
    private(set) var userId: UUID?

    /// in-memory cache used by view controllers (keeps original FamilyMember model)
    private(set) var members: [FamilyMember] = []

    // MARK: - Configure

    /// Call after successful login with the user's UUID string (users_sb.id).
    /// Optionally set migrateLegacyIfPresent to true to push local data to Supabase if server side is empty.
    func configureForUser(id: String, migrateLegacyIfPresent migrate: Bool = false, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = UUID(uuidString: id) else {
            completion(.failure(NSError(domain: "FamilyStore", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid user id"])))
            return
        }
        self.userId = uid

        // fetch server data
        fetchMembersFromServer { result in
            switch result {
            case .success(let serverMembersExist):
                if migrate && !serverMembersExist {
                    // migrate local -> supabase
                    self.migrateLocalToSupabase { migrateResult in
                        switch migrateResult {
                        case .success:
                            self.fetchMembersFromServer { _ in completion(.success(())) } // best-effort reload
                        case .failure(let err):
                            completion(.failure(err))
                        }
                    }
                } else {
                    completion(.success(()))
                }
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    // quick helper to mutate local cache only (no server)
    func updateMemberLocallyOnly(_ updated: FamilyMember) {
        if let idx = members.firstIndex(where: { $0.id == updated.id }) {
            members[idx] = updated
        } else {
            members.append(updated)
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .familyStoreDidChange, object: nil)
        }
    }

    /// Call on logout to clear memory
    func signOut() {
        members = []
        userId = nil
    }

    // MARK: - Public synchronous helpers (to keep existing ViewController code mostly unchanged)
    /// load() now becomes async under the hood; this function triggers a fetch and calls completion
    func load(completion: ((Result<Void, Error>) -> Void)? = nil) {
        guard userId != nil else {
            // keep members empty if not configured
            members = []
            completion?(.success(()))
            return
        }
        fetchMembersFromServer(completion: { res in
            switch res {
            case .success:
                completion?(.success(()))
            case .failure(let err):
                completion?(.failure(err))
            }
        })
    }
    
    /// Refresh data from server without showing errors for first load
    func refreshFromServer(silent: Bool = false, completion: ((Bool) -> Void)? = nil) {
        fetchMembersFromServer { result in
            switch result {
            case .success(let hasData):
                completion?(true)
            case .failure(let error):
                if !silent {
                    print("⚠️ FamilyStore refresh failed: \(error.localizedDescription)")
                }
                completion?(false)
            }
        }
    }

    // MARK: - CRUD (members)

    /// Backwards-compatible synchronous add: triggers server POST in background and appends to local cache quickly.
    func addMember(_ member: FamilyMember) {
        // For backwards compatibility, but should migrate to async
        addMember(member) { result in
            if case .failure(let error) = result {
                print("⚠️ Background addMember failed: \(error.localizedDescription)")
                // Don't remove from local cache - let user retry
            }
        }
    }

    /// Async add with completion (server result)
    func addMember(_ member: FamilyMember, completion: @escaping (Result<FamilyMember, Error>) -> Void) {
        guard let uid = userId else {
            // add local-only and fail
            members.append(member)
            completion(.failure(NSError(domain: "FamilyStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "No user configured"])))
            return
        }

        let payload: [String: Any] = [
            "user_id": uid.uuidString,
            "full_name": member.name,
            "age": member.age,
            "height_cm": member.height,
            "gender": member.gender
        ]

        request(path: "family_members_sb", method: "POST", body: payload) { (result: Result<Data, Error>) in
            switch result {
            case .success(let data):
                // PostgREST returns created row (Prefer: return=representation)
                if let dtos = try? JSONDecoder().decode([MemberDTO].self, from: data),
                   let dto = dtos.first,
                   let createdIdString = dto.id,
                   let createdId = UUID(uuidString: createdIdString) {
                    var new = member
                    new.id = createdId // sync to server uuid

                    // replace local temporary member (match by name+maybe old id) -- best-effort
                    if let idx = self.members.firstIndex(where: { $0.id == member.id }) {
                        self.members[idx] = new
                    } else {
                        self.members.append(new)
                    }
                    // notify UI
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .familyStoreDidChange, object: nil)
                    }
                    completion(.success(new))
                } else {
                    completion(.failure(NSError(domain: "FamilyStore", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to parse created member"])))
                }
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    /// Backwards-compatible synchronous update: updates local cache and triggers background sync of member fields and any new weights.
    /// Backwards-compatible synchronous update: NO LONGER RECOMMENDED - use async version
    func updateMember(_ updated: FamilyMember) {
        // For backwards compatibility
        updateMember(updated) { result in
            if case .failure(let error) = result {
                print("⚠️ Background updateMember failed: \(error.localizedDescription)")
            }
        }
    }

    /// Async update (server-aware) - patches member fields and uploads any new weights (weights with id == nil)
    func updateMember(_ updated: FamilyMember, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = userId else { completion(.failure(NSError(domain: "FamilyStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "No user configured"]))); return }

        // Patch member fields
        let idString = updated.id.uuidString
        let payload: [String: Any] = [
            "full_name": updated.name,
            "age": updated.age,
            "height_cm": updated.height,
            "gender": updated.gender
        ]

        // Patch member itself
        request(path: "family_members_sb?id=eq.\(idString)", method: "PATCH", body: payload) { patchRes in
            switch patchRes {
            case .success:
                // Next: find new weights (id == nil) and POST them sequentially
                let newWeights = updated.weights.filter { $0.id == nil }
                if newWeights.isEmpty {
                    completion(.success(()))
                    return
                }

                // serially add new weights
                let group = DispatchGroup()
                var lastError: Error?
                for w in newWeights {
                    group.enter()
                    self.addWeight(memberId: updated.id, date: w.date, weightKg: w.weight) { res in
                        if case .failure(let err) = res { lastError = err }
                        group.leave()
                    }
                }

                group.notify(queue: .main) {
                    if let err = lastError { completion(.failure(err)) } else { completion(.success(())) }
                }
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .familyStoreDidChange, object: nil)
                }

            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    func deleteMember(_ member: FamilyMember, completion: @escaping (Result<Void, Error>) -> Void) {
        print("🟦 Deleting member from Supabase + local:", member.id.uuidString)

        // 1️⃣ Delete locally first
        self.members.removeAll { $0.id == member.id }

        // 2️⃣ DELETE from Supabase using SQL-style DELETE endpoint
        let path = "family_members_sb?id=eq.\(member.id.uuidString)"
        
        request(path: path, method: "DELETE", body: nil) { res in
            switch res {
            case .success:
                print("🟩 Supabase DELETE succeeded for:", member.id.uuidString)
                completion(.success(()))

            case .failure(let err):
                print("❌ Supabase DELETE failed:", err.localizedDescription)
                completion(.failure(err))
            }
        }
    }


    // MARK: - CRUD (weights)
    /// Adds a weight entry for a member (member.id must be server UUID)
    func addWeight(memberId: UUID, date: Date, weightKg: Double, notes: String? = nil, completion: @escaping (Result<WeightEntry, Error>) -> Void) {
        guard let uid = userId else { completion(.failure(NSError(domain: "FamilyStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "No user configured"]))); return }

        let dateStr = isoDateOnly(from: date) // "YYYY-MM-DD"
        let payload: [String: Any] = [
            "member_id": memberId.uuidString,
            "user_id": uid.uuidString,
            "entry_date": dateStr,
            "weight_kg": weightKg,
            "notes": notes ?? NSNull()
        ]

        request(path: "weight_entries_sb", method: "POST", body: payload) { res in
            switch res {
            case .success(let data):
                if let dtos = try? JSONDecoder().decode([WeightDTO].self, from: data),
                   let dto = dtos.first,
                   let wIdStr = dto.id,
                   let wUUID = UUID(uuidString: wIdStr),
                   let entryDate = self.dateFromYMD(dto.entry_date) {
                    let entry = WeightEntry(id: wUUID, date: entryDate, weight: dto.weight_kg)
                    // update local member cache (append)
                    if let idx = self.members.firstIndex(where: { $0.id == memberId }) {
                        self.members[idx].weights.append(entry)
                        self.members[idx].weights.sort { $0.date > $1.date }
                    }
                    completion(.success(entry))
                } else {
                    completion(.failure(NSError(domain: "FamilyStore", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to parse created weight"])))
                }
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

//    func deleteWeight(memberId: UUID, weightId: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
//        // Soft-delete: patch is_deleted = true
//        request(path: "weight_entries_sb?id=eq.\(weightId.uuidString)", method: "PATCH", body: ["is_deleted": true]) { res in
//            switch res {
//            case .success:
//                if let mIdx = self.members.firstIndex(where: { $0.id == memberId }) {
//                    self.members[mIdx].weights.removeAll { $0.id == weightId }
//                }
//                completion(.success(()))
//                DispatchQueue.main.async {
//                    NotificationCenter.default.post(name: .familyStoreDidChange, object: nil)
//                }
//            case .failure(let err):
//                completion(.failure(err))
//            }
//        }
//    }
    
    func deleteWeight(memberId: UUID, weightId: UUID, completion: @escaping (Result<Void, Error>) -> Void) {

        print("🟦 Calling Supabase SQL delete for weight:", weightId.uuidString)

        // SQL DELETE query
        let sql = """
            DELETE FROM weight_entries_sb
            WHERE id = '\(weightId.uuidString)';
        """

        let payload: [String: Any] = ["query": sql]

        // Use RPC exec_sql endpoint (same as member delete)
        request(path: "rpc/exec_sql", method: "POST", body: payload) { res in
            switch res {
            case .success:
                print("🟩 Supabase SQL delete success!")

                // ---- LOCAL DELETE ----
                if let mIdx = self.members.firstIndex(where: { $0.id == memberId }) {
                    self.members[mIdx].weights.removeAll { $0.id == weightId }
                }

                completion(.success(()))

                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .familyStoreDidChange, object: nil)
                }

            case .failure(let err):
                print("❌ Supabase SQL delete error:", err)
                completion(.failure(err))
            }
        }
    }


    // MARK: - Server fetch helpers

    /// Fetch members & weights (for current user) and populate local cache. Completion indicates whether server had any members (true/false)
    private func fetchMembersFromServer(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let uid = userId else {
            completion(.success(false))
            return
        }

        // 1) Fetch members for user
        let memberPath = "family_members_sb?user_id=eq.\(uid.uuidString)&is_deleted=eq.false&order=full_name.asc"
        request(path: memberPath, method: "GET", body: nil) { (res: Result<Data, Error>) in
            switch res {
            case .success(let data):
                let decoder = JSONDecoder()
                if let dtos = try? decoder.decode([MemberDTO].self, from: data) {
                    // 2) fetch weights for user (one call) and group by member_id
                    let weightsPath = "weight_entries_sb?user_id=eq.\(uid.uuidString)&is_deleted=eq.false&order=entry_date.desc"
                    self.request(path: weightsPath, method: "GET", body: nil) { weightRes in
                        switch weightRes {
                        case .success(let wdata):
                            var grouping: [UUID: [WeightEntry]] = [:]
                            if let wDtos = try? decoder.decode([WeightDTO].self, from: wdata) {
                                for w in wDtos {
                                    guard let midStr = w.member_id, let midUUID = UUID(uuidString: midStr) else { continue }
                                    if let date = self.dateFromYMD(w.entry_date) {
                                        let entryId = w.id.flatMap { UUID(uuidString: $0) }
                                        let entry = WeightEntry(id: entryId, date: date, weight: w.weight_kg)
                                        grouping[midUUID, default: []].append(entry)
                                    }
                                }
                            }
                            // Build local members array
                            var built: [FamilyMember] = []
                            for m in dtos {
                                guard let midStr = m.id, let midUUID = UUID(uuidString: midStr) else { continue }
                                let fm = FamilyMember(
                                    id: midUUID,
                                    name: m.full_name,
                                    age: m.age ?? 0,
                                    height: m.height_cm ?? 0.0,
                                    gender: m.gender ?? "",
                                    weights: grouping[midUUID] ?? []
                                )
                                built.append(fm)
                            }
                            self.members = built

                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: .familyStoreDidLoad, object: nil)
                                NotificationCenter.default.post(name: .familyStoreDidChange, object: nil)
                                NotificationCenter.default.post(name: .familyMembersUpdated, object: nil)
                            }
                            completion(.success(!built.isEmpty))

                        case .failure(let err):
                            completion(.failure(err))
                        }
                    }
                } else {
                    // no members on server (empty array or parse fail)
                    self.members = []
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .familyStoreDidLoad, object: nil)
                        NotificationCenter.default.post(name: .familyStoreDidChange, object: nil)
                        NotificationCenter.default.post(name: .familyMembersUpdated, object: nil)
                    }
                    completion(.success(false))
                }
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    // MARK: - Migration: push local UserDefaults to Supabase
    private func migrateLocalToSupabase(completion: @escaping (Result<Void, Error>) -> Void) {
        // Read legacy data (if present)
        let legacyKey = "storedFamilyMembers"
        guard let data = UserDefaults.standard.data(forKey: legacyKey),
              let localMembers = try? JSONDecoder().decode([FamilyMember].self, from: data),
              !localMembers.isEmpty else {
            completion(.success(())); return
        }
        // Iterate sequentially to create members and weights (conservative)
        let group = DispatchGroup()
        var lastError: Error?

        for lm in localMembers {
            group.enter()
            // create member
            let memberPayload: [String: Any] = [
                "user_id": userId!.uuidString,
                "full_name": lm.name,
                "age": lm.age,
                "height_cm": lm.height,
                "gender": lm.gender
            ]
            request(path: "family_members_sb", method: "POST", body: memberPayload) { res in
                switch res {
                case .success(let mdata):
                    if let created = try? JSONDecoder().decode([MemberDTO].self, from: mdata).first, let createdIdStr = created.id, let createdId = UUID(uuidString: createdIdStr) {
                        // create weights for that member
                        for w in lm.weights {
                            group.enter()
                            let payload: [String: Any] = [
                                "member_id": createdId.uuidString,
                                "user_id": self.userId!.uuidString,
                                "entry_date": self.isoDateOnly(from: w.date),
                                "weight_kg": w.weight
                            ]
                            self.request(path: "weight_entries_sb", method: "POST", body: payload) { wres in
                                if case .failure(let err) = wres { lastError = err }
                                group.leave()
                            }
                        }
                    } else {
                        lastError = NSError(domain: "FamilyStore", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to parse member on migration"])
                    }
                case .failure(let err):
                    lastError = err
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if let err = lastError { completion(.failure(err)) } else { completion(.success(())) }
        }
    }

    // MARK: - Networking helper
    private func request(path: String, method: String, body: Any? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        let urlString = Supabase.restURL + "/" + path
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "FamilyStore", code: 100, userInfo: [NSLocalizedDescriptionKey: "Bad URL: \(urlString)"])))
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        for (k,v) in Supabase.defaultHeaders { req.setValue(v, forHTTPHeaderField: k) }

        if let b = body {
            if method == "GET" || method == "DELETE" {
                // body usually ignored for GET/DELETE
            } else {
                // JSON encode - need to convert UUIDs to strings if present inside dicts
                if let dict = b as? [String: Any] {
                    // Convert values that are UUID or Date to a JSON-friendly form (string)
                    var encodable = [String: Any]()
                    for (k, v) in dict {
                        if let u = v as? UUID { encodable[k] = u.uuidString }
                        else if let d = v as? Date { encodable[k] = isoDateOnly(from: d) }
                        else { encodable[k] = v }
                    }
                    if let data = try? JSONSerialization.data(withJSONObject: encodable, options: []) {
                        req.httpBody = data
                    } else {
                        completion(.failure(NSError(domain: "FamilyStore", code: 101, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request body"])))
                        return
                    }
                } else {
                    if let data = try? JSONSerialization.data(withJSONObject: b, options: []) {
                        req.httpBody = data
                    } else {
                        completion(.failure(NSError(domain: "FamilyStore", code: 101, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request body"])))
                        return
                    }
                }
            }
        }

        let task = URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err { completion(.failure(err)); return }
            guard let http = resp as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "FamilyStore", code: 102, userInfo: [NSLocalizedDescriptionKey: "No HTTP response"])))
                return
            }
            guard (200...299).contains(http.statusCode) else {
                let body = String(data: data ?? Data(), encoding: .utf8) ?? ""
                print("❌ Supabase Error [\(http.statusCode)]: \(body)")
                let err = NSError(domain: "FamilyStore", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error: \(http.statusCode) — \(body)"])
                completion(.failure(err))
                return
            }
            completion(.success(data ?? Data()))
        }
        task.resume()
    }

    // MARK: - Date helpers
    private func isoDateOnly(from date: Date) -> String {
        let fmt = DateFormatter()
        fmt.calendar = Calendar(identifier: .gregorian)
        fmt.timeZone = TimeZone(secondsFromGMT: 0)
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }

    private func dateFromYMD(_ s: String) -> Date? {
        let fmt = DateFormatter()
        fmt.calendar = Calendar(identifier: .gregorian)
        fmt.timeZone = TimeZone(secondsFromGMT: 0)
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.date(from: s)
    }
}

extension Notification.Name {
    static let familyMembersUpdated = Notification.Name("familyMembersUpdated")
}
