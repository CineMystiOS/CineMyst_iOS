//
//  CineMystTabBarController.swift
//  CineMystApp
//
//  Created by user@50 on 11/11/25.
//

import UIKit

class CineMystTabBarController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        delegate = self
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
        
        appearance.stackedLayoutAppearance.selected.iconColor = activeColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: activeColor]
        appearance.stackedLayoutAppearance.normal.iconColor = inactiveColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: inactiveColor]

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = activeColor
        tabBar.unselectedItemTintColor = inactiveColor

        // MARK: - Tabs

        // Home
        let homeVC = UINavigationController(rootViewController: HomeDashboardViewController())
        homeVC.tabBarItem = UITabBarItem(title: "Home",
                                         image: UIImage(systemName: "house.fill"),
                                         tag: 0)

        // Flicks → ReelsViewController
        let reelsVC = ReelsViewController()
        let flicksNav = UINavigationController(rootViewController: reelsVC)
        flicksNav.tabBarItem = UITabBarItem(title: "Flicks",
                                            image: UIImage(systemName: "popcorn.fill"),
                                            tag: 1)

        // Chat → MessagesViewController
        let messagesVC = MessagesViewController()
        let chatNav = UINavigationController(rootViewController: messagesVC)
        chatNav.tabBarItem = UITabBarItem(title: "Chat",
                                          image: UIImage(systemName: "bubble.left.and.bubble.right.fill"),
                                          tag: 2)

        // Mentorship
        let mentorHome = MentorshipHomeViewController()
        let mentorVC = UINavigationController(rootViewController: mentorHome)
        mentorVC.tabBarItem = UITabBarItem(title: "Mentorship",
                                           image: UIImage(systemName: "person.2.fill"),
                                           tag: 3)

        // Jobs
        let jobsVC = UINavigationController(rootViewController: jobsViewController())
        jobsVC.tabBarItem = UITabBarItem(title: "Jobs",
                                         image: UIImage(systemName: "briefcase.fill"),
                                         tag: 4)

        // Final Tab Order
        viewControllers = [homeVC, flicksNav, chatNav, mentorVC, jobsVC]
    }
}
