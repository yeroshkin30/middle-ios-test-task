import UIKit

struct BitcoinUIModel {
    let price: String
    let change: String
    let changeColor: UIColor
    let rank: String
    let marketCap: String
    let volume: String
    let supply: String
    let lastUpdated: String
}

extension BitcoinUIModel {
    init(from bitcoinData: BitcoinData) {
        self.price = Self.formatPrice(bitcoinData.priceUsd)
        
        let (changeText, changeColor) = Self.formatChange(bitcoinData.changePercent24Hr)
        self.change = changeText
        self.changeColor = changeColor
        
        self.rank = "Rank: #\(bitcoinData.rank)"
        self.marketCap = Self.formatCurrency(bitcoinData.marketCapUsd, prefix: "Market Cap: ")
        self.volume = Self.formatCurrency(bitcoinData.volumeUsd24Hr, prefix: "24h Volume: ")
        self.supply = Self.formatSupply(bitcoinData.supply)
        self.lastUpdated = "Last Updated: \(DateFormatter.shortTime.string(from: Date()))"
    }
    
    private static func formatPrice(_ priceString: String) -> String {
        Double(priceString).map { String(format: "$%.2f", $0) } ?? "N/A"
    }
    
    private static func formatChange(_ changeString: String) -> (String, UIColor) {
        guard let changeValue = Double(changeString) else {
            return ("24h Change: N/A", .label)
        }
        
        let changeText = String(format: "%.2f%%", changeValue)
        let color = changeValue >= 0 ? UIColor.systemGreen : UIColor.systemRed
        return ("24h Change: \(changeText)", color)
    }
    
    private static func formatCurrency(_ valueString: String, prefix: String) -> String {
        guard let value = Double(valueString) else {
            return "\(prefix)N/A"
        }
        return "\(prefix)\(formatLargeNumber(value))"
    }
    
    private static func formatSupply(_ supplyString: String) -> String {
        guard let supplyValue = Double(supplyString) else {
            return "Supply: N/A"
        }
        return "Supply: \(formatLargeNumber(supplyValue)) BTC"
    }
    
    private static func formatLargeNumber(_ number: Double) -> String {
        let billion = 1_000_000_000.0
        let million = 1_000_000.0
        let thousand = 1_000.0

        if number >= billion {
            return String(format: "$%.2fB", number / billion)
        } else if number >= million {
            return String(format: "$%.2fM", number / million)
        } else if number >= thousand {
            return String(format: "$%.2fK", number / thousand)
        } else {
            return String(format: "$%.2f", number)
        }
    }
}

private extension DateFormatter {
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}
