//
//  BitcoinView.swift
//  TransactionsTestTask
//
//

import UIKit

final class BitcoinView: UIView {
    enum BitcoinViewEvent {
        case startFetching
        case stopFetching
    }

    var onEvent: ((BitcoinViewEvent) -> Void)?

    // MARK: - Private Properties

    private let titleLabel = UILabel()
    private let priceLabel = UILabel()
    private let changeLabel = UILabel()
    private let rankLabel = UILabel()
    private let marketCapLabel = UILabel()
    private let volumeLabel = UILabel()
    private let supplyLabel = UILabel()
    private let lastUpdatedLabel = UILabel()
    private let startButton = UIButton(configuration: .bordered())
    private let stopButton = UIButton(configuration: .bordered())
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    private let cardView = UIView()
    private let headerStackView = UIStackView()
    private let detailsStackView = UIStackView()
    private let buttonStackView = UIStackView()

    // MARK: - Initialisers

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Methods


    func updateFetchingState(_ isFetching: Bool) {
        if isFetching {
            activityIndicator.startAnimating()
            startButton.isEnabled = false
            stopButton.isEnabled = true
        } else {
            stopButton.isEnabled = false
            startButton.isEnabled = true
            activityIndicator.stopAnimating()
        }
    }

    func updateUI(with uiModel: BitcoinUIModel) {
        priceLabel.text = uiModel.price
        changeLabel.text = uiModel.change
        changeLabel.textColor = uiModel.changeColor
        rankLabel.text = uiModel.rank
        marketCapLabel.text = uiModel.marketCap
        volumeLabel.text = uiModel.volume
        supplyLabel.text = uiModel.supply
        lastUpdatedLabel.text = uiModel.lastUpdated
    }
}

// MARK: - Private methods

private extension BitcoinView {

    func setupView() {
        backgroundColor = .systemBackground
        
        setupCardView()
        setupStackViews()
        setupLabels()
        setupButtons()
        setupActivityIndicator()
        setupConstraints()
    }

    func setupCardView() {
        cardView.backgroundColor = .secondarySystemBackground
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.1
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 8
        
    }
    
    func setupStackViews() {
        cardView.addSubview(headerStackView)
        cardView.addSubview(detailsStackView)

        headerStackView.axis = .vertical
        headerStackView.alignment = .center
        headerStackView.spacing = 8

        detailsStackView.axis = .vertical
        detailsStackView.alignment = .leading
        detailsStackView.spacing = 12
    }
    
    func setupLabels() {
        let allLabels = [titleLabel, priceLabel, changeLabel, rankLabel, marketCapLabel, volumeLabel, supplyLabel, lastUpdatedLabel]
        allLabels.forEach { $0.numberOfLines = 0 }
        
        // Add header labels to header stack
        headerStackView.addArrangedSubview(titleLabel)
        headerStackView.addArrangedSubview(priceLabel)
        headerStackView.addArrangedSubview(changeLabel)
        
        // Add detail labels to details stack
        detailsStackView.addArrangedSubview(rankLabel)
        detailsStackView.addArrangedSubview(marketCapLabel)
        detailsStackView.addArrangedSubview(volumeLabel)
        detailsStackView.addArrangedSubview(supplyLabel)
        
        // Last updated label stays separate
        cardView.addSubview(lastUpdatedLabel)
        
        titleLabel.text = "Bitcoin (BTC)"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        
        priceLabel.text = "Price: Loading..."
        priceLabel.font = .systemFont(ofSize: 32, weight: .heavy)
        priceLabel.textColor = .systemBlue
        priceLabel.textAlignment = .center
        
        changeLabel.text = "24h Change: Loading..."
        changeLabel.font = .systemFont(ofSize: 18, weight: .medium)
        changeLabel.textAlignment = .center
        
        rankLabel.text = "Rank: Loading..."
        rankLabel.font = .systemFont(ofSize: 16, weight: .regular)
        
        marketCapLabel.text = "Market Cap: Loading..."
        marketCapLabel.font = .systemFont(ofSize: 16, weight: .regular)
        
        volumeLabel.text = "24h Volume: Loading..."
        volumeLabel.font = .systemFont(ofSize: 16, weight: .regular)
        
        supplyLabel.text = "Supply: Loading..."
        supplyLabel.font = .systemFont(ofSize: 16, weight: .regular)
        
        lastUpdatedLabel.text = "Last Updated: Never"
        lastUpdatedLabel.font = .systemFont(ofSize: 14, weight: .light)
        lastUpdatedLabel.textColor = .secondaryLabel
        lastUpdatedLabel.textAlignment = .center
    }
    
    func setupButtons() {
        buttonStackView.axis = .horizontal
        buttonStackView.alignment = .fill
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 16
        buttonStackView.addArrangedSubview(startButton)
        buttonStackView.addArrangedSubview(stopButton)

        startButton.configuration?.title = "Start"
        startButton.onTapEvent { [weak self] in
            self?.onEvent?(.startFetching)
        }
        stopButton.configuration?.title = "Stop"
        stopButton.onTapEvent { [weak self] in
            self?.onEvent?(.stopFetching)
        }
    }
    
    func setupActivityIndicator() {
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .systemBlue
    }
    
    func setupConstraints() {
        addSubview(cardView)
        addSubview(buttonStackView)
        addSubview(activityIndicator)

        let horizontalMargin: CGFloat = 16
        let safeAreaMargin: CGFloat = 20
        let sectionSpacing: CGFloat = 24
        let buttonHeight: CGFloat = 50
        
        cardView.layout {
            $0.top == safeAreaLayoutGuide.topAnchor + safeAreaMargin
            $0.leading == leadingAnchor + horizontalMargin
            $0.trailing == trailingAnchor - horizontalMargin
            $0.bottom <= activityIndicator.topAnchor - horizontalMargin
        }
        
        headerStackView.layout {
            $0.top == cardView.topAnchor + sectionSpacing
            $0.leading == cardView.leadingAnchor + horizontalMargin
            $0.trailing == cardView.trailingAnchor - horizontalMargin
        }
        
        detailsStackView.layout {
            $0.top == headerStackView.bottomAnchor + sectionSpacing
            $0.leading == cardView.leadingAnchor + horizontalMargin
            $0.trailing == cardView.trailingAnchor - horizontalMargin
        }
        
        lastUpdatedLabel.layout {
            $0.top == detailsStackView.bottomAnchor + sectionSpacing
            $0.leading == cardView.leadingAnchor + horizontalMargin
            $0.trailing == cardView.trailingAnchor - horizontalMargin
            $0.bottom == cardView.bottomAnchor - sectionSpacing
        }

        buttonStackView.layout {
            $0.leading == leadingAnchor + horizontalMargin
            $0.trailing == trailingAnchor - horizontalMargin
            $0.height == buttonHeight
            $0.bottom == safeAreaLayoutGuide.bottomAnchor - safeAreaMargin
        }

        activityIndicator.layout {
            $0.centerX == centerXAnchor
            $0.bottom == buttonStackView.topAnchor - horizontalMargin
        }
    }
}
