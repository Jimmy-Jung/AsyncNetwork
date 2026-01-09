//
//  PostDetailViewController.swift
//  AsyncNetworkSampleApp
//
//  Created by jimmy on 2026/01/07.
//

import UIKit
import Combine
import AsyncViewModel

final class PostDetailViewController: UIViewController {
    
    // MARK: - UI Components
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.refreshControl = refreshControl
        return scrollView
    }()
    
    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
        return stackView
    }()
    
    private lazy var postTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var userIdLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var postBodyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.textColor = .label
        return label
    }()
    
    private lazy var divider: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .separator
        return view
    }()
    
    private lazy var commentsHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "댓글"
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        return label
    }()
    
    private lazy var commentsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        return stackView
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return control
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .systemRed
        label.isHidden = true
        return label
    }()
    
    private lazy var retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("다시 시도", for: .normal)
        button.addTarget(self, action: #selector(handleRetry), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    // MARK: - Properties
    
    private let viewModel: PostDetailViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(viewModel: PostDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        
        // viewDidAppear Input 전송
        viewModel.send(.viewDidAppear)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // cleanup Input 전송
        viewModel.send(.viewDidDisappear)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Post Detail"
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        view.addSubview(loadingIndicator)
        view.addSubview(errorLabel)
        view.addSubview(retryButton)
        
        scrollView.addSubview(contentStackView)
        
        contentStackView.addArrangedSubview(postTitleLabel)
        contentStackView.addArrangedSubview(userIdLabel)
        contentStackView.addArrangedSubview(postBodyLabel)
        contentStackView.addArrangedSubview(divider)
        contentStackView.addArrangedSubview(commentsHeaderLabel)
        contentStackView.addArrangedSubview(commentsStackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
            
            divider.heightAnchor.constraint(equalToConstant: 1),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            retryButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 20),
            retryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func setupBindings() {
        // Post 변경 구독
        viewModel.$state
            .map(\.post)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] post in
                self?.renderPost(post)
            }
            .store(in: &cancellables)
        
        // Comments 변경 구독
        viewModel.$state
            .map(\.comments)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] comments in
                self?.renderComments(comments)
            }
            .store(in: &cancellables)
        
        // Loading 상태 구독
        viewModel.$state
            .map(\.isLoading)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                    self?.refreshControl.endRefreshing()
                }
            }
            .store(in: &cancellables)
        
        // Error 상태 구독
        viewModel.$state
            .map(\.error)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.handleError(error)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Rendering
    
    private func renderPost(_ post: Post?) {
        guard let post = post else { return }
        
        postTitleLabel.text = post.title
        userIdLabel.text = "User ID: \(post.userId)"
        postBodyLabel.text = post.body
    }
    
    private func renderComments(_ comments: [Comment]) {
        // 기존 댓글 제거
        commentsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 새 댓글 추가
        comments.forEach { comment in
            let commentView = CommentView()
            commentView.configure(with: comment)
            commentsStackView.addArrangedSubview(commentView)
        }
        
        commentsHeaderLabel.text = "댓글 (\(comments.count))"
    }
    
    // MARK: - Actions
    
    @objc private func handleRefresh() {
        viewModel.send(.refreshButtonTapped)
    }
    
    @objc private func handleRetry() {
        viewModel.send(.retryButtonTapped)
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: SendableError?) {
        if let error = error {
            errorLabel.text = error.localizedDescription
            errorLabel.isHidden = false
            retryButton.isHidden = false
            scrollView.isHidden = true
        } else {
            errorLabel.isHidden = true
            retryButton.isHidden = true
            scrollView.isHidden = false
        }
    }
}

// MARK: - CommentView

private final class CommentView: UIView {
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let bodyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(emailLabel)
        containerView.addSubview(bodyLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            emailLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            emailLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            bodyLabel.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 8),
            bodyLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            bodyLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            bodyLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with comment: Comment) {
        nameLabel.text = comment.name
        emailLabel.text = comment.email
        bodyLabel.text = comment.body
    }
}

