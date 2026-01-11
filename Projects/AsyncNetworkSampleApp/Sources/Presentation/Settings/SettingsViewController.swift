//
//  SettingsViewController.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/09.
//

import AsyncNetwork
import Combine
import UIKit

/// Settings 화면 ViewController
final class SettingsViewController: UITableViewController {
    // MARK: - Types

    private enum Section: Int, CaseIterable {
        case networkStatus
        case configuration
        case retryPolicy
        case logging
        case developerTools
        case reset

        var title: String {
            switch self {
            case .networkStatus: return "네트워크 상태"
            case .configuration: return "네트워크 설정"
            case .retryPolicy: return "재시도 정책"
            case .logging: return "로깅 레벨"
            case .developerTools: return "개발자 도구"
            case .reset: return "초기화"
            }
        }
    }

    // MARK: - Properties

    private let viewModel: SettingsViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(viewModel: SettingsViewModel) {
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.send(.viewDidAppear)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.send(.viewDidDisappear)
    }

    // MARK: - Setup

    private func setupUI() {
        title = "설정"
        navigationController?.navigationBar.prefersLargeTitles = true

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(DetailTableViewCell.self, forCellReuseIdentifier: "DetailCell")
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
        case .networkStatus: return 3 // Status, Connection Type, Flags
        case .configuration: return NetworkConfigurationPreset.allCases.count
        case .retryPolicy: return RetryPolicyPreset.allCases.count
        case .logging: return LoggingLevel.allCases.count
        case .developerTools: return 1 // Error Simulator
        case .reset: return 1
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
        case .networkStatus:
            return configureNetworkStatusCell(at: indexPath)
        case .configuration:
            return configureConfigurationCell(at: indexPath)
        case .retryPolicy:
            return configureRetryPolicyCell(at: indexPath)
        case .logging:
            return configureLoggingCell(at: indexPath)
        case .developerTools:
            return configureDeveloperToolsCell(at: indexPath)
        case .reset:
            return configureResetCell(at: indexPath)
        }
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let section = Section(rawValue: indexPath.section) else { return }

        switch section {
        case .networkStatus:
            break // Read-only
        case .configuration:
            let preset = NetworkConfigurationPreset.allCases[indexPath.row]
            viewModel.send(.configurationPresetSelected(preset))
        case .retryPolicy:
            let preset = RetryPolicyPreset.allCases[indexPath.row]
            viewModel.send(.retryPolicyPresetSelected(preset))
        case .logging:
            let level = LoggingLevel.allCases[indexPath.row]
            viewModel.send(.loggingLevelSelected(level))
        case .developerTools:
            showErrorSimulator()
        case .reset:
            showResetConfirmation()
        }
    }

    // MARK: - Cell Configuration

    private func configureNetworkStatusCell(at indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "DetailCell",
            for: indexPath
        ) as? DetailTableViewCell else {
            return UITableViewCell()
        }
        let state = viewModel.state

        switch indexPath.row {
        case 0: // Status
            cell.configure(
                title: "상태",
                detail: state.networkStatus.displayName,
                detailColor: state.networkStatus.isConnected ? .systemGreen : .systemRed
            )
        case 1: // Connection Type
            cell.configure(
                title: "연결 유형",
                detail: state.networkStatus.connectionTypeDescription,
                detailColor: .secondaryLabel
            )
        case 2: // Flags
            let flags = [
                state.isExpensive ? "고비용" : nil,
                state.isConstrained ? "제한됨" : nil
            ].compactMap { $0 }.joined(separator: ", ")
            cell.configure(
                title: "플래그",
                detail: flags.isEmpty ? "없음" : flags,
                detailColor: .secondaryLabel
            )
        default:
            break
        }

        cell.selectionStyle = .none
        return cell
    }

    private func configureConfigurationCell(at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let preset = NetworkConfigurationPreset.allCases[indexPath.row]

        // 모든 속성 초기화
        var config = cell.defaultContentConfiguration()
        config.text = preset.displayName
        config.secondaryText = nil
        config.image = nil
        cell.contentConfiguration = config

        cell.accessoryType = viewModel.state.configurationPreset == preset ? .checkmark : .none

        return cell
    }

    private func configureRetryPolicyCell(at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let preset = RetryPolicyPreset.allCases[indexPath.row]

        // 모든 속성 초기화
        var config = cell.defaultContentConfiguration()
        config.text = "\(preset.displayName) (\(preset.maxRetries) 회 재시도)"
        config.secondaryText = nil
        config.image = nil
        cell.contentConfiguration = config

        cell.accessoryType = viewModel.state.retryPolicyPreset == preset ? .checkmark : .none

        return cell
    }

    private func configureLoggingCell(at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let level = LoggingLevel.allCases[indexPath.row]

        // 모든 속성 초기화
        var config = cell.defaultContentConfiguration()
        config.text = level.displayName
        config.secondaryText = nil
        config.image = nil
        cell.contentConfiguration = config

        cell.accessoryType = viewModel.state.loggingLevel == level ? .checkmark : .none

        return cell
    }

    private func configureDeveloperToolsCell(at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        var config = cell.defaultContentConfiguration()
        config.text = "Error Simulator"
        config.secondaryText = "네트워크 에러 시뮬레이션 및 재시도 테스트"
        config.image = UIImage(systemName: "hammer.circle.fill")
        config.imageProperties.tintColor = .systemOrange

        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    private func configureResetCell(at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        // 모든 속성 초기화
        var config = cell.defaultContentConfiguration()
        config.text = "기본값으로 초기화"
        config.textProperties.color = .systemRed
        config.textProperties.alignment = .center
        config.secondaryText = nil
        config.image = nil
        cell.contentConfiguration = config

        cell.accessoryType = .none

        return cell
    }

    // MARK: - Actions

    private func showErrorSimulator() {
        let errorSimulatorViewModel = ErrorSimulatorViewModel()
        let errorSimulatorVC = ErrorSimulatorViewController(viewModel: errorSimulatorViewModel)
        navigationController?.pushViewController(errorSimulatorVC, animated: true)
    }

    private func showResetConfirmation() {
        let alert = UIAlertController(
            title: "설정 초기화",
            message: "모든 설정을 기본값으로 초기화하시겠습니까?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "초기화", style: .destructive) { [weak self] _ in
            self?.viewModel.send(.resetToDefaultsTapped)
        })

        present(alert, animated: true)
    }
}

// MARK: - DetailTableViewCell

/// 상세 정보를 표시하는 커스텀 셀
final class DetailTableViewCell: UITableViewCell {
    override init(style _: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, detail: String, detailColor: UIColor) {
        textLabel?.text = title
        detailTextLabel?.text = detail
        detailTextLabel?.textColor = detailColor
    }
}
