//
//  SupabaseConfig.swift
//  CineMystApp
//
//  Created by user@50 on 19/11/25.
//


import Foundation


enum SupabaseConfig {
    static var urlString: String {
        guard let host = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_HOST") as? String,
              !host.isEmpty else {
            fatalError("SUPABASE_HOST not found in Info.plist.")
        }
        return "https://\(host)"
    }

    static var apiKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_KEY") as? String,
              !key.isEmpty else {
            fatalError("SUPABASE_KEY not found in Info.plist.")
        }
        return key
    }
}
