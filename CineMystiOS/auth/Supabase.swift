//
//  Supabase.swift
//  CineMystApp
//
//  Created by user@50 on 19/11/25.
//



import Foundation
import Supabase

let supabase: SupabaseClient = {
    guard let url = URL(string: SupabaseConfig.urlString) else {
        fatalError("Invalid Supabase URL: \(SupabaseConfig.urlString)")
    }
    return SupabaseClient(
        supabaseURL: url,
        supabaseKey: SupabaseConfig.apiKey
    )
}()
