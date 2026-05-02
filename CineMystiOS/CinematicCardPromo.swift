
import UIKit

// MARK: - Promo Manager
class CinematicCardPromoManager {
    static let shared = CinematicCardPromoManager()
    private let lastShownKey = "cinemyst.promo.lastShown"
    private let launchCountKey = "cinemyst.promo.launchCount"
    
    func shouldShowPromo() -> Bool {
        let currentCount = UserDefaults.standard.integer(forKey: launchCountKey)
        UserDefaults.standard.set(currentCount + 1, forKey: launchCountKey)
        
        // Only show every 5th time the screen is accessed
        if (currentCount + 1) % 5 != 0 { return false }
        
        // AND ensure at least 24 hours have passed since last time
        if let lastShown = UserDefaults.standard.object(forKey: lastShownKey) as? Date {
            let hours = Calendar.current.dateComponents([.hour], from: lastShown, to: Date()).hour ?? 0
            if hours < 24 { return false }
        }
        
        return true
    }
    
    func markShown() {
        UserDefaults.standard.set(Date(), forKey: lastShownKey)
    }
}

// MARK: - Promo View Controller
class CinematicCardPromoViewController: UIViewController {
    var onAction: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        
        let container = UIView()
        container.backgroundColor = UIColor(red: 0.12, green: 0.12, blue: 0.15, alpha: 1)
        container.layer.cornerRadius = 32
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        
        let icon = UIImageView(image: UIImage(systemName: "sparkles.rectangle.stack.fill"))
        icon.tintColor = UIColor(red: 0.95, green: 0.42, blue: 0.47, alpha: 1)
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(icon)
        
        let titleLbl = UILabel()
        titleLbl.text = "Elevate Your Art"
        titleLbl.font = UIFont.systemFont(ofSize: 28, weight: .black)
        titleLbl.textColor = .white
        titleLbl.textAlignment = .center
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLbl)
        
        let subLbl = UILabel()
        subLbl.text = "Generate your custom Gen-Z Cinematic Card and share your professional stats in style."
        subLbl.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        subLbl.textColor = .systemGray
        subLbl.numberOfLines = 0
        subLbl.textAlignment = .center
        subLbl.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(subLbl)
        
        let btn = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = "CREATE NOW"
        config.baseBackgroundColor = UIColor(red: 0.95, green: 0.42, blue: 0.47, alpha: 1)
        config.cornerStyle = .capsule
        btn.configuration = config
        btn.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(btn)
        
        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle("Maybe Later", for: .normal)
        closeBtn.setTitleColor(.systemGray2, for: .normal)
        closeBtn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(closeBtn)
        
        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            container.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            container.heightAnchor.constraint(equalToConstant: 420),
            
            icon.topAnchor.constraint(equalTo: container.topAnchor, constant: 40),
            icon.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            icon.widthAnchor.constraint(equalToConstant: 80),
            icon.heightAnchor.constraint(equalToConstant: 80),
            
            titleLbl.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 20),
            titleLbl.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            titleLbl.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            
            subLbl.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 12),
            subLbl.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 30),
            subLbl.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -30),
            
            btn.bottomAnchor.constraint(equalTo: closeBtn.topAnchor, constant: -10),
            btn.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            btn.widthAnchor.constraint(equalToConstant: 200),
            btn.heightAnchor.constraint(equalToConstant: 54),
            
            closeBtn.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
            closeBtn.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        ])
    }
    
    @objc private func actionTapped() {
        dismiss(animated: true) { self.onAction?() }
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}
