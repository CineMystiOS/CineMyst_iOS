//
//  PortfolioCreationViewController.swift
//  CineMystApp
//
//  Full actor portfolio: personal info, vital stats, preferences & experience.

import UIKit
import PhotosUI
import AVFoundation
import Supabase

// MARK: - Media Item (local pick before upload)

struct PickedMediaItem {
    let id = UUID().uuidString
    let image: UIImage?          // UIImage for photos; video thumbnail
    let videoURL: URL?           // nil for photos
    var type: String { videoURL != nil ? "video" : "image" }
}

// MARK: - Actor Portfolio Form Data

struct ActorPortfolioFormData {
    // Step 1 – Personal Info
    var fullName: String?
    var age: String?
    var height: String?
    var weight: String?
    var sex: String?
    var currentAddress: String?
    var contactNo: String?
    var email: String?
    var education: String?
    var maritalStatus: String?
    var currentProfession: String?
    var passport: String?         // "Yes" / "No"
    var hobbies: String?
    var languages: String?

    // Step 2 – Vital Statistics
    var bust: String?
    var waist: String?
    var hips: String?
    var skinTone: String?
    var eyeColor: String?
    var hairColor: String?
    var bodyType: String?
    var anyTattoo: String?
    var armpitHair: String?
    var bodyHair: String?
    var upperLipsHair: String?
    var shoeSize: String?

    // Step 3 – Shoot Preferences (Bool as yes/no strings)
    var interestedOutstation: String?
    var interestedOutOfCountry: String?
    var comfortableAllTimings: String?
    var dressesComfortableWith: String?

    // Step 4 – Work Interests (yes/no)
    var printShoot: String?
    var sareesShoot: String?
    var lahungaShoot: String?
    var rampShows: String?
    var designerShoots: String?
    var indianWears: String?
    var traditionalWear: String?
    var casualWear: String?
    var ethnicWears: String?
    var westernWears: String?
    var sportswear: String?
    var nightWears: String?
    var jewellery: String?
    var bikiniShoots: String?
    var lingerieShoots: String?
    var swimSuits: String?
    var calendarShoots: String?
    var musicAlbums: String?
    var acting: String?
    var movies: String?
    var tvc: String?
    var tvSerials: String?
    var kissingScene: String?
    var intimateScenes: String?
    var backlessScene: String?
    var smokingScenes: String?
    var singing: String?
    var dancing: String?
    var anchoring: String?
    var webSeries: String?
    var adjustment: String?
    var shorts: String?
    var topless: String?
    var compromise: String?
    var nude: String?
    var semiNude: String?
    var dustAllergy: String?

    // Step 5 – Experience & Social
    var previousExperience: String?
    var instagramUrl: String?
    var youtubeUrl: String?
    var imdbUrl: String?
}

// MARK: - Main VC

class PortfolioCreationViewController: UIViewController {

    // MARK: Properties
    private var currentStep = 0
    private let totalSteps  = 7     // 0-6
    private var formData    = ActorPortfolioFormData()
    private var pickedMedia: [PickedMediaItem] = []

    // MARK: UI
    private let progressView    = UIProgressView(progressViewStyle: .bar)
    private let progressLabel   = UILabel()
    private let scrollView      = UIScrollView()
    private let contentView     = UIView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let nextButton      = UIButton(type: .system)
    private let backButton      = UIButton(type: .system)
    private var currentStepView: UIView?

