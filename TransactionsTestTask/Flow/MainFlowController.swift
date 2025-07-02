//
//  MainFlowController.swift
//  TransactionsTestTask
//
//  Created by Oleh Yeroshkin on 29.06.2025.
//

import UIKit

final class MainFlowController: UINavigationController {

    private let dependencyContainer: DependencyContainer

    // MARK: - Initializer

    init(dependencyContainer: DependencyContainer = .init()) {
        self.dependencyContainer = dependencyContainer
        super.init(nibName: nil, bundle: nil)
    }


    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            await setupInitialViewController()
        }
    }
}

// MARK: - Private Methods

private extension MainFlowController {
    func setupInitialViewController() async {
        let service = await dependencyContainer.bitcoinRateService
        let dependency = BitcoinRateViewModel.Dependency(
            startFetching: { await service.startFetching() },
            stopFetching:  { await service.stopFetching() },
            getBitcoinDataStream: { await service.getBitcoinDataStream() }
        )

        let controller = BitcoinRateViewModel(dependency: dependency)
        let viewController = BitcoinRateVC(controller: controller)
        self.setViewControllers([viewController], animated: false)
    }
}
