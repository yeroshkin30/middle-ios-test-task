//
//  StorageServiceProtocol.swift
//  TransactionsTestTask
//
//  Created by Oleh Yeroshkin on 02.07.2025.
//

import Foundation

protocol StorageServiceProtocol: Actor {
    func saveBitcoinData(_ data: BitcoinData)
    func loadCachedBitcoinData() -> BitcoinData?
}

/// Simple implementation of a storage service using UserDefaults.
actor StorageService: StorageServiceProtocol {

    private let fileManager = FileManager.default
    private let fileName = "bitcoinData.json"

    private var fileURL: URL {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentDirectory.appendingPathComponent(fileName)
    }

    func saveBitcoinData(_ data: BitcoinData) {
        do {
            let encodedData = try JSONEncoder().encode(data)
            let url = fileURL
            try encodedData.write(to: url)
        } catch {
            print("Error saving bitcoin data: \(error)")
        }
    }

    func loadCachedBitcoinData() -> BitcoinData? {
        do {
            let url = fileURL
            let data = try Data(contentsOf: url)
            let bitcoinData = try JSONDecoder().decode(BitcoinData.self, from: data)
            return bitcoinData
        } catch {
            print("Error loading bitcoin data: \(error)")
            return nil
        }
    }
}
