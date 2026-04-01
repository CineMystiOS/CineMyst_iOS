//
//  LaunchWelcomeViewController.swift
//  CineMystApp
//
//  Welcome Onboarding screen for unauthenticated users.
//

import UIKit

class LaunchWelcomeViewController: UIViewController {

    private let backgroundImageView = UIImageView()
    private let darkOverlayView     = UIView()
    
    // For continuous rolling reel animation
    private let reelContainer       = UIView()
    private let reelImageView1      = UIImageView()
    private let reelImageView2      = UIImageView()
    
    private let logoStackView       = UIStackView()
    private let iconImageView       = UIImageView()
    private let titleLabel          = UILabel()
    
    private let subtitleLabel       = UILabel()
    private let getStartedButton    = UIButton(type: .system)
    private var glassBlurView: UIVisualEffectView?
    private var btnGradientLayer: CAGradientLayer?
    
    // Constraint reference for animation
    private var iconCenterXConstraint: NSLayoutConstraint!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAnimations()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Background
        if let obImage = UIImage(named: "onboarding") {
            backgroundImageView.image = obImage
        } else {
            // Fallback in case image asset name is slightly different
            backgroundImageView.backgroundColor = UIColor(red: 0.1, green: 0.05, blue: 0.1, alpha: 1.0)
        }
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView)
        
        // Dark/Color Tint Overlay
        // The screenshot shows a very dark maroon/plum tint overlay
        darkOverlayView.backgroundColor = UIColor(red: 0.15, green: 0.05, blue: 0.1, alpha: 0.65)
        darkOverlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(darkOverlayView)
        
        // Reel Container
        reelContainer.clipsToBounds = true
        reelContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(reelContainer)
        
        // Reel Images
        // Trying "reel" asset
        let reelImage = UIImage(named: "reel")
        reelImageView1.image = reelImage
        reelImageView1.contentMode = .scaleAspectFill
        reelImageView1.clipsToBounds = true
        reelImageView2.image = reelImage
        reelImageView2.contentMode = .scaleAspectFill
        reelImageView2.clipsToBounds = true
        
        reelContainer.addSubview(reelImageView1)
        reelContainer.addSubview(reelImageView2)
        
        // Logo & Title
        // Trying "icon " or "icon"
        let iconImg = UIImage(named: "icon ") ?? UIImage(named: "icon")
        iconImageView.image = iconImg
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(iconImageView)
        
        titleLabel.text = "" 
        titleLabel.textColor = .white
        titleLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 52) ?? UIFont.systemFont(ofSize: 52, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel.text = "Where Talent meets Opportunity"
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        subtitleLabel.font = UIFont(name: "AvenirNext-Medium", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.alpha = 0
        view.addSubview(subtitleLabel)
        
        // 1. Setup the Blur (Glass)
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.isUserInteractionEnabled = false
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 30
        blurView.clipsToBounds = true
        
        // 2. Button Attributes
        var btnConfig = UIButton.Configuration.filled()
        btnConfig.title = "Get Started"
        btnConfig.baseBackgroundColor = UIColor(red: 0.53, green: 0.22, blue: 0.38, alpha: 0.35) // Low alpha for glass tint
        btnConfig.baseForegroundColor = .white
        btnConfig.cornerStyle = .capsule
        btnConfig.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
        btnConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont(name: "AvenirNext-Bold", size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .bold)
            return outgoing
        }
        
        getStartedButton.configuration = btnConfig
        getStartedButton.translatesAutoresizingMaskIntoConstraints = false
        getStartedButton.alpha = 0
        getStartedButton.transform = CGAffineTransform(translationX: 0, y: 40)
        
        blurView.alpha = 0
        blurView.transform = CGAffineTransform(translationX: 0, y: 40)
        
        getStartedButton.addTarget(self, action: #selector(getStartedTapped), for: .touchUpInside)
        
        // 3. Add Blur behind the button
        view.addSubview(blurView)
        view.addSubview(getStartedButton)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: getStartedButton.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: getStartedButton.bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: getStartedButton.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: getStartedButton.trailingAnchor)
        ])
        
        // Layering / Shadow
        getStartedButton.layer.shadowColor = UIColor(red: 0.53, green: 0.22, blue: 0.38, alpha: 0.8).cgColor
        getStartedButton.layer.shadowOffset = CGSize(width: 0, height: 12)
        getStartedButton.layer.shadowRadius = 24
        getStartedButton.layer.shadowOpacity = 0.4
        getStartedButton.layer.masksToBounds = false
        
        // Store reference to animate both
        self.glassBlurView = blurView
        
        // Setup initial animation states
        iconImageView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        iconImageView.alpha = 0
        
        // We will store this constraint to animate it later
        iconCenterXConstraint = iconImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 10)
        
        self.setupGetStartedGradient()
        
        navigationItem.backButtonTitle = ""
    }
    
    private func setupGetStartedGradient() {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.31, green: 0.07, blue: 0.18, alpha: 0.85).cgColor, // Deep Plum (Left)
            UIColor(red: 0.46, green: 0.11, blue: 0.28, alpha: 0.85).cgColor  // Lighter Plum (Right)
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        
        // We will apply this to the button's layer
        getStartedButton.layer.insertSublayer(gradient, at: 0)
        self.btnGradientLayer = gradient
    }
    
    private func setupLayout() {
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            darkOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            darkOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            darkOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            darkOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            reelContainer.topAnchor.constraint(equalTo: view.topAnchor),
            reelContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            reelContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -40),
            reelContainer.widthAnchor.constraint(equalToConstant: 240), 
            
            // Icon constrained via stored constraint
            iconCenterXConstraint,
            iconImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -10),
            iconImageView.widthAnchor.constraint(equalToConstant: 110),
            iconImageView.heightAnchor.constraint(equalToConstant: 110),
            
            // Title immediately bounds to icon with clean spacing
            titleLabel.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            
            subtitleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 12),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),
            
            getStartedButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            getStartedButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            getStartedButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            getStartedButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Setup reel image frames for animation
        let reelWidth = reelContainer.bounds.width
        var reelHeight: CGFloat = view.bounds.height * 2.5 
        if let img = reelImageView1.image {
            let aspect = img.size.height / img.size.width
            reelHeight = reelWidth * aspect
        }
        
        if reelHeight < view.bounds.height {
            reelHeight = view.bounds.height + 100
        }
        
        reelImageView1.frame = CGRect(x: 0, y: 0, width: reelWidth, height: reelHeight)
        reelImageView2.frame = CGRect(x: 0, y: reelHeight, width: reelWidth, height: reelHeight)
        
        // Update button gradient frame
        if let grad = btnGradientLayer {
            grad.frame = getStartedButton.bounds
            grad.cornerRadius = getStartedButton.bounds.height / 2
        }
    }
    
    private func startAnimations() {
        // No slow zoom on background - static image for cleaner look
        
        // Phase 1: Unroll the film (From Bottom Up)
        let maskLayer = CALayer()
        maskLayer.backgroundColor = UIColor.white.cgColor
        // Start mask at the bottom
        maskLayer.frame = CGRect(x: 0, y: view.bounds.height, width: reelContainer.bounds.width, height: 0)
        reelContainer.layer.mask = maskLayer
        
        let unrollHeight = view.bounds.height * 2.5
        
        let unrollAnimation = CABasicAnimation(keyPath: "bounds.size.height")
        unrollAnimation.fromValue = 0
        unrollAnimation.toValue = unrollHeight
        
        let positionAnimation = CABasicAnimation(keyPath: "position.y")
        positionAnimation.fromValue = view.bounds.height
        positionAnimation.toValue = view.bounds.height - (unrollHeight / 2)
        
        let unrollGroup = CAAnimationGroup()
        unrollGroup.animations = [unrollAnimation, positionAnimation]
        unrollGroup.duration = 1.9
        unrollGroup.timingFunction = CAMediaTimingFunction(name: .easeOut)
        unrollGroup.fillMode = .forwards
        unrollGroup.isRemovedOnCompletion = false
        
        maskLayer.add(unrollGroup, forKey: "unroll")
        
        // Start continuous rolling after unroll
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            self.animateReelLoop()
        }
        
        // Phase 2: Pop the Logo Icon
        UIView.animate(withDuration: 0.6, delay: 1.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: .curveEaseOut, animations: {
            self.iconImageView.alpha = 1
            self.iconImageView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                self.iconImageView.transform = .identity
            }
        }
        
        // Phase 3: Slide Logo Left & Typewriter Text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            // Calculated offset to perfectly center the logo + spaced "ineMyst" text
            self.iconCenterXConstraint.constant = -121 
            
            UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseInOut, animations: {
                self.view.layoutIfNeeded()
            }, completion: { _ in
                // Typewriter effect
                let fullText = "ineMyst"
                for (index, char) in fullText.enumerated() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.08) {
                        self.titleLabel.text?.append(char)
                    }
                }
            })
        }
        
        // Phase 4: Fade in Subtitle and Button
        UIView.animate(withDuration: 0.8, delay: 2.8, options: .curveEaseOut, animations: {
            self.subtitleLabel.alpha = 1
        }, completion: nil)
        
        UIView.animate(withDuration: 0.8, delay: 3.1, options: .curveEaseOut, animations: {
            self.getStartedButton.alpha = 1
            self.getStartedButton.transform = .identity
            self.glassBlurView?.alpha = 1
            self.glassBlurView?.transform = .identity
        }, completion: nil)
    }
    
    private func animateReelLoop() {
        let reelHeight = reelImageView1.frame.height
        
        // Reset positions for seamless looping
        reelImageView1.frame.origin.y = 0
        reelImageView2.frame.origin.y = reelHeight
        
        UIView.animate(withDuration: 25.0, delay: 0, options: [.curveLinear, .repeat], animations: {
            self.reelImageView1.frame.origin.y = -reelHeight
            self.reelImageView2.frame.origin.y = 0
        }, completion: nil)
    }

    
    @objc private func getStartedTapped() {
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()
        
        UIView.animate(withDuration: 0.1, animations: {
            self.getStartedButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.getStartedButton.transform = .identity
            }
            
            let loginVC = LoginViewController()
            let nav = UINavigationController(rootViewController: loginVC)
            
            // Use custom detent for iOS 16+, fallback to standard for iOS 15
            nav.modalPresentationStyle = .pageSheet
            if let sheet = nav.sheetPresentationController {
                if #available(iOS 16.0, *) {
                    sheet.detents = [.custom(resolver: { context in
                        return context.maximumDetentValue * 0.75
                    }), .large()]
                } else {
                    sheet.detents = [.medium(), .large()]
                }
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 32
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            }
            
            self.present(nav, animated: true)
        }
    }
}
