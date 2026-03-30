// CardModels.swift
// Simple in-memory card model + store

import Foundation

public struct Card {
    public var id: String = UUID().uuidString
    public var holderName: String
    public var number: String
    public var expiry: String
    public var cvv: String

    public init(id: String = UUID().uuidString,
                holderName: String,
                number: String,
                expiry: String,
                cvv: String) {
        self.id = id
        self.holderName = holderName
        self.number = number
        self.expiry = expiry
        self.cvv = cvv
    }
}

public final class CardStore {
    public static let shared = CardStore()
    private init() {}

    private(set) var currentCard: Card = Card(
        holderName: "ANSH GAUTAM",
        number: "3096 4347 8180",
        expiry: "02/27",
        cvv: "••••"
    )

    public func update(_ card: Card) {
        currentCard = card
        // Persist to UserDefaults/Keychain/backend if needed
        // e.g. UserDefaults.standard.set(...), Keychain for secure fields, etc.
    }
}
