// SceneDelegate.swift
// CineMystApp

import UIKit
import Supabase

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // MARK: - App Launch
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(windowScene: windowScene)

        // Check for URL from connectionOptions (cold start)
        if let url = connectionOptions.urlContexts.first?.url {
            print("🔵 App opened with URL (cold start): \(url)")
            handleIncomingURL(url)
            return
        }

        // Normal app launch - check auth state
        Task {
            await determineInitialScreen()
        }
    }

    // MARK: - OAuth Redirect Handling (Hot Start)
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        print("🔵 App opened with URL (hot start): \(url)")
        handleIncomingURL(url)
        print("SUPABASE_URL:",
              Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") ?? "❌ missing")

    }

    // MARK: - Handle Incoming OAuth URL
    private func handleIncomingURL(_ url: URL) {
        print("🔗 Processing URL: \(url.absoluteString)")
        
        Task {
            do {
                // This processes the OAuth callback
                try await supabase.auth.handle(url)
                print("✅ OAuth callback handled successfully")
                
                // Small delay to let session save
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // Now check session and navigate
                await determineInitialScreen()
                
            } catch {
                print("❌ Error handling OAuth callback: \(error)")
                await MainActor.run {
                    showLoginScreen()
                }
            }
        }
    }

    // MARK: - Determine Initial Screen
    @MainActor
    private func determineInitialScreen() async {
        do {
            let session = try await supabase.auth.session
            
            print("📱 Session check:")
            print("   User: \(session.user.email ?? "unknown")")
            print("   Expired: \(session.isExpired)")
            
            if session.isExpired {
                print("🟡 Session expired → Login")
                showLoginScreen()
            } else {
                print("✅ Valid session → Checking profile...")
                
                // Check if user has completed profile
                let hasProfile = await checkUserProfile(userId: session.user.id)
                
                if hasProfile {
                    print("✅ Profile exists → Home")
                    showHomeScreen()
                } else {
                    print("⚠️ No profile → Onboarding")
                    showOnboardingScreen()
                }
            }
            
        } catch {
            print("🟡 No session → Login")
            showLoginScreen()
        }
    }
    
    // MARK: - Check User Profile
    private func checkUserProfile(userId: UUID) async -> Bool {
        do {
            let response = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
            
            return response.data.count > 0
        } catch {
            print("⚠️ Profile check error: \(error)")
            return false
        }
    }

    // MARK: - Navigation Helpers
    @MainActor
    private func showLoginScreen() {
        let loginVC = LoginViewController(nibName: "LoginViewController", bundle: nil)
        let nav = UINavigationController(rootViewController: loginVC)
        nav.setNavigationBarHidden(true, animated: false)
        window?.rootViewController = nav
        window?.makeKeyAndVisible()
    }
    
    @MainActor
    private func showHomeScreen() {
        // Dismiss any presented view controllers (like Safari)
        window?.rootViewController?.dismiss(animated: true)
        
        window?.rootViewController = CineMystTabBarController()
        window?.makeKeyAndVisible()
    }
    
    @MainActor
    private func showOnboardingScreen() {
        // Dismiss any presented view controllers
        window?.rootViewController?.dismiss(animated: true)
        
        let coordinator = OnboardingCoordinator()
        let birthdayVC = BirthdayViewController()
        birthdayVC.coordinator = coordinator
        
        let nav = UINavigationController(rootViewController: birthdayVC)
        window?.rootViewController = nav
        window?.makeKeyAndVisible()
    }
}
