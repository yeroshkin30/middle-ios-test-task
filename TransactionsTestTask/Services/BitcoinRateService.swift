//
//  BitcoinRateService.swift
//  TransactionsTestTask
//
//

/// Rate Service should fetch data from https://api.coindesk.com/v1/bpi/currentprice.json
/// Fetching should be scheduled with dynamic update interval
/// Rate should be cached for the offline mode
/// The service should be covered by unit tests
protocol BitcoinRateService: AnyObject { }

final class BitcoinRateServiceImpl {

    // MARK: - Init
    
    init() {
        
    }
}

extension BitcoinRateServiceImpl: BitcoinRateService {
    
}
