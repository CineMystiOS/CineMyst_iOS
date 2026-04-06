//
//  AIAssistantViewController.swift
//  CineMystApp
//

import UIKit

final class AIAssistantViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    private let plum = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1)
    private let plumLight = UIColor(red: 163/255, green: 100/255, blue: 149/255, alpha: 1)
    private let plumMist = UIColor(red: 244/255, green: 239/255, blue: 243/255, alpha: 1)
    private let deepInk = UIColor(red: 42/255, green: 31/255, blue: 38/255, alpha: 1)
    private let backgroundGradient = CAGradientLayer()
    private let ambientGlowBottom = UIView()
    private let messagesTableView = UITableView(frame: .zero, style: .plain)
    private let composerContainer = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let textField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let heroCard = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
    private let chatService = AIChatService()
    private let conversationId = UUID().uuidString
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private var isSending = false {
        didSet {
            sendButton.isHidden = isSending
            activityIndicator.isHidden = !isSending
            if isSending {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
            textField.isEnabled = !isSending
        }
    }

    private var messages: [(text: String, isUser: Bool)] = [
        (
            "Hi, I’m CineMyst AI. I can help you discover mentors, compare specialties and prices, explore jobs, and guide you based on your profile.",
            false
        )
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "AI Concierge"
        navigationItem.largeTitleDisplayMode = .never
        setupBackground()
        setupNavigationAppearance()
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
        ambientGlowBottom.layer.cornerRadius = ambientGlowBottom.bounds.width / 2
    }

    private func setupBackground() {
        view.backgroundColor = plumMist

        backgroundGradient.colors = [
            UIColor(red: 252/255, green: 249/255, blue: 252/255, alpha: 1).cgColor,
            UIColor(red: 246/255, green: 239/255, blue: 245/255, alpha: 1).cgColor,
            UIColor(red: 241/255, green: 232/255, blue: 241/255, alpha: 1).cgColor
        ]
        backgroundGradient.startPoint = CGPoint(x: 0.1, y: 0.0)
        backgroundGradient.endPoint = CGPoint(x: 0.9, y: 1.0)
        view.layer.insertSublayer(backgroundGradient, at: 0)

        ambientGlowBottom.translatesAutoresizingMaskIntoConstraints = false
        ambientGlowBottom.backgroundColor = plumLight.withAlphaComponent(0.08)
        ambientGlowBottom.layer.borderWidth = 1
        ambientGlowBottom.layer.borderColor = UIColor.white.withAlphaComponent(0.14).cgColor
        view.addSubview(ambientGlowBottom)

        NSLayoutConstraint.activate([
            ambientGlowBottom.widthAnchor.constraint(equalToConstant: 200),
            ambientGlowBottom.heightAnchor.constraint(equalToConstant: 200),
            ambientGlowBottom.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -82),
            ambientGlowBottom.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 54)
        ])
    }

    private func setupNavigationAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: deepInk,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        appearance.shadowColor = .clear
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = deepInk
    }

    private func setupUI() {
        heroCard.translatesAutoresizingMaskIntoConstraints = false
        heroCard.layer.cornerRadius = 30
        heroCard.layer.masksToBounds = true
        heroCard.layer.borderWidth = 1
        heroCard.layer.borderColor = UIColor.white.withAlphaComponent(0.72).cgColor
        heroCard.layer.shadowColor = plum.cgColor
        heroCard.layer.shadowOpacity = 0.08
        heroCard.layer.shadowRadius = 24
        heroCard.layer.shadowOffset = CGSize(width: 0, height: 14)

        let orb = UIView()
        orb.translatesAutoresizingMaskIntoConstraints = false
        orb.layer.cornerRadius = 30
        orb.layer.masksToBounds = true

        let orbGradient = CAGradientLayer()
        orbGradient.colors = [
            plumLight.cgColor,
            plum.cgColor
        ]
        orbGradient.startPoint = CGPoint(x: 0.15, y: 0.0)
        orbGradient.endPoint = CGPoint(x: 0.85, y: 1.0)
        orb.layer.insertSublayer(orbGradient, at: 0)

        let orbIcon = UIImageView(image: UIImage(systemName: "sparkles"))
        orbIcon.translatesAutoresizingMaskIntoConstraints = false
        orbIcon.tintColor = .white
        orbIcon.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 27, weight: .bold)
        titleLabel.textColor = deepInk
        titleLabel.text = "Your CineMyst AI"

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.numberOfLines = 0
        subtitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        subtitleLabel.textColor = plum.withAlphaComponent(0.58)
        subtitleLabel.text = "Ask about mentors, jobs, portfolio fit, and what opportunities match you best."

        let chipStack = UIStackView()
        chipStack.translatesAutoresizingMaskIntoConstraints = false
        chipStack.axis = .horizontal
        chipStack.spacing = 8
        chipStack.alignment = .leading
        chipStack.distribution = .fillProportionally

        ["Mentors", "Jobs", "Portfolio Fit"].forEach { title in
            chipStack.addArrangedSubview(makeChip(title: title))
        }

        let heroGlow = UIView()
        heroGlow.translatesAutoresizingMaskIntoConstraints = false
        heroGlow.backgroundColor = plumLight.withAlphaComponent(0.10)
        heroGlow.layer.cornerRadius = 72

        view.addSubview(heroCard)
        heroCard.contentView.addSubview(heroGlow)
        heroCard.contentView.addSubview(orb)
        orb.addSubview(orbIcon)
        heroCard.contentView.addSubview(titleLabel)
        heroCard.contentView.addSubview(subtitleLabel)
        heroCard.contentView.addSubview(chipStack)

        messagesTableView.translatesAutoresizingMaskIntoConstraints = false
        messagesTableView.backgroundColor = .clear
        messagesTableView.separatorStyle = .none
        messagesTableView.dataSource = self
        messagesTableView.delegate = self
        messagesTableView.register(UITableViewCell.self, forCellReuseIdentifier: "MessageCell")
        messagesTableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)
        view.addSubview(messagesTableView)

        composerContainer.translatesAutoresizingMaskIntoConstraints = false
        composerContainer.layer.cornerRadius = 28
        composerContainer.layer.masksToBounds = true
        composerContainer.layer.borderWidth = 1
        composerContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.82).cgColor
        view.addSubview(composerContainer)

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.attributedPlaceholder = NSAttributedString(
            string: "Ask about mentors or jobs",
            attributes: [.foregroundColor: plum.withAlphaComponent(0.34)]
        )
        textField.borderStyle = .none
        textField.returnKeyType = .send
        textField.delegate = self
        textField.textColor = deepInk
        textField.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        composerContainer.contentView.addSubview(textField)

        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setImage(UIImage(systemName: "arrow.up"), for: .normal)
        sendButton.tintColor = .white
        sendButton.backgroundColor = plum
        sendButton.layer.cornerRadius = 18
        sendButton.layer.shadowColor = plum.cgColor
        sendButton.layer.shadowOpacity = 0.22
        sendButton.layer.shadowRadius = 12
        sendButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        composerContainer.contentView.addSubview(sendButton)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = plum
        activityIndicator.hidesWhenStopped = false
        activityIndicator.isHidden = true
        composerContainer.contentView.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            heroCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            heroCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            heroCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            heroGlow.widthAnchor.constraint(equalToConstant: 144),
            heroGlow.heightAnchor.constraint(equalToConstant: 144),
            heroGlow.trailingAnchor.constraint(equalTo: heroCard.contentView.trailingAnchor, constant: 42),
            heroGlow.topAnchor.constraint(equalTo: heroCard.contentView.topAnchor, constant: -26),

            orb.topAnchor.constraint(equalTo: heroCard.contentView.topAnchor, constant: 20),
            orb.leadingAnchor.constraint(equalTo: heroCard.contentView.leadingAnchor, constant: 18),
            orb.widthAnchor.constraint(equalToConstant: 60),
            orb.heightAnchor.constraint(equalToConstant: 60),

            orbIcon.centerXAnchor.constraint(equalTo: orb.centerXAnchor),
            orbIcon.centerYAnchor.constraint(equalTo: orb.centerYAnchor),
            orbIcon.widthAnchor.constraint(equalToConstant: 26),
            orbIcon.heightAnchor.constraint(equalToConstant: 26),

            titleLabel.topAnchor.constraint(equalTo: heroCard.contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: orb.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: heroCard.contentView.trailingAnchor, constant: -18),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: heroCard.contentView.trailingAnchor, constant: -18),

            chipStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 14),
            chipStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            chipStack.trailingAnchor.constraint(lessThanOrEqualTo: heroCard.contentView.trailingAnchor, constant: -18),
            chipStack.bottomAnchor.constraint(equalTo: heroCard.contentView.bottomAnchor, constant: -18),

            composerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            composerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            composerContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            composerContainer.heightAnchor.constraint(equalToConstant: 62),

            textField.leadingAnchor.constraint(equalTo: composerContainer.contentView.leadingAnchor, constant: 18),
            textField.centerYAnchor.constraint(equalTo: composerContainer.contentView.centerYAnchor),
            textField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -12),

            sendButton.trailingAnchor.constraint(equalTo: composerContainer.contentView.trailingAnchor, constant: -14),
            sendButton.centerYAnchor.constraint(equalTo: composerContainer.contentView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36),

            activityIndicator.centerXAnchor.constraint(equalTo: sendButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: sendButton.centerYAnchor),

            messagesTableView.topAnchor.constraint(equalTo: heroCard.bottomAnchor, constant: 12),
            messagesTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            messagesTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            messagesTableView.bottomAnchor.constraint(equalTo: composerContainer.topAnchor, constant: -10)
        ])

        orb.layoutIfNeeded()
        orbGradient.frame = orb.bounds
    }

    @objc private func sendTapped() {
        guard !isSending,
              let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return
        }
        messages.append((text, true))
        messages.append(("", false))
        textField.text = nil
        reloadMessages(animated: true)
        isSending = true

        Task { [weak self] in
            guard let self else { return }
            do {
                let userId = try await self.resolveCurrentUserId()
                do {
                    try await self.chatService.streamMessage(
                        userId: userId,
                        conversationId: self.conversationId,
                        message: text
                    ) { [weak self] delta in
                        guard let self else { return }
                        guard !delta.isEmpty else { return }
                        if let lastIndex = self.messages.indices.last {
                            self.messages[lastIndex].text += delta
                        }
                        self.reloadMessages(animated: false)
                    }
                } catch {
                    let fallbackReply = try await self.chatService.sendMessage(
                        userId: userId,
                        conversationId: self.conversationId,
                        message: text
                    )
                    await MainActor.run {
                        if let lastIndex = self.messages.indices.last, self.messages[lastIndex].isUser == false {
                            self.messages[lastIndex].text = fallbackReply
                        } else {
                            self.messages.append((fallbackReply, false))
                        }
                    }
                }
                await MainActor.run {
                    self.isSending = false
                    self.reloadMessages(animated: true)
                }
            } catch {
                await MainActor.run {
                    if let lastIndex = self.messages.indices.last, self.messages[lastIndex].isUser == false {
                        self.messages[lastIndex].text = self.userFacingMessage(for: error)
                    } else {
                        self.messages.append((self.userFacingMessage(for: error), false))
                    }
                    self.isSending = false
                    self.reloadMessages(animated: true)
                }
            }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTapped()
        return true
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        84
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let message = messages[indexPath.row]
        let bubble = UIView()
        bubble.translatesAutoresizingMaskIntoConstraints = false
        bubble.layer.cornerRadius = 24
        bubble.layer.masksToBounds = true
        bubble.layer.borderWidth = 1
        bubble.layer.borderColor = message.isUser
            ? UIColor.white.withAlphaComponent(0.16).cgColor
            : UIColor.white.withAlphaComponent(0.80).cgColor
        bubble.backgroundColor = message.isUser ? plum : UIColor.white.withAlphaComponent(0.72)

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.text = message.text
        label.textColor = message.isUser ? .white : deepInk

        cell.contentView.addSubview(bubble)
        bubble.addSubview(label)

        NSLayoutConstraint.activate([
            bubble.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
            bubble.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
            label.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 14),
            label.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -14),
            label.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -16),
        ])

        if message.isUser {
            NSLayoutConstraint.activate([
                bubble.leadingAnchor.constraint(greaterThanOrEqualTo: cell.contentView.leadingAnchor, constant: 74),
                bubble.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -8)
            ])
        } else {
            NSLayoutConstraint.activate([
                bubble.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 8),
                bubble.trailingAnchor.constraint(lessThanOrEqualTo: cell.contentView.trailingAnchor, constant: -74)
            ])
        }

        return cell
    }

    private func reloadMessages(animated: Bool) {
        messagesTableView.reloadData()
        let lastRow = max(messages.count - 1, 0)
        guard messages.indices.contains(lastRow) else { return }
        messagesTableView.scrollToRow(at: IndexPath(row: lastRow, section: 0), at: .bottom, animated: animated)
    }

    private func resolveCurrentUserId() async throws -> String {
        let session = try await supabase.auth.session
        return session.user.id.uuidString
    }

    private func userFacingMessage(for error: Error) -> String {
        let message = (error as NSError).localizedDescription.lowercased()
        if message.contains("syncqueryrequestbuilder") || message.contains("attribute 'select'") {
            return "CineMyst AI is temporarily unavailable while the assistant service is updating. Please try again in a little while."
        }
        return "I couldn't reach the CineMyst AI backend right now. Please try again in a moment."
    }

    private func makeChip(title: String) -> UIView {
        let label = PaddingLabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        label.textColor = plum
        label.insets = UIEdgeInsets(top: 7, left: 12, bottom: 7, right: 12)
        label.backgroundColor = UIColor.white.withAlphaComponent(0.72)
        label.layer.cornerRadius = 14
        label.layer.masksToBounds = true
        label.layer.borderWidth = 1
        label.layer.borderColor = UIColor.white.withAlphaComponent(0.72).cgColor
        return label
    }
}