    private var stepContentBottomConstraint: NSLayoutConstraint?

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ActorProfileDS.bgLight
        title = "Create Portfolio"
        setupNav()
        setupProgress()
        setupScrollView()
        setupButtons()
        setupLoader()
        fetchUserEmail()
        showStep(0)
    }

    // MARK: Setup

    private func setupNav() {
        let cancel = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped))
        cancel.tintColor = ActorProfileDS.deepPlum
        navigationItem.leftBarButtonItem = cancel
    }

    private func setupProgress() {
        progressView.progressTintColor = ActorProfileDS.rosePink
        progressView.trackTintColor    = ActorProfileDS.palePink
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)

        progressLabel.font      = .systemFont(ofSize: 13, weight: .medium)
        progressLabel.textColor = ActorProfileDS.midPlum
        progressLabel.textAlignment = .center
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressLabel)

        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            progressView.heightAnchor.constraint(equalToConstant: 6),

            progressLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 6),
            progressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        updateProgress()
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints  = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])
    }

    private func setupButtons() {
        backButton.setTitle("← Back", for: .normal)
        backButton.titleLabel?.font    = .systemFont(ofSize: 15, weight: .medium)
        backButton.setTitleColor(ActorProfileDS.deepPlum, for: .normal)
        backButton.backgroundColor     = .white
        backButton.layer.cornerRadius  = 14
        backButton.layer.borderWidth   = 1.5
        backButton.layer.borderColor   = ActorProfileDS.deepPlum.cgColor
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)

        nextButton.setTitle("Next →", for: .normal)
        nextButton.titleLabel?.font   = .systemFont(ofSize: 15, weight: .semibold)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.backgroundColor    = ActorProfileDS.deepPlum
        nextButton.layer.cornerRadius = 14
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        view.addSubview(nextButton)

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            backButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.28),
            backButton.heightAnchor.constraint(equalToConstant: 48),

            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            nextButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.62),
            nextButton.heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    private func setupLoader() {
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = ActorProfileDS.deepPlum
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func fetchUserEmail() {
        Task {
            guard let session = try? await AuthManager.shared.currentSession() else { return }
            let email = session.user.email ?? ""
            await MainActor.run {
                self.formData.email = email
                (self.view.viewWithTag(101) as? UITextField)?.text = email
            }
        }
    }

    // MARK: Step Management

    private func showStep(_ step: Int) {
        currentStep = step
        updateProgress()
        currentStepView?.removeFromSuperview()

        let stepView: UIView
        switch step {
        case 0: stepView = makePersonalInfoStep()
        case 1: stepView = makeVitalStatsStep()
        case 2: stepView = makeShootPreferencesStep()
        case 3: stepView = makeWorkInterestsStep()
        case 4: stepView = makeExperienceStep()
        case 5: stepView = makeMediaUploadStep()
        case 6: stepView = makeReviewStep()
        default: return
        }

        stepView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stepView)
        NSLayoutConstraint.activate([
            stepView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stepView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stepView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stepView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
        ])
        currentStepView = stepView

        backButton.isHidden = (step == 0)
        nextButton.setTitle(step == totalSteps - 1 ? "🎬 Create Portfolio" : "Next →", for: .normal)
        scrollView.setContentOffset(.zero, animated: false)
    }

    private func updateProgress() {
        let progress = Float(currentStep + 1) / Float(totalSteps)
        progressView.setProgress(progress, animated: true)
        let titles = ["Personal Info", "Vital Stats", "Shoot Prefs", "Work Interests", "Experience", "Media", "Review"]
        progressLabel.text = "Step \(currentStep + 1) of \(totalSteps)  •  \(titles[min(currentStep, titles.count - 1)])"
    }

    // MARK: – Step 0: Personal Information

    private func makePersonalInfoStep() -> UIView {
        let v = makeContainer()
        addSectionHeader(to: v, icon: "👤", title: "Personal Information", subtitle: "Basic details about you")

        let fields: [(String, Int, UIKeyboardType)] = [
            ("Full Name *", 1000, .default),
            ("Age", 1001, .numberPad),
            ("Height (e.g. 5'5\")", 1002, .default),
            ("Weight (e.g. 58kg)", 1003, .default),
            ("Education", 1004, .default),
            ("Marital Status", 1005, .default),
            ("Current Profession", 1006, .default),
            ("Contact Number", 1007, .phonePad),
            ("Email Address", 101, .emailAddress),
            ("Current Address", 1009, .default),
            ("Languages Known", 1010, .default),
            ("Hobbies", 1011, .default),
        ]

        let sexPicker = makePickerRow(label: "Sex", options: ["Select", "Male", "Female", "Other"],
                                     current: formData.sex, tag: 1100)
        let passportPicker = makePickerRow(label: "Passport", options: ["Select", "Yes", "No"],
                                           current: formData.passport, tag: 1101)

        var lastView: UIView = v.subviews.last!
        for (placeholder, tag, keyboard) in fields {
            let tf = makeTextField(placeholder: placeholder, tag: tag, keyboardType: keyboard)
            // Restore persisted value
            switch tag {
            case 1000: tf.text = formData.fullName
            case 1001: tf.text = formData.age
            case 1002: tf.text = formData.height
            case 1003: tf.text = formData.weight
            case 1004: tf.text = formData.education
            case 1005: tf.text = formData.maritalStatus
            case 1006: tf.text = formData.currentProfession
            case 1007: tf.text = formData.contactNo
            case 101:  tf.text = formData.email; tf.isEnabled = false; tf.alpha = 0.6
            case 1009: tf.text = formData.currentAddress
            case 1010: tf.text = formData.languages
            case 1011: tf.text = formData.hobbies
            default: break
            }
            v.addSubview(tf)
            NSLayoutConstraint.activate([
                tf.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 12),
                tf.leadingAnchor.constraint(equalTo: v.leadingAnchor),
                tf.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            ])
            lastView = tf
        }
        for row in [sexPicker, passportPicker] {
            v.addSubview(row)
            NSLayoutConstraint.activate([
                row.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 12),
                row.leadingAnchor.constraint(equalTo: v.leadingAnchor),
                row.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            ])
            lastView = row
        }
        lastView.bottomAnchor.constraint(equalTo: v.bottomAnchor).isActive = true
        return v
    }

    // MARK: – Step 1: Vital Statistics

    private func makeVitalStatsStep() -> UIView {
        let v = makeContainer()
        addSectionHeader(to: v, icon: "📐", title: "Vital Statistics", subtitle: "Physical measurements")

        let fields: [(String, Int)] = [
            ("Bust/Breast (inches)", 2000),
            ("Waist (inches)", 2001),
            ("Hips (inches)", 2002),
            ("Skin Tone / Complexion", 2003),
            ("Eye Color", 2004),
            ("Hair Color", 2005),
            ("Body Type (e.g. Slim, Average)", 2006),
            ("Shoe Size", 2007),
        ]
        let yesNoPickers: [(String, Int, String?)] = [
            ("Any Tattoo", 2100, formData.anyTattoo),
            ("Armpit Hair", 2101, formData.armpitHair),
            ("Body Hair", 2102, formData.bodyHair),
            ("Upper Lips Hair", 2103, formData.upperLipsHair),
        ]

        var lastView: UIView = v.subviews.last!
        for (placeholder, tag) in fields {
            let tf = makeTextField(placeholder: placeholder, tag: tag)
            switch tag {
            case 2000: tf.text = formData.bust
            case 2001: tf.text = formData.waist
            case 2002: tf.text = formData.hips
            case 2003: tf.text = formData.skinTone
            case 2004: tf.text = formData.eyeColor
            case 2005: tf.text = formData.hairColor
            case 2006: tf.text = formData.bodyType
            case 2007: tf.text = formData.shoeSize
            default: break
            }
            v.addSubview(tf)
            NSLayoutConstraint.activate([
                tf.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 12),
                tf.leadingAnchor.constraint(equalTo: v.leadingAnchor),
                tf.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            ])
            lastView = tf
        }
        for (label, tag, current) in yesNoPickers {
            let row = makePickerRow(label: label, options: ["Select", "Yes", "No"], current: current, tag: tag)
            v.addSubview(row)
            NSLayoutConstraint.activate([
                row.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 12),
                row.leadingAnchor.constraint(equalTo: v.leadingAnchor),
                row.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            ])
            lastView = row
        }
        lastView.bottomAnchor.constraint(equalTo: v.bottomAnchor).isActive = true
        return v
    }

    // MARK: – Step 2: Shoot Preferences

    private func makeShootPreferencesStep() -> UIView {
        let v = makeContainer()
        addSectionHeader(to: v, icon: "🎬", title: "Shoot Preferences", subtitle: "Availability & comfort zone")

        let pickers: [(String, Int, String?)] = [
            ("Interested for Outstation Shoot", 3000, formData.interestedOutstation),
            ("Interested for Out of Country Shoot", 3001, formData.interestedOutOfCountry),
            ("Comfortable with All Timings", 3002, formData.comfortableAllTimings),
        ]
        var lastView: UIView = v.subviews.last!
        for (label, tag, current) in pickers {
            let row = makePickerRow(label: label, options: ["Select", "Yes", "No"], current: current, tag: tag)
            v.addSubview(row)
            NSLayoutConstraint.activate([
                row.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 14),
                row.leadingAnchor.constraint(equalTo: v.leadingAnchor),
                row.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            ])
            lastView = row
        }
        // Dresses comfortable with — free text
        let dressTF = makeTextField(placeholder: "Dresses comfortable with (e.g. Saree, Western...)", tag: 3003)
        dressTF.text = formData.dressesComfortableWith
        v.addSubview(dressTF)
        NSLayoutConstraint.activate([
            dressTF.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 14),
            dressTF.leadingAnchor.constraint(equalTo: v.leadingAnchor),
            dressTF.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            dressTF.bottomAnchor.constraint(equalTo: v.bottomAnchor),
        ])
        return v
    }

    // MARK: – Step 3: Work Interests

    private func makeWorkInterestsStep() -> UIView {
        let v = makeContainer()
        addSectionHeader(to: v, icon: "🌟", title: "Work Interests", subtitle: "Select Yes / No for each category")

        let items: [(String, Int, String?)] = [
            ("Print Shoot / Catalog", 4000, formData.printShoot),
            ("Sarees Shoot", 4001, formData.sareesShoot),
            ("Lahanga Shoot", 4002, formData.lahungaShoot),
            ("Ramp Shows", 4003, formData.rampShows),
            ("Designer Shoots", 4004, formData.designerShoots),
            ("Indian Wears", 4005, formData.indianWears),
            ("Traditional Wear", 4006, formData.traditionalWear),
            ("Casual Wear", 4007, formData.casualWear),
            ("Ethnic Wears", 4008, formData.ethnicWears),
            ("Western Wears", 4009, formData.westernWears),
            ("Sports Wears", 4010, formData.sportswear),
            ("Night Wears", 4011, formData.nightWears),
            ("Jewellery", 4012, formData.jewellery),
            ("Bikini Shoots", 4013, formData.bikiniShoots),
            ("Lingerie Shoots", 4014, formData.lingerieShoots),
            ("Swim Suits", 4015, formData.swimSuits),
            ("Calendar Shoots", 4016, formData.calendarShoots),
            ("Music Albums", 4017, formData.musicAlbums),
            ("Acting", 4018, formData.acting),
            ("Movies", 4019, formData.movies),
            ("TVC", 4020, formData.tvc),
            ("TV Serials", 4021, formData.tvSerials),
            ("Kissing Scene", 4022, formData.kissingScene),
            ("Intimate / Bold Scenes", 4023, formData.intimateScenes),
            ("Backless Scene", 4024, formData.backlessScene),
            ("Smoking Scenes", 4025, formData.smokingScenes),
            ("Singing", 4026, formData.singing),
            ("Dancing", 4027, formData.dancing),
            ("Anchoring", 4028, formData.anchoring),
            ("Web Series", 4029, formData.webSeries),
            ("Adjustment", 4030, formData.adjustment),
            ("Shorts", 4031, formData.shorts),
            ("Topless", 4032, formData.topless),
            ("Compromise", 4033, formData.compromise),
            ("Nude", 4034, formData.nude),
            ("Semi Nude", 4035, formData.semiNude),
            ("Allergy to Dust", 4036, formData.dustAllergy),
        ]

        var lastView: UIView = v.subviews.last!
        for (label, tag, current) in items {
            let row = makeToggleRow(label: label, current: current, tag: tag)
            v.addSubview(row)
            NSLayoutConstraint.activate([
                row.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 4),
                row.leadingAnchor.constraint(equalTo: v.leadingAnchor),
                row.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            ])
            lastView = row
        }
        lastView.bottomAnchor.constraint(equalTo: v.bottomAnchor).isActive = true
        return v
    }

    // MARK: – Step 4: Experience & Social

    private func makeExperienceStep() -> UIView {
        let v = makeContainer()
        addSectionHeader(to: v, icon: "🎭", title: "Experience & Social", subtitle: "Your acting experience and online presence")

        let expTV = makeTextView(placeholder: "Describe your previous experience, roles, productions...", tag: 5000)
        expTV.text = formData.previousExperience
        v.addSubview(expTV)

        let ig = makeTextField(placeholder: "Instagram URL / @handle", tag: 5001)
        ig.text = formData.instagramUrl
        let yt = makeTextField(placeholder: "YouTube URL / @handle", tag: 5002)
        yt.text = formData.youtubeUrl
        let imdb = makeTextField(placeholder: "IMDb Profile URL", tag: 5003)
        imdb.text = formData.imdbUrl

        let header = v.subviews.last!
        v.addSubview(expTV)
        NSLayoutConstraint.activate([
            expTV.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 14),
            expTV.leadingAnchor.constraint(equalTo: v.leadingAnchor),
            expTV.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            expTV.heightAnchor.constraint(equalToConstant: 180),
        ])
        var last: UIView = expTV
        for tf in [ig, yt, imdb] {
            v.addSubview(tf)
            NSLayoutConstraint.activate([
                tf.topAnchor.constraint(equalTo: last.bottomAnchor, constant: 12),
                tf.leadingAnchor.constraint(equalTo: v.leadingAnchor),
                tf.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            ])
            last = tf
        }
        last.bottomAnchor.constraint(equalTo: v.bottomAnchor).isActive = true
        return v
    }

    // MARK: – Step 5: Media Upload

    private func makeMediaUploadStep() -> UIView {
        let v = makeContainer()
        addSectionHeader(to: v, icon: "📸", title: "Photos & Videos", subtitle: "Add your portfolio media — shots, reels, BTS...")

        let addBtn = UIButton(type: .system)
        addBtn.setTitle("＋  Add Photos / Videos", for: .normal)
        addBtn.setTitleColor(.white, for: .normal)
        addBtn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        addBtn.backgroundColor  = ActorProfileDS.deepPlum
        addBtn.layer.cornerRadius = 14
        addBtn.translatesAutoresizingMaskIntoConstraints = false
        addBtn.addTarget(self, action: #selector(pickMediaTapped), for: .touchUpInside)
        v.addSubview(addBtn)

        // Media preview scroll
        let previewScroll = UIScrollView()
        previewScroll.showsHorizontalScrollIndicator = false
        previewScroll.translatesAutoresizingMaskIntoConstraints = false
        previewScroll.tag = 6000

        let previewStack = UIStackView()
        previewStack.axis    = .horizontal
        previewStack.spacing = 10
        previewStack.tag     = 6001
        previewStack.translatesAutoresizingMaskIntoConstraints = false
        previewScroll.addSubview(previewStack)

        v.addSubview(previewScroll)

        let hdrView = v.subviews.first(where: { $0.tag == 9001 })!
        NSLayoutConstraint.activate([
            addBtn.topAnchor.constraint(equalTo: hdrView.bottomAnchor, constant: 16),
            addBtn.leadingAnchor.constraint(equalTo: v.leadingAnchor),
            addBtn.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            addBtn.heightAnchor.constraint(equalToConstant: 50),

            previewScroll.topAnchor.constraint(equalTo: addBtn.bottomAnchor, constant: 16),
            previewScroll.leadingAnchor.constraint(equalTo: v.leadingAnchor),
            previewScroll.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            previewScroll.heightAnchor.constraint(equalToConstant: 140),
            previewScroll.bottomAnchor.constraint(equalTo: v.bottomAnchor),

            previewStack.topAnchor.constraint(equalTo: previewScroll.topAnchor),
            previewStack.bottomAnchor.constraint(equalTo: previewScroll.bottomAnchor),
            previewStack.leadingAnchor.constraint(equalTo: previewScroll.leadingAnchor),
            previewStack.trailingAnchor.constraint(equalTo: previewScroll.trailingAnchor),
            previewStack.heightAnchor.constraint(equalTo: previewScroll.heightAnchor),
        ])

        refreshMediaPreview(inStack: previewStack)
        return v
    }

    private func refreshMediaPreview(inStack stack: UIStackView) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for item in pickedMedia {
            let iv = UIImageView(image: item.image ?? UIImage(systemName: "video.fill"))
            iv.contentMode    = .scaleAspectFill
            iv.clipsToBounds  = true
            iv.layer.cornerRadius = 10
            iv.backgroundColor    = ActorProfileDS.palePink
            iv.translatesAutoresizingMaskIntoConstraints = false

            if item.videoURL != nil {
                let overlay = UIImageView(image: UIImage(systemName: "play.circle.fill"))
                overlay.tintColor    = .white
                overlay.contentMode  = .center
                overlay.translatesAutoresizingMaskIntoConstraints = false
                iv.addSubview(overlay)
                NSLayoutConstraint.activate([
                    overlay.centerXAnchor.constraint(equalTo: iv.centerXAnchor),
                    overlay.centerYAnchor.constraint(equalTo: iv.centerYAnchor),
                    overlay.widthAnchor.constraint(equalToConstant: 32),
                    overlay.heightAnchor.constraint(equalToConstant: 32),
                ])
            }

            iv.widthAnchor.constraint(equalToConstant: 120).isActive = true
            stack.addArrangedSubview(iv)
        }
    }

    @objc private func pickMediaTapped() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 10
        config.filter = .any(of: [.images, .videos])
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: – Step 5 old → Step 6: Experience (just renumbered)

    private func makeReviewStep() -> UIView {
        let v = makeContainer()
        addSectionHeader(to: v, icon: "✅", title: "Review Portfolio", subtitle: "Confirm before saving")

        let tv = UITextView()
        tv.text = buildReviewText()
        tv.font = .systemFont(ofSize: 13)
        tv.isEditable = false
        tv.backgroundColor = ActorProfileDS.palePink
        tv.layer.cornerRadius = 12
        tv.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
        tv.translatesAutoresizingMaskIntoConstraints = false

        v.addSubview(tv)
        let header = v.subviews.first(where: { $0.tag == 9001 })!
        NSLayoutConstraint.activate([
            tv.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 16),
            tv.leadingAnchor.constraint(equalTo: v.leadingAnchor),
            tv.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            tv.heightAnchor.constraint(equalToConstant: 500),
            tv.bottomAnchor.constraint(equalTo: v.bottomAnchor),
        ])
        return v
    }

    // MARK: – Builder Helpers

    private func makeContainer() -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    private func addSectionHeader(to view: UIView, icon: String, title: String, subtitle: String) {
        let iconLabel = UILabel()
        iconLabel.text = icon
        iconLabel.font = .systemFont(ofSize: 36)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = ActorProfileDS.deepPlum
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subLabel = UILabel()
        subLabel.text = subtitle
        subLabel.font = .systemFont(ofSize: 14)
        subLabel.textColor = .secondaryLabel
        subLabel.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [iconLabel, titleLabel, subLabel])
        stack.axis      = .vertical
        stack.spacing   = 4
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.tag = 9001
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func makeTextField(placeholder: String, tag: Int, keyboardType: UIKeyboardType = .default) -> UITextField {
        let tf = UITextField()
        tf.placeholder  = placeholder
        tf.borderStyle  = .none
        tf.backgroundColor = .white
        tf.font         = .systemFont(ofSize: 15)
        tf.keyboardType = keyboardType
        tf.autocapitalizationType = keyboardType == .emailAddress || keyboardType == .URL ? .none : .sentences
        tf.tag          = tag
        tf.delegate     = self
        tf.layer.cornerRadius = 12
        tf.layer.borderWidth  = 1
        tf.layer.borderColor  = ActorProfileDS.palePink.cgColor
        tf.leftView  = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 48))
        tf.leftViewMode  = .always
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 48))
        tf.rightViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return tf
    }

    private func makeTextView(placeholder: String, tag: Int) -> UITextView {
        let tv = UITextView()
        tv.text      = placeholder
        tv.textColor = .placeholderText
        tv.font      = .systemFont(ofSize: 15)
        tv.backgroundColor = .white
        tv.layer.cornerRadius = 12
        tv.layer.borderWidth  = 1
        tv.layer.borderColor  = ActorProfileDS.palePink.cgColor
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        tv.tag       = tag
        tv.delegate  = self
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }

    /// A label + segmented Yes/No control row
    private func makeToggleRow(label: String, current: String?, tag: Int) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let lbl = UILabel()
        lbl.text      = label
        lbl.font      = .systemFont(ofSize: 14, weight: .medium)
        lbl.textColor = .label
        lbl.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(lbl)

        let seg = UISegmentedControl(items: ["Yes", "No"])
        seg.tag         = tag
        seg.selectedSegmentIndex = current == "Yes" ? 0 : current == "No" ? 1 : UISegmentedControl.noSegment
        seg.selectedSegmentTintColor = ActorProfileDS.deepPlum
        seg.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        seg.setTitleTextAttributes([.foregroundColor: ActorProfileDS.deepPlum], for: .normal)
        seg.translatesAutoresizingMaskIntoConstraints = false
        seg.widthAnchor.constraint(equalToConstant: 100).isActive = true
        container.addSubview(seg)

        NSLayoutConstraint.activate([
            lbl.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            lbl.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            lbl.trailingAnchor.constraint(equalTo: seg.leadingAnchor, constant: -8),
            seg.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            seg.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
        return container
    }

    /// Label + a segmented picker for a small set of options
    private func makePickerRow(label: String, options: [String], current: String?, tag: Int) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let lbl = UILabel()
        lbl.text      = label
        lbl.font      = .systemFont(ofSize: 13, weight: .medium)
        lbl.textColor = .secondaryLabel
        lbl.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(lbl)

        // Use a UIButton menu for more than 3 options
        let optionsWithoutSelect = options.filter { $0 != "Select" }
        let button = UIButton(type: .system)
        button.tag  = tag
        let title   = current ?? options.first ?? "Select"
        button.setTitle("  \(title)  ▾", for: .normal)
        button.setTitleColor(ActorProfileDS.deepPlum, for: .normal)
        button.titleLabel?.font   = .systemFont(ofSize: 14, weight: .semibold)
        button.backgroundColor    = ActorProfileDS.palePink
        button.layer.cornerRadius = 10
        button.contentHorizontalAlignment = .left
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 38).isActive = true
        button.widthAnchor.constraint(equalToConstant: 160).isActive = true
        button.addTarget(self, action: #selector(pickerButtonTapped(_:)), for: .touchUpInside)
        container.addSubview(button)

        NSLayoutConstraint.activate([
            lbl.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            lbl.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            button.topAnchor.constraint(equalTo: lbl.bottomAnchor, constant: 6),
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        return container
    }

    @objc private func pickerButtonTapped(_ sender: UIButton) {
        let tag = sender.tag
        let options: [String]
        switch tag {
        case 1100: options = ["Male", "Female", "Other"]
        case 1101, 2100, 2101, 2102, 2103, 3000, 3001, 3002: options = ["Yes", "No"]
        default:   options = []
        }
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        for opt in options {
            sheet.addAction(UIAlertAction(title: opt, style: .default) { [weak self, weak sender] _ in
                sender?.setTitle("  \(opt)  ▾", for: .normal)
                self?.pickerValueChanged(tag: tag, value: opt)
            })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = sender; pop.sourceRect = sender.bounds
        }
        present(sheet, animated: true)
    }

    private func pickerValueChanged(tag: Int, value: String) {
        switch tag {
        case 1100: formData.sex = value
        case 1101: formData.passport = value
        case 2100: formData.anyTattoo = value
        case 2101: formData.armpitHair = value
        case 2102: formData.bodyHair = value
        case 2103: formData.upperLipsHair = value
        case 3000: formData.interestedOutstation = value
        case 3001: formData.interestedOutOfCountry = value
        case 3002: formData.comfortableAllTimings = value
        default: break
        }
    }

    // MARK: Save Step Data

    private func saveCurrentStepData() {
        switch currentStep {
        case 0:
            formData.fullName        = (view.viewWithTag(1000) as? UITextField)?.text
            formData.age             = (view.viewWithTag(1001) as? UITextField)?.text
            formData.height          = (view.viewWithTag(1002) as? UITextField)?.text
            formData.weight          = (view.viewWithTag(1003) as? UITextField)?.text
            formData.education       = (view.viewWithTag(1004) as? UITextField)?.text
            formData.maritalStatus   = (view.viewWithTag(1005) as? UITextField)?.text
            formData.currentProfession = (view.viewWithTag(1006) as? UITextField)?.text
            formData.contactNo       = (view.viewWithTag(1007) as? UITextField)?.text
            formData.email           = (view.viewWithTag(101) as? UITextField)?.text
            formData.currentAddress  = (view.viewWithTag(1009) as? UITextField)?.text
            formData.languages       = (view.viewWithTag(1010) as? UITextField)?.text
            formData.hobbies         = (view.viewWithTag(1011) as? UITextField)?.text
        case 1:
            formData.bust       = (view.viewWithTag(2000) as? UITextField)?.text
            formData.waist      = (view.viewWithTag(2001) as? UITextField)?.text
            formData.hips       = (view.viewWithTag(2002) as? UITextField)?.text
            formData.skinTone   = (view.viewWithTag(2003) as? UITextField)?.text
            formData.eyeColor   = (view.viewWithTag(2004) as? UITextField)?.text
            formData.hairColor  = (view.viewWithTag(2005) as? UITextField)?.text
            formData.bodyType   = (view.viewWithTag(2006) as? UITextField)?.text
            formData.shoeSize   = (view.viewWithTag(2007) as? UITextField)?.text
        case 2:
            formData.dressesComfortableWith = (view.viewWithTag(3003) as? UITextField)?.text
        case 3:
            let map: [(Int, WritableKeyPath<ActorPortfolioFormData, String?>)] = [
                (4000, \.printShoot), (4001, \.sareesShoot), (4002, \.lahungaShoot),
                (4003, \.rampShows), (4004, \.designerShoots), (4005, \.indianWears),
                (4006, \.traditionalWear), (4007, \.casualWear), (4008, \.ethnicWears),
                (4009, \.westernWears), (4010, \.sportswear), (4011, \.nightWears),
                (4012, \.jewellery), (4013, \.bikiniShoots), (4014, \.lingerieShoots),
                (4015, \.swimSuits), (4016, \.calendarShoots), (4017, \.musicAlbums),
                (4018, \.acting), (4019, \.movies), (4020, \.tvc), (4021, \.tvSerials),
                (4022, \.kissingScene), (4023, \.intimateScenes), (4024, \.backlessScene),
                (4025, \.smokingScenes), (4026, \.singing), (4027, \.dancing),
                (4028, \.anchoring), (4029, \.webSeries), (4030, \.adjustment),
                (4031, \.shorts), (4032, \.topless), (4033, \.compromise),
                (4034, \.nude), (4035, \.semiNude), (4036, \.dustAllergy),
            ]
            for (tag, kp) in map {
                if let seg = view.viewWithTag(tag) as? UISegmentedControl,
                   seg.selectedSegmentIndex != UISegmentedControl.noSegment {
                    formData[keyPath: kp] = seg.selectedSegmentIndex == 0 ? "Yes" : "No"
                }
            }
        case 4:
            if let tv = view.viewWithTag(5000) as? UITextView, tv.textColor != .placeholderText {
                formData.previousExperience = tv.text
            }
            formData.instagramUrl = (view.viewWithTag(5001) as? UITextField)?.text
            formData.youtubeUrl   = (view.viewWithTag(5002) as? UITextField)?.text
            formData.imdbUrl      = (view.viewWithTag(5003) as? UITextField)?.text
        default: break
        }
    }

    private func validateCurrentStep() -> Bool {
        if currentStep == 0 {
            guard let name = formData.fullName, !name.trimmingCharacters(in: .whitespaces).isEmpty else {
                showError("Full Name is required.")
                return false
            }
        }
        return true
    }

    // MARK: Review Text

    private func buildReviewText() -> String {
        var t = ""
        func yn(_ s: String?) -> String { s ?? "—" }
        t += "👤 PERSONAL INFO\n"
        t += "Name: \(yn(formData.fullName))\nAge: \(yn(formData.age))  |  Sex: \(yn(formData.sex))\n"
        t += "Height: \(yn(formData.height))  |  Weight: \(yn(formData.weight))\n"
        t += "Education: \(yn(formData.education))\nMarital Status: \(yn(formData.maritalStatus))\n"
        t += "Profession: \(yn(formData.currentProfession))\nContact: \(yn(formData.contactNo))\n"
        t += "Email: \(yn(formData.email))\nAddress: \(yn(formData.currentAddress))\n"
        t += "Languages: \(yn(formData.languages))\nHobbies: \(yn(formData.hobbies))\nPassport: \(yn(formData.passport))\n\n"

        t += "📐 VITAL STATS\n"
        t += "Bust/Waist/Hips: \(yn(formData.bust)) / \(yn(formData.waist)) / \(yn(formData.hips))\n"
        t += "Skin: \(yn(formData.skinTone))  Eye: \(yn(formData.eyeColor))  Hair: \(yn(formData.hairColor))\n"
        t += "Body Type: \(yn(formData.bodyType))  Shoe: \(yn(formData.shoeSize))\n"
        t += "Tattoo: \(yn(formData.anyTattoo))  Body Hair: \(yn(formData.bodyHair))\n\n"

        t += "🎬 SHOOT PREFERENCES\n"
        t += "Outstation: \(yn(formData.interestedOutstation))  |  Abroad: \(yn(formData.interestedOutOfCountry))\n"
        t += "All Timings: \(yn(formData.comfortableAllTimings))\nDresses: \(yn(formData.dressesComfortableWith))\n\n"

        t += "🌟 WORK INTERESTS (Yes = ✓ / No = ✗)\n"
        let interests: [(String, String?)] = [
            ("Print/Catalog", formData.printShoot), ("Sarees", formData.sareesShoot),
            ("Lahanga", formData.lahungaShoot), ("Ramp", formData.rampShows),
            ("Designer", formData.designerShoots), ("Indian", formData.indianWears),
            ("Traditional", formData.traditionalWear), ("Casual", formData.casualWear),
            ("Ethnic", formData.ethnicWears), ("Western", formData.westernWears),
            ("Sports", formData.sportswear), ("Night Wear", formData.nightWears),
            ("Jewellery", formData.jewellery), ("Bikini", formData.bikiniShoots),
            ("Lingerie", formData.lingerieShoots), ("SwimSuit", formData.swimSuits),
            ("Calendar", formData.calendarShoots), ("Music", formData.musicAlbums),
            ("Acting", formData.acting), ("Movies", formData.movies),
            ("TVC", formData.tvc), ("TV Serials", formData.tvSerials),
            ("Kissing", formData.kissingScene), ("Intimate", formData.intimateScenes),
            ("Backless", formData.backlessScene), ("Smoking", formData.smokingScenes),
            ("Singing", formData.singing), ("Dancing", formData.dancing),
            ("Anchoring", formData.anchoring), ("Web Series", formData.webSeries),
        ]
        for (name, val) in interests {
            t += "  \(val == "Yes" ? "✓" : val == "No" ? "✗" : "·") \(name)\n"
        }

        t += "\n🎭 EXPERIENCE\n\(yn(formData.previousExperience))\n"
        return t
    }

    // MARK: Actions

    @objc private func cancelTapped() {
        let alert = UIAlertController(title: "Cancel?", message: "Your progress will be lost.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Keep Editing", style: .cancel))
        alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    @objc private func backTapped() {
        saveCurrentStepData()
        showStep(currentStep - 1)
    }

    @objc private func nextTapped() {
        saveCurrentStepData()
        if currentStep == totalSteps - 1 {
            submitPortfolio()
        } else if validateCurrentStep() {
            showStep(currentStep + 1)
        }
    }

    // MARK: Submit to Supabase

    private func submitPortfolio() {
        loadingIndicator.startAnimating()
        nextButton.isEnabled = false
        backButton.isEnabled = false

        Task {
            do {
                guard let session = try await AuthManager.shared.currentSession() else {
                    throw NSError(domain: "Auth", code: 401)
                }
                let uid = session.user.id.uuidString
                print("🚀 Submitting portfolio for UID: \(uid)")

                struct PortfolioInsert: Encodable {
                    // personal
                    let user_id, full_name: String
                    let age, height_cm, weight_kg, sex: String?
                    let current_address, contact_no, email_address, education: String?
                    let marital_status, current_profession, passport, hobbies, languages: String?
                    // vitals
                    let bust, waist, hips, skin_tone, eye_color, hair_color: String?
                    let body_type, any_tattoo, armpit_hair, body_hair, upper_lips_hair, shoe_size: String?
                    // shoot prefs
                    let interested_outstation, interested_out_of_country, comfortable_all_timings: String?
                    let dresses_comfortable_with: String?
                    // interests
                    let print_shoot, sarees_shoot, lahanga_shoot, ramp_shows, designer_shoots: String?
                    let indian_wears, traditional_wear, casual_wear, ethnic_wears, western_wears: String?
                    let sportswear, night_wears, jewellery, bikini_shoots, lingerie_shoots: String?
                    let swim_suits, calendar_shoots, music_albums, acting, movies: String?
                    let tvc, tv_serials, kissing_scene, intimate_scenes, backless_scene: String?
                    let smoking_scenes, singing, dancing, anchoring, web_series: String?
                    let adjustment, shorts, topless, compromise, nude, semi_nude, dust_allergy: String?
                    // experience
                    let previous_experience, instagram_url, youtube_url, imdb_url: String?
                    let is_public: Bool
                    // media
                    let media_urls: [[String: String]]?
                }

                // Upload media items to Supabase Storage
                var uploadedMedia: [[String: String]] = []
                for item in self.pickedMedia {
                    let path = "\(uid)/\(item.id).\(item.type == "video" ? "mp4" : "jpg")"
                    if item.type == "video", let videoURL = item.videoURL {
                        let data = try Data(contentsOf: videoURL)
                        try await supabase.storage
                            .from("portfolio-media")
                            .upload(path, data: data, options: FileOptions(contentType: "video/mp4"))
                    } else if let img = item.image, let data = img.jpegData(compressionQuality: 0.8) {
                        try await supabase.storage
                            .from("portfolio-media")
                            .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))
                    }
                    let publicURL = try supabase.storage.from("portfolio-media").getPublicURL(path: path)
                    uploadedMedia.append(["url": publicURL.absoluteString, "type": item.type])
                }

                let f = self.formData
                let insert = PortfolioInsert(
                    user_id: uid, full_name: f.fullName ?? "",
                    age: f.age, height_cm: f.height, weight_kg: f.weight, sex: f.sex,
                    current_address: f.currentAddress, contact_no: f.contactNo,
                    email_address: f.email, education: f.education,
                    marital_status: f.maritalStatus, current_profession: f.currentProfession,
                    passport: f.passport, hobbies: f.hobbies, languages: f.languages,
                    bust: f.bust, waist: f.waist, hips: f.hips, skin_tone: f.skinTone,
                    eye_color: f.eyeColor, hair_color: f.hairColor, body_type: f.bodyType,
                    any_tattoo: f.anyTattoo, armpit_hair: f.armpitHair, body_hair: f.bodyHair,
                    upper_lips_hair: f.upperLipsHair, shoe_size: f.shoeSize,
                    interested_outstation: f.interestedOutstation,
                    interested_out_of_country: f.interestedOutOfCountry,
                    comfortable_all_timings: f.comfortableAllTimings,
                    dresses_comfortable_with: f.dressesComfortableWith,
                    print_shoot: f.printShoot, sarees_shoot: f.sareesShoot,
                    lahanga_shoot: f.lahungaShoot, ramp_shows: f.rampShows,
                    designer_shoots: f.designerShoots, indian_wears: f.indianWears,
                    traditional_wear: f.traditionalWear, casual_wear: f.casualWear,
                    ethnic_wears: f.ethnicWears, western_wears: f.westernWears,
                    sportswear: f.sportswear, night_wears: f.nightWears,
                    jewellery: f.jewellery, bikini_shoots: f.bikiniShoots,
                    lingerie_shoots: f.lingerieShoots, swim_suits: f.swimSuits,
                    calendar_shoots: f.calendarShoots, music_albums: f.musicAlbums,
                    acting: f.acting, movies: f.movies, tvc: f.tvc, tv_serials: f.tvSerials,
                    kissing_scene: f.kissingScene, intimate_scenes: f.intimateScenes,
                    backless_scene: f.backlessScene, smoking_scenes: f.smokingScenes,
                    singing: f.singing, dancing: f.dancing, anchoring: f.anchoring,
                    web_series: f.webSeries, adjustment: f.adjustment, shorts: f.shorts,
                    topless: f.topless, compromise: f.compromise, nude: f.nude,
                    semi_nude: f.semiNude, dust_allergy: f.dustAllergy,
                    previous_experience: f.previousExperience,
                    instagram_url: f.instagramUrl, youtube_url: f.youtubeUrl,
                    imdb_url: f.imdbUrl, is_public: true,
                    media_urls: uploadedMedia.isEmpty ? nil : uploadedMedia
                )

                try await supabase
                    .from("actor_portfolios")
                    .upsert(insert, onConflict: "user_id")
                    .execute()

                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.nextButton.isEnabled = true
                    self.backButton.isEnabled = true
                    self.showSuccess()
                }
            } catch {
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.nextButton.isEnabled = true
                    self.backButton.isEnabled = true
                    self.showError("Failed to save portfolio: \(error.localizedDescription)")
                }
            }
        }
    }

    private func showSuccess() {
        let a = UIAlertController(title: "🎉 Portfolio Saved!",
                                  message: "Your actor portfolio is live and visible to casting directors.",
                                  preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "Great!", style: .default) { [weak self] _ in
            self?.dismiss(animated: true) {
                NotificationCenter.default.post(name: .portfolioCreated, object: nil)
            }
        })
        present(a, animated: true)
    }

    private func showError(_ message: String) {
        let a = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

// MARK: - Delegates

extension PortfolioCreationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder(); return true
    }
}

