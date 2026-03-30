import Foundation
import Supabase

// Shared provider to fetch mentors from Supabase with tolerant parsing of rows
enum MentorsProvider {
    static func rowsArray(from raw: Any?) throws -> [Any]? {
        guard let raw = raw else { return nil }
        if let arr = raw as? [Any] { return arr }
        if let dict = raw as? [String: Any] {
            let candidateKeys = ["data", "result", "rows", "payload"]
            for k in candidateKeys {
                if let v = dict[k] as? [Any] { return v }
            }
            for (_, v) in dict {
                if let a = v as? [Any] { return a }
            }
        }
        if let data = raw as? Data {
            let json = try JSONSerialization.jsonObject(with: data)
            if let arr = json as? [Any] { return arr }
            if let dict = json as? [String: Any] {
                let candidateKeys = ["data", "result", "rows", "payload"]
                for k in candidateKeys {
                    if let v = dict[k] as? [Any] { return v }
                }
                for (_, v) in dict {
                    if let a = v as? [Any] { return a }
                }
            }
        }
        if let s = raw as? String, let data = s.data(using: .utf8) {
            let json = try JSONSerialization.jsonObject(with: data)
            if let arr = json as? [Any] { return arr }
            if let dict = json as? [String: Any] {
                let candidateKeys = ["data", "result", "rows", "payload"]
                for k in candidateKeys {
                    if let v = dict[k] as? [Any] { return v }
                }
                for (_, v) in dict {
                    if let a = v as? [Any] { return a }
                }
            }
        }
        return nil
    }

    static func parseMentors(from rows: [Any]) -> [Mentor] {
        var mapped: [Mentor] = []
        for item in rows {
            if let dict = item as? [String: Any] {
                let id = (dict["id"] as? String) ?? (dict["ID"] as? String)
                let displayName = (dict["display_name"] as? String) ?? (dict["displayName"] as? String) ?? (dict["name"] as? String)
                let role = (dict["role"] as? String) ?? ""
                let rating = (dict["rating"] as? Double) ?? (dict["rating"] as? NSNumber)?.doubleValue ?? 0.0
                let profileUrl = (dict["profile_picture_url"] as? String) ?? (dict["profilePictureUrl"] as? String)
                let ratingCount = (dict["rating_count"] as? Int) ?? (dict["ratingCount"] as? Int)
                var areas: [String]? = nil
                if let arr = dict["mentorship_areas"] as? [Any] {
                    areas = arr.compactMap { $0 as? String }
                } else if let s = dict["mentorship_areas"] as? String, let data = s.data(using: .utf8) {
                    if let json = try? JSONSerialization.jsonObject(with: data), let arr = json as? [Any] {
                        areas = arr.compactMap { $0 as? String }
                    }
                }
                let about = (dict["about"] as? String)
                let userId = (dict["user_id"] as? String) ?? (dict["userId"] as? String)
                var metadataJson: String? = nil
                if let meta = dict["metadata"] {
                    if let s = meta as? String { metadataJson = s }
                    else if let obj = try? JSONSerialization.data(withJSONObject: meta), let str = String(data: obj, encoding: .utf8) { metadataJson = str }
                }
                let createdAt = (dict["created_at"] as? String) ?? (dict["createdAt"] as? String)
                // orgName comes from `name` column; session from `session`; money from `money` column
                let orgName = (dict["name"] as? String) ?? (dict["org"] as? String)
                let sessionCount = (dict["session"] as? Int) ?? (dict["session"] as? NSNumber)?.intValue

                // Money/price parsing: accept String or numeric types and format as integer rupees
                var moneyString: String? = nil
                if let s = dict["money"] as? String, let d = Double(s) {
                    moneyString = "₹ \(Int(d))"
                } else if let s = dict["price"] as? String, let d = Double(s) {
                    moneyString = "₹ \(Int(d))"
                } else if let n = dict["money"] as? NSNumber {
                    moneyString = "₹ \(Int(n.doubleValue))"
                } else if let n = dict["price"] as? NSNumber {
                    moneyString = "₹ \(Int(n.doubleValue))"
                } else if let cents = dict["price_cents"] as? NSNumber {
                    moneyString = "₹ \(Int(cents.intValue / 100))"
                } else if let cents = dict["price_cents"] as? Int {
                    moneyString = "₹ \(cents / 100)"
                } else if let s = dict["money"] as? String {
                    // fallback: show raw string prefixed with ₹
                    moneyString = "₹ \(s)"
                } else if let s = dict["price"] as? String {
                    moneyString = "₹ \(s)"
                }

                let mentor = Mentor(id: id,
                                    name: displayName ?? "Unknown",
                                    role: role,
                                    rating: rating,
                                    imageName: nil,
                                    profilePictureUrl: profileUrl,
                                    ratingCount: ratingCount,
                                    mentorshipAreas: areas,
                                    orgName: orgName,
                                    sessionCount: sessionCount,
                                    moneyString: moneyString,
                                    about: about,
                                    userId: userId,
                                    metadataJson: metadataJson,
                                    createdAt: createdAt)
                mapped.append(mentor)
            }
        }
        return mapped
    }

    static func fetchAll() async -> [Mentor] {
        do {
            var res = try await supabase.database.from("mentor_profiles").select().order("rating", ascending: false).execute()
            // handle error embedded in response
            if let err = (res as AnyObject).error {
                let msg = String(describing: err)
                if msg.contains("does not exist") {
                    res = try await supabase.database.from("mentor_profiles").select().order("rating", ascending: false).execute()
                }
            }
            if let rows = try rowsArray(from: res.data), !rows.isEmpty {
                return parseMentors(from: rows)
            }
            if let raw = res.data as? Data {
                let json = try JSONSerialization.jsonObject(with: raw)
                if let arr = json as? [Any], !arr.isEmpty {
                    return parseMentors(from: arr)
                }
            }
            return []
        } catch {
            print("[MentorsProvider] fetch error: \(error)")
            return []
        }
    }
}
