//
//  ErrorSimulatorViewController.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/09.
//

import AsyncNetwork
import Combine
import UIKit

/// Error Simulator 화면 ViewController
final class ErrorSimulatorViewController: UITableViewController {
    // MARK: - Types

    private enum Section: Int, CaseIterable {
        case errorType
        case actions
        case results

        var title: String {
            switch self {
            case .errorType: return "에러 타입 선택"
            case .actions: return "동작"
            case .results: return "시뮬레이션 결과"
            }
        }
    }

    // MARK: - Properties

    private let viewModel: ErrorSimulatorViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(viewModel: ErrorSimulatorViewModel) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }

    // MARK: - Setup

    private func setupUI() {
        title = "Error Simulator"
        navigationController?.navigationBar.prefersLargeTitles = true

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(ResultTableViewCell.self, forCellReuseIdentifier: "ResultCell")
    }

    private func bindViewModel() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in _: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }

        switch section {
        case .errorType: return SimulatedErrorType.allCases.count
        case .actions: return 2 // Start/Cancel, Clear
        case .results: return max(viewModel.state.results.count, 1) // 최소 1개 (안내 메시지)
        }
    }

    override func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section)?.title
    }

    override func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }

        switch section {
        case .errorType:
            return configureErrorTypeCell(at: indexPath)
        case .actions:
            return configureActionCell(at: indexPath)
        case .results:
            return configureResultCell(at: indexPath)
        }
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let section = Section(rawValue: indexPath.section) else { return }

        switch section {
        case .errorType:
            let errorType = SimulatedErrorType.allCases[indexPath.row]
            viewModel.send(.errorTypeSelected(errorType))

        case .actions:
            if indexPath.row == 0 {
                // Start/Cancel
                if viewModel.state.isSimulating {
                    viewModel.send(.cancelSimulationTapped)
                } else {
                    viewModel.send(.startSimulationTapped)
                }
            } else {
                // Clear
                viewModel.send(.clearResultsTapped)
            }

        case .results:
            break
        }
    }

    // MARK: - Cell Configuration

    private func configureErrorTypeCell(at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let errorType = SimulatedErrorType.allCases[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = errorType.displayName
        config.secondaryText = errorType.description
        config.image = UIImage(systemName: errorType.icon)
        config.imageProperties.tintColor = errorType == .none ? .systemGreen : .systemOrange

        cell.contentConfiguration = config
        cell.accessoryType = viewModel.state.selectedErrorType == errorType ? .checkmark : .none

        return cell
    }

    private func configureActionCell(at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        var config = cell.defaultContentConfiguration()

        if indexPath.row == 0 {
            // Start/Cancel Button
            if viewModel.state.isSimulating {
                config.text = "시뮬레이션 취소"
                config.image = UIImage(systemName: "stop.circle.fill")
                config.imageProperties.tintColor = .systemRed
            } else {
                config.text = "시뮬레이션 시작"
                config.image = UIImage(systemName: "play.circle.fill")
                config.imageProperties.tintColor = .systemBlue
            }
        } else {
            // Clear Button
            config.text = "결과 초기화"
            config.image = UIImage(systemName: "trash.circle.fill")
            config.imageProperties.tintColor = .systemGray
        }

        cell.contentConfiguration = config

        return cell
    }

    private func configureResultCell(at indexPath: IndexPath) -> UITableViewCell {
        if viewModel.state.results.isEmpty {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

            var config = cell.defaultContentConfiguration()
            config.text = "결과가 없습니다"
            config.textProperties.color = .secondaryLabel
            config.textProperties.alignment = .center

            cell.contentConfiguration = config
            cell.selectionStyle = .none

            return cell
        }

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "ResultCell",
            for: indexPath
        ) as? ResultTableViewCell else {
            return UITableViewCell()
        }

        let result = viewModel.state.results[indexPath.row]
        cell.configure(with: result)
        cell.selectionStyle = .none

        return cell
    }
}

// MARK: - ResultTableViewCell

/// 시뮬레이션 결과를 표시하는 커스텀 셀
final class ResultTableViewCell: UITableViewCell {
    override init(style _: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with result: ErrorSimulationResult) {
        var config = defaultContentConfiguration()

        config.text = result.displayMessage
        config.secondaryText = result.url

        if result.isSuccess {
            config.image = UIImage(systemName: "checkmark.circle.fill")
            config.imageProperties.tintColor = .systemGreen
        } else {
            config.image = UIImage(systemName: "xmark.circle.fill")
            config.imageProperties.tintColor = .systemRed
        }

        contentConfiguration = config
    }
}