extension PortfolioCreationViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = ""; textView.textColor = .label
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.textColor = .placeholderText
            textView.text = "Describe your previous experience, roles, productions..."
        }
    }
}

// MARK: - PHPickerViewControllerDelegate

extension PortfolioCreationViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard !results.isEmpty else { return }

        let group = DispatchGroup()
        for result in results {
            let provider = result.itemProvider
            group.enter()
            if provider.hasItemConformingToTypeIdentifier("public.movie") {
                provider.loadFileRepresentation(forTypeIdentifier: "public.movie") { [weak self] url, _ in
                    defer { group.leave() }
                    guard let url else { return }
                    let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
                    try? FileManager.default.copyItem(at: url, to: tmpURL)
                    let asset = AVAsset(url: tmpURL)
                    let gen = AVAssetImageGenerator(asset: asset)
                    gen.appliesPreferredTrackTransform = true
                    let thumb: UIImage? = (try? gen.copyCGImage(at: .zero, actualTime: nil)).map { UIImage(cgImage: $0) }
                    self?.pickedMedia.append(PickedMediaItem(image: thumb, videoURL: tmpURL))
                }
            } else if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] obj, _ in
                    defer { group.leave() }
                    guard let img = obj as? UIImage else { return }
                    self?.pickedMedia.append(PickedMediaItem(image: img, videoURL: nil))
                }
            } else {
                group.leave()
            }
        }
        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            if let stack = self.view.viewWithTag(6001) as? UIStackView {
                self.refreshMediaPreview(inStack: stack)
            }
        }
    }
}

// MARK: - Notification

extension Notification.Name {
    static let portfolioCreated = Notification.Name("portfolioCreated")
}

// MARK: - Form Data

struct PortfolioFormData {
    var stageName: String?
    var contactEmail: String?
    var alternateEmail: String?
    var profileImage: UIImage?
    var bio: String?
    var instagramUrl: String?
    var youtubeUrl: String?
    var imdbUrl: String?
}
