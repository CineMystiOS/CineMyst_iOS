import UIKit
class WrappingStackView: UIView {
    
    private let itemSpacing: CGFloat = 10
    private let lineSpacing: CGFloat = 10
    private var arrangedSubviews: [UIView] = []

    func addArrangedSubview(_ view: UIView) {
        arrangedSubviews.append(view)
        addSubview(view)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        var x: CGFloat = 0
        var y: CGFloat = 0
        let maxWidth = bounds.width

        arrangedSubviews.forEach { view in
            let size = view.systemLayoutSizeFitting(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))

            if x + size.width > maxWidth {
                x = 0
                y += size.height + lineSpacing
            }

            view.frame = CGRect(x: x, y: y, width: size.width, height: size.height)
            x += size.width + itemSpacing
        }
    }

    override var intrinsicContentSize: CGSize {
        var x: CGFloat = 0
        var y: CGFloat = 0
        let maxWidth = UIScreen.main.bounds.width - 40 // padding

        arrangedSubviews.forEach { view in
            let size = view.systemLayoutSizeFitting(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))

            if x + size.width > maxWidth {
                x = 0
                y += size.height + lineSpacing
            }

            x += size.width + itemSpacing
        }
        return CGSize(width: maxWidth, height: y + 40)
    }
}

