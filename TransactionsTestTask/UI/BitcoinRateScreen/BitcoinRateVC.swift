//
//  ViewController.swift
//  TransactionsTestTask
//
//

import UIKit

final class BitcoinRateVC: UIViewController {

    // MARK: - Private properties
    
    private let mainView: BitcoinView = .init()
    private let viewModel: BitcoinRateViewModel

    // MARK: - Initialisers
    
    init(controller: BitcoinRateViewModel) {
        self.viewModel = controller
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Bitcoin Tracker"
        setup()
    }
    
    override func loadView() {
        view = mainView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupViewModel()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.stopFetching()
    }
}

// MARK: - Private methods

private extension BitcoinRateVC {
    
    func setup() {
        setupMainView()
    }

    func setupMainView() {
        mainView.onEvent = { [weak self] event in
            guard let self else { return }
            switch event {
            case .startFetching:
                viewModel.startFetching()
            case .stopFetching:
                viewModel.stopFetching()
            }
        }
    }

    func setupViewModel() {
        viewModel.onEvent = { [weak self] event in
            guard let self else { return }
            switch event {
            case .bitcoinDataFetched(let data):
                mainView.updateUI(with: data)
            case .fetchingStateChanged(let isFetching):
                mainView.updateFetchingState(isFetching)
            }
        }
        viewModel.startFetching()
    }
}
