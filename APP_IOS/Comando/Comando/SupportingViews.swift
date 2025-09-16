import UIKit
import MapKit
// MARK: - AlertTableViewCell

class AlertTableViewCell: UITableViewCell {
    
    private let titleLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.numberOfLines = 0
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }
    
    func configure(with alerta: Alertas) {
        titleLabel.text = alerta.nome
    }
}



// MARK: - InfoCollectionViewCell

class InfoCollectionViewCell: UICollectionViewCell {
    
    private let infoLabel = UILabel()
    private let containerView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        containerView.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
        containerView.layer.cornerRadius = 8
        
        contentView.addSubview(containerView)
        containerView.addSubview(infoLabel)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        infoLabel.textColor = .white
        infoLabel.font = UIFont.systemFont(ofSize: 14)
        infoLabel.numberOfLines = 0
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            infoLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            infoLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            infoLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            infoLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10)
        ])
    }
    
    func configure(with info: String) {
        infoLabel.text = info
    }
}

// MARK: - StoreAnnotation (para mapas)

class StoreAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String? = nil, subtitle: String? = nil) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        super.init()
    }
}

// MARK: - LoadingOverlay

class LoadingOverlay {
    
    var overlayView = UIView()
    var activityIndicator = UIActivityIndicatorView()
    var loadingTextLabel = UILabel()
    
    class var shared: LoadingOverlay {
        struct Singleton {
            static let instance = LoadingOverlay()
        }
        return Singleton.instance
    }
    
    public func showOverlay(view: UIView, text: String = "Carregando...") {
        overlayView.frame = view.frame
        overlayView.center = view.center
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        activityIndicator.style = .large
        activityIndicator.color = .white
        activityIndicator.center = CGPoint(x: overlayView.bounds.width / 2, y: overlayView.bounds.height / 2 - 30)
        
        loadingTextLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
        loadingTextLabel.center = CGPoint(x: overlayView.bounds.width / 2, y: overlayView.bounds.height / 2 + 20)
        loadingTextLabel.textAlignment = .center
        loadingTextLabel.text = text
        loadingTextLabel.textColor = .white
        loadingTextLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        overlayView.addSubview(activityIndicator)
        overlayView.addSubview(loadingTextLabel)
        view.addSubview(overlayView)
        
        activityIndicator.startAnimating()
    }
    
    public func hideOverlayView() {
        activityIndicator.stopAnimating()
        overlayView.removeFromSuperview()
    }
}

// MARK: - Extensions

extension UIViewController {
    func showWaitOverlayWithText(_ text: String) {
        LoadingOverlay.shared.showOverlay(view: self.view, text: text)
    }
    
    func removeAllOverlays() {
        LoadingOverlay.shared.hideOverlayView()
    }
}

extension UIView {
    func applyGradient(colours: [UIColor], radius: CGFloat, sentido: String) {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = colours.map { $0.cgColor }
        
        if sentido == "Horizontal" {
            gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
            gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        } else {
            gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
            gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        }
        
        gradient.cornerRadius = radius
        
        self.layer.insertSublayer(gradient, at: 0)
    }
}
