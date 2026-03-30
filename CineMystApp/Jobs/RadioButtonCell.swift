import UIKit

class RadioButtonCell: UITableViewCell {

    let circleView = UIView()
    let optionLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        selectionStyle = .none

        // Circle View
        circleView.layer.cornerRadius = 10
        circleView.layer.borderWidth = 2
        circleView.layer.borderColor = UIColor.gray.cgColor
        circleView.backgroundColor = .clear

        // Option Label
        optionLabel.font = .systemFont(ofSize: 16)

        contentView.addSubview(circleView)
        contentView.addSubview(optionLabel)

        circleView.translatesAutoresizingMaskIntoConstraints = false
        optionLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            circleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            circleView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            circleView.widthAnchor.constraint(equalToConstant: 20),
            circleView.heightAnchor.constraint(equalToConstant: 20),

            optionLabel.leadingAnchor.constraint(equalTo: circleView.trailingAnchor, constant: 15),
            optionLabel.centerYAnchor.constraint(equalTo: circleView.centerYAnchor)
        ])
    }

    func setSelectedState(_ isSelected: Bool) {
        if isSelected {
            circleView.backgroundColor = UIColor.purple
            circleView.layer.borderColor = UIColor.purple.cgColor
        } else {
            circleView.backgroundColor = .clear
            circleView.layer.borderColor = UIColor.gray.cgColor
        }
    }
}