private final class PaddingLabel: UILabel {
    var insets = UIEdgeInsets.zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
    }
}

private struct AIChatRequestBody: Encodable {
    let user_id: String
    let message: String
    let conversation_id: String
}

private struct AIChatResponseBody: Decodable {
    let answer: String
    let user_id: String
    let conversation_id: String
    let profile_summary: String
}

private struct AIStreamEvent: Decodable {
    let delta: String?
    let done: Bool?
    let error: String?
}

private final class AIChatService {
    private let session: URLSession
    private let baseURL: URL

    init(session: URLSession = .shared) {
        self.session = session
        if let configuredBaseURL = Bundle.main.object(forInfoDictionaryKey: "AI_CHATBOT_BASE_URL") as? String,
           let configuredURL = URL(string: configuredBaseURL),
           !configuredBaseURL.isEmpty {
            self.baseURL = configuredURL
        } else {
            self.baseURL = URL(string: "https://cinemyst-chatbot-backend.onrender.com")!
        }
    }

    func sendMessage(userId: String, conversationId: String, message: String) async throws -> String {
        var request = URLRequest(url: baseURL.appendingPathComponent("/v1/chat"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        request.httpBody = try JSONEncoder().encode(
            AIChatRequestBody(
                user_id: userId,
                message: message,
                conversation_id: conversationId
            )
        )

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "AIChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid server response."])
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            let bodyText = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw NSError(
                domain: "AIChatService",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: bodyText]
            )
        }

        let decoded = try JSONDecoder().decode(AIChatResponseBody.self, from: data)
        return decoded.answer
    }

    func streamMessage(
        userId: String,
        conversationId: String,
        message: String,
        onDelta: @escaping @MainActor (String) -> Void
    ) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("/v1/chat/stream"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 120
        request.httpBody = try JSONEncoder().encode(
            AIChatRequestBody(
                user_id: userId,
                message: message,
                conversation_id: conversationId
            )
        )

        let (bytes, response) = try await session.bytes(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "AIChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid server response."])
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            throw NSError(
                domain: "AIChatService",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Streaming request failed with status \(httpResponse.statusCode)."]
            )
        }

        for try await line in bytes.lines {
            guard line.hasPrefix("data: ") else { continue }
            let payloadString = String(line.dropFirst(6))
            guard let payloadData = payloadString.data(using: .utf8) else { continue }
            let event = try JSONDecoder().decode(AIStreamEvent.self, from: payloadData)

            if let error = event.error, !error.isEmpty {
                throw NSError(domain: "AIChatService", code: -2, userInfo: [NSLocalizedDescriptionKey: error])
            }
            if let delta = event.delta, !delta.isEmpty {
                await onDelta(delta)
            }
            if event.done == true {
                break
            }
        }
    }
}
