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

    // MARK: - Tab Bar Setup
    private func setupTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = UIColor(white: 0, alpha: 0.2)

        let activeColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1)
        appearance.stackedLayoutAppearance.selected.iconColor = activeColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: activeColor]
        appearance.stackedLayoutAppearance.normal.iconColor = .systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray]

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = activeColor
        tabBar.unselectedItemTintColor = .systemGray

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
