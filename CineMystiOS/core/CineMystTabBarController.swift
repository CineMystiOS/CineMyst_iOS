//
//  CineMystTabBarController.swift
//  CineMystApp
//
//  Created by user@50 on 11/11/25.
//

import UIKit

class CineMystTabBarController: UITabBarController, UITabBarControllerDelegate {
    private weak var profileTabNavigationController: UINavigationController?
    private let defaultProfileTabImage = UIImage(systemName: "person.crop.circle.fill")

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        delegate = self
        refreshProfileTabAvatar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshProfileTabAvatar()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tabBar.layer.cornerRadius = 28
        tabBar.layer.masksToBounds = false
        tabBar.layer.shadowColor = UIColor.black.withAlphaComponent(0.12).cgColor
        tabBar.layer.shadowOpacity = 1
        tabBar.layer.shadowRadius = 24
        tabBar.layer.shadowOffset = CGSize(width: 0, height: 10)
        tabBar.frame = CGRect(
            x: 12,
            y: view.bounds.height - tabBar.frame.height - 10,
            width: view.bounds.width - 24,
            height: tabBar.frame.height
        )
        tabBar.itemPositioning = .centered
        tabBar.itemSpacing = 0
        tabBar.itemWidth = floor(tabBar.bounds.width / 5.0)
    }

    // MARK: - Tab Bar Setup
    private func setupTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterialLight)
        appearance.backgroundColor = UIColor(red: 0.982, green: 0.968, blue: 0.975, alpha: 0.78)
        appearance.shadowColor = .clear

        // Color: #431631 (deepPlum)
        let activeColor = UIColor(red: 0x43/255, green: 0x16/255, blue: 0x31/255, alpha: 1)
        let inactiveColor = UIColor(red: 0x43/255, green: 0x16/255, blue: 0x31/255, alpha: 0.4)
        let tabTitleFont = UIFont.systemFont(ofSize: 10, weight: .medium)
        
        appearance.stackedLayoutAppearance.selected.iconColor = activeColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: activeColor,
            .font: tabTitleFont
        ]
        appearance.stackedLayoutAppearance.normal.iconColor = inactiveColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: inactiveColor,
            .font: tabTitleFont
        ]
        appearance.stackedLayoutAppearance.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -1)
        appearance.stackedLayoutAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -1)

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = activeColor
        tabBar.unselectedItemTintColor = inactiveColor
        tabBar.itemPositioning = .fill

        // MARK: - Tabs

        // Home
        let homeVC = UINavigationController(rootViewController: HomeDashboardViewController())
        homeVC.tabBarItem = UITabBarItem(title: "Home",
                                         image: UIImage(systemName: "house.fill"),
                                         tag: 0)

        // Castings
        let jobsVC = UINavigationController(rootViewController: JobsViewController())
        jobsVC.tabBarItem = UITabBarItem(title: "Castings",
                                         image: UIImage(systemName: "briefcase.fill"),
                                         tag: 1)

        // Flicks → ReelsViewController
        let reelsVC = ReelsViewController()
        let flicksNav = UINavigationController(rootViewController: reelsVC)
        flicksNav.tabBarItem = UITabBarItem(title: "Flicks",
                                            image: UIImage(systemName: "popcorn.fill"),
                                            tag: 2)

        // Mentorship
        let mentorHome = MentorshipHomeViewController()
        let mentorVC = UINavigationController(rootViewController: mentorHome)
        mentorVC.tabBarItem = UITabBarItem(title: "1:1",
                                           image: UIImage(systemName: "person.2.fill"),
                                           tag: 3)

        // Profile
        let profileVC = UINavigationController(rootViewController: ActorProfileViewController())
        profileVC.tabBarItem = UITabBarItem(title: "",
                                            image: defaultProfileTabImage,
                                            tag: 4)
        profileVC.tabBarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
        profileVC.tabBarItem.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 40)
        profileTabNavigationController = profileVC

        // Final Tab Order
        viewControllers = [homeVC, jobsVC, flicksNav, mentorVC, profileVC]
    }

    private func refreshProfileTabAvatar() {
        guard let profileTabNavigationController else { return }

        profileTabNavigationController.tabBarItem.image = defaultProfileTabImage
        profileTabNavigationController.tabBarItem.selectedImage = defaultProfileTabImage

        Task { [weak self] in
            guard let self else { return }

            do {
                let profileData = try await ProfileService.shared.fetchCurrentUserProfile()
                guard
                    let urlString = profileData.profile.profilePictureUrl,
                    let url = URL(string: urlString)
                else { return }

                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else { return }

                let tabImage = self.makeCircularTabImage(from: image)
                await MainActor.run {
                    profileTabNavigationController.tabBarItem.image = tabImage.withRenderingMode(.alwaysOriginal)
                    profileTabNavigationController.tabBarItem.selectedImage = tabImage.withRenderingMode(.alwaysOriginal)
                    self.tabBar.setNeedsLayout()
                    self.tabBar.layoutIfNeeded()
                }
            } catch {
                print("⚠️ Failed to refresh profile tab avatar: \(error)")
            }
        }
    }

    private func makeCircularTabImage(from image: UIImage) -> UIImage {
        let size = CGSize(width: 38, height: 38)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            UIBezierPath(ovalIn: rect).addClip()
            image.draw(in: rect)

            UIColor.white.withAlphaComponent(0.9).setStroke()
            let strokeRect = rect.insetBy(dx: 0.75, dy: 0.75)
            let strokePath = UIBezierPath(ovalIn: strokeRect)
            strokePath.lineWidth = 1.5
            strokePath.stroke()
        }
    }
}
