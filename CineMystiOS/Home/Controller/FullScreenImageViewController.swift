//
//  FullScreenImageViewController.swift
//  CineMystApp
//
//  Created by user55 on 16/04/26.
//

import UIKit

final class MediaFullScreenViewController: UIViewController, UIScrollViewDelegate {
    
    private let urls: [String]
    private var selectedIndex: Int
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.isPagingEnabled = true
        sv.showsHorizontalScrollIndicator = false
        sv.backgroundColor = .black
        return sv
    }()
    
    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "xmark"), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        btn.layer.cornerRadius = 20
        return btn
    }()
    
    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.hidesForSinglePage = true
        return pc
    }()
    
    init(urls: [String], selectedIndex: Int) {
        self.urls = urls
        self.selectedIndex = selectedIndex
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        loadImages()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        scrollView.contentSize = CGSize(width: view.bounds.width * CGFloat(urls.count), height: view.bounds.height)
        
        for (index, subview) in scrollView.subviews.enumerated() {
            subview.frame = CGRect(x: CGFloat(index) * view.bounds.width, y: 0, width: view.bounds.width, height: view.bounds.height)
            if let imgScrollView = subview as? UIScrollView, let iv = imgScrollView.subviews.first as? UIImageView {
                imgScrollView.zoomScale = 1.0
                iv.frame = imgScrollView.bounds
            }
        }
        
        let xOffset = CGFloat(selectedIndex) * view.bounds.width
        scrollView.setContentOffset(CGPoint(x: xOffset, y: 0), animated: false)
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.delegate = self
        
        view.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        
        view.addSubview(pageControl)
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        pageControl.numberOfPages = urls.count
        pageControl.currentPage = selectedIndex
    }
    
    private func loadImages() {
        for (index, urlString) in urls.enumerated() {
            let imgScrollView = UIScrollView()
            imgScrollView.delegate = self
            imgScrollView.minimumZoomScale = 1.0
            imgScrollView.maximumZoomScale = 4.0
            imgScrollView.showsVerticalScrollIndicator = false
            imgScrollView.showsHorizontalScrollIndicator = false
            
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFit
            imgScrollView.addSubview(iv)
            scrollView.addSubview(imgScrollView)
            
            if let url = URL(string: urlString) {
                URLSession.shared.dataTask(with: url) { data, _, _ in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            iv.image = image
                        }
                    }
                }.resume()
            }
        }
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - UIScrollViewDelegate
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == self.scrollView {
            let page = Int(scrollView.contentOffset.x / scrollView.bounds.width)
            selectedIndex = page
            pageControl.currentPage = page
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if scrollView != self.scrollView {
            return scrollView.subviews.first
        }
        return nil
    }
}
