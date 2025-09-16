//
//  AvisosViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 10/06/19.
//  Copyright © 2019 Candido Bugarin. All rights reserved.
//

import UIKit
import WebKit
import MapKit



class AvisosViewController: UIViewController,MKMapViewDelegate, UITableViewDelegate, UITableViewDataSource,UICollectionViewDelegate, UICollectionViewDataSource,UISearchBarDelegate {
    
    // Gerenciador de localização para obter dados climáticos
    private var locationManager: CLLocationManager?
    
    @IBOutlet weak var viewtwittertempo: UIView!
    var mob = 0
    var lingua = ""
    var caminho = "https://aplicativo.cocr.com.br/radar"
    
    @IBOutlet weak var viewtransito: UIView!
    var fav: Array<EstacaoMete> = []
    var fav2: Array<Sirene> = []
    var fav15: Array<KM> = []

    var fav4: Array<AlertaN> = []
    var fav8: Array<TTT> = []
    
    var fav18: Array<TTA> = []
    
    var fav20: Array<InterdicoesSite> = []

    var fav19: Array<ComandoFiltro> = []

    var fav3: Array<Cameras> = []
    var fav6: Array<Estacao> = []
    var fav9: Array<Alertas> = []
    var fav13: Array<EstacaoMeteCeu> = []
    var fav14: Array<Tempo> = []
    var fav11: Array<Prev> = []
    var fav12: Array<NC> = []

    @IBOutlet weak var estagio_cidade: UIView!
    @IBOutlet weak var estagio_img: UIImageView!
    @IBOutlet weak var cidade_text: UILabel!
    @IBOutlet weak var textochuva: UILabel!
    @IBOutlet weak var table: UITableView!

    @IBOutlet weak var viewtempo: UIView!
    @IBOutlet weak var viewchuva: UIView!
    @IBOutlet weak var viewconfig: UIView!
    @IBOutlet weak var viewsaude: UIView!
    @IBOutlet weak var viewcarnaval: UIView!
    @IBOutlet weak var viewtelefone: UIView!
    @IBOutlet weak var viewinterdicoes: UIView!
    @IBOutlet weak var viewpontosapoio: UIView!
    @IBOutlet weak var mapscamera: MKMapView!
    @IBOutlet weak var viewradar: UIView!
    @IBOutlet weak var sirenesview: UIView!
    @IBOutlet weak var sirenes_ativas: UILabel!
    @IBOutlet weak var viewcameras: UIView!
    @IBOutlet weak var mapasirene: MKMapView!
    @IBOutlet weak var viewsistema: UIView!
    @IBOutlet weak var ligardc: UIButton!
    @IBOutlet weak var listasirene: UIButton!
    @IBOutlet weak var pontosdeapoio: UIButton!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var quilometro: UILabel!
    @IBOutlet weak var meteoro: UIView!
    @IBOutlet weak var maps: MKMapView!
    
    @IBOutlet weak var fundovale: UIImageView!
    @IBOutlet weak var viewalertas: UIView!
    @IBOutlet weak var scroll: UIScrollView!
    
    @IBOutlet weak var viewfonfon: UIView!
    @IBOutlet weak var condicao: UIImageView!
    @IBOutlet weak var viewcalor: UIView!
    @IBOutlet weak var calorbt: UILabel!
    
    @IBOutlet weak var vento: UILabel!
    @IBOutlet weak var chuva: UILabel!
    @IBOutlet weak var temperatura: UILabel!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var collectionview2: UICollectionView!
    @IBOutlet weak var collectionview: UICollectionView!
    
    @IBOutlet weak var atencaobnt: UILabel!
    @IBOutlet weak var cardHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var painelmetview: UIView!
    
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
    let locManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        

        
        if let url = URL(string: caminho) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        searchBar.delegate = self
        
        
        let xib = UINib(nibName: "AssuntoTableViewCell", bundle: nil)
        self.table.register(xib,forCellReuseIdentifier:"cell")
        self.table.dataSource = self
        self.table.delegate = self
                
        self.tabBarController?.tabBar.isHidden = true
        
        if #available(iOS 15, *) {
            
            let logoContainer = UIView(frame: CGRect(x: 0, y: 0, width: 270, height: 30))
            
            let myimage = UIImage(named: "logo_cor.png")?.withRenderingMode(.alwaysOriginal)

            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
           
            if self.traitCollection.userInterfaceStyle == .dark {
                appearance.backgroundColor = UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 0)
            } else {
                appearance.backgroundColor = UIColor(red: 0.16, green: 0.41, blue: 0.56, alpha: 0)
            }
            
            
            appearance.shadowColor = .none
            
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationItem.titleView = logoContainer
            
            navigationController?.navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance
            
            let rightBarButton = UIBarButtonItem(image: myimage, style: UIBarButtonItem.Style.plain, target: self, action: "")
            self.navigationItem.rightBarButtonItem = rightBarButton
            
            
        }
        
        if CLLocationManager.locationServicesEnabled() {
            switch(CLLocationManager.authorizationStatus()) {
            case .restricted, .denied:
                let alert = UIAlertController(title: "Localização", message: "Seus serviços de localização não foram autorizados. Eles são fundamentais para a visualização das informações. Permita a localização para poder ver o conteúdo.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
                
                
            case .authorizedAlways, .authorizedWhenInUse:
                
                locManager.desiredAccuracy = kCLLocationAccuracyBest
                locManager.startUpdatingLocation()
                
            case .notDetermined:
                
                self.locManager.requestWhenInUseAuthorization()
            }
            
        } else {
            
            self.locManager.requestWhenInUseAuthorization()
            
        }
        
    
        
        maps.userTrackingMode = MKUserTrackingMode.followWithHeading
        maps.showsUserLocation = true
        maps.delegate = self
        
        if let userLocation = locManager.location?.coordinate {
            let viewRegion = MKCoordinateRegion(center: userLocation, latitudinalMeters: 1500, longitudinalMeters: 1500)
            maps.setRegion(viewRegion, animated: false)
        } else {
            let latitude:CLLocationDegrees = -22.9241421//insert latitutde
            let longitude:CLLocationDegrees = -43.4405087 //insert longitud
            let location = CLLocationCoordinate2DMake(latitude, longitude)
            
            let viewRegion = MKCoordinateRegion(center: location,   latitudinalMeters: 1500, longitudinalMeters: 1500)
            maps.setRegion(viewRegion, animated: false)
        }
        
        mapscamera.userTrackingMode = MKUserTrackingMode.followWithHeading
        mapscamera.showsUserLocation = true
        mapscamera.delegate = self
        
        if let userLocation = locManager.location?.coordinate {
            let viewRegion = MKCoordinateRegion(center: userLocation, latitudinalMeters: 1500, longitudinalMeters: 1500)
            mapscamera.setRegion(viewRegion, animated: false)
        } else {
            let latitude:CLLocationDegrees = -22.9241421//insert latitutde
            let longitude:CLLocationDegrees = -43.4405087 //insert longitud
            let location = CLLocationCoordinate2DMake(latitude, longitude)
            
            let viewRegion = MKCoordinateRegion(center: location,   latitudinalMeters: 1500, longitudinalMeters: 1500)
            mapscamera.setRegion(viewRegion, animated: false)
        }
        
        mapasirene.userTrackingMode = MKUserTrackingMode.followWithHeading
        mapasirene.showsUserLocation = true
        mapasirene.delegate = self
        
        if let userLocation = locManager.location?.coordinate {
            let viewRegion = MKCoordinateRegion(center: userLocation, latitudinalMeters: 1500, longitudinalMeters: 1500)
            mapasirene.setRegion(viewRegion, animated: false)
        } else {
            let latitude:CLLocationDegrees = -22.9241421//insert latitutde
            let longitude:CLLocationDegrees = -43.4405087 //insert longitud
            let location = CLLocationCoordinate2DMake(latitude, longitude)
            
            let viewRegion = MKCoordinateRegion(center: location,   latitudinalMeters: 1500, longitudinalMeters: 1500)
            mapasirene.setRegion(viewRegion, animated: false)
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.configTap(_:)))
        self.viewconfig.addGestureRecognizer(tap)
        self.viewconfig.isUserInteractionEnabled = true
        
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(self.saudeTap(_:)))
        self.viewsaude.addGestureRecognizer(tap2)
        self.viewsaude.isUserInteractionEnabled = true
        
        let tap3 = UITapGestureRecognizer(target: self, action: #selector(self.carnaTap(_:)))
        self.viewcarnaval.addGestureRecognizer(tap3)
        self.viewcarnaval.isUserInteractionEnabled = true
        
        let tap4 = UITapGestureRecognizer(target: self, action: #selector(self.telefoneTap(_:)))
        self.viewtelefone.addGestureRecognizer(tap4)
        self.viewtelefone.isUserInteractionEnabled = true
        
        let tap5 = UITapGestureRecognizer(target: self, action: #selector(self.sireneTap(_:)))
        self.sirenesview.addGestureRecognizer(tap5)
        self.sirenesview.isUserInteractionEnabled = true

        let tap6 = UITapGestureRecognizer(target: self, action: #selector(self.pontoTap(_:)))
        self.viewpontosapoio.addGestureRecognizer(tap6)
        self.viewpontosapoio.isUserInteractionEnabled = true
        
        

    
        let tap11 = UITapGestureRecognizer(target: self, action: #selector(self.interTap(_:)))
        self.viewinterdicoes.addGestureRecognizer(tap11)
        self.viewinterdicoes.isUserInteractionEnabled = true
 
        let tap12 = UITapGestureRecognizer(target: self, action: #selector(self.estagioTap(_:)))
        self.estagio_cidade.addGestureRecognizer(tap12)
        self.estagio_cidade.isUserInteractionEnabled = true
        
        collectionview.dataSource = self
        collectionview.delegate = self
        collectionview.register(UINib.init(nibName: "OcorrenciasCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "OcorrenciasCollectionViewCell")

        
        collectionview2.dataSource = self
        collectionview2.delegate = self
        collectionview2.register(UINib.init(nibName: "OcorrenciasCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "OcorrenciasCollectionViewCell")

        self.collectionview2.backgroundColor = UIColor.clear
        self.collectionview.backgroundColor = UIColor.clear
        
        
        self.table.backgroundColor = UIColor.clear

        self.table.estimatedRowHeight = 90 // Um valor aproximado
        self.table.rowHeight = UITableView.automaticDimension
        self.table.isScrollEnabled = false
        self.table.reloadData()
        ajustarAlturaDaTableView()
        
        self.atencaobnt.layer.cornerRadius = 12
        // Do any additional setup after loading the view.
    }
    

    
    
    func ajustarAlturaDaTableView() {
        // Primeiro layout para calcular o tamanho
        table.layoutIfNeeded()
        
        // Calcular a altura total baseada na soma das alturas de cada célula
        var height: CGFloat = 0
        for i in 0..<table.numberOfRows(inSection: 0) {
            let cellHeight = table.rectForRow(at: IndexPath(row: i, section: 0)).height
            height += cellHeight
        }
        
        // Adicionar altura do header e footer se existirem
        if let headerView = table.tableHeaderView {
            height += headerView.frame.height
        }
        if let footerView = table.tableFooterView {
            height += footerView.frame.height
        }
        
        // Atualizar a constraint de altura
        self.tableViewHeightConstraint.constant = height
        
        // Refresh layout
        view.layoutIfNeeded()
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        //Ignoring user
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        //Activity Indicator
        
        if ((UserDefaults.standard.string(forKey: "lingua_usu")) != nil) {
            lingua = UserDefaults.standard.string(forKey: "lingua_usu")!
        } else {
            lingua = UserDefaults.standard.stringArray(forKey: "AppleLanguages")![0]
        }
        
        
        if lingua.contains("pt") {
            self.title = "Câmeras"
           
        } else if lingua.contains("es") {
            self.title = "Cámaras de la ciudad"
            searchBar.placeholder = "Buscar dirección"
        } else {
            self.title = "Street cameras"
            searchBar.placeholder = "Search address"
        }
        
        
        if lingua.contains("pt") {
            let text = "Buscando endereço"
            self.showWaitOverlayWithText(text)
           
        } else if lingua.contains("es") {
            let text = "Buscando dirección"
            self.showWaitOverlayWithText(text)
        } else {
            let text = "Searching for address"
            self.showWaitOverlayWithText(text)
        }
        
        
        
                
        //Hide search bar
        searchBar.resignFirstResponder()
        dismiss(animated: true, completion: nil)
        
        //Create the search request
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchBar.text
        
        let activeSearch = MKLocalSearch(request: searchRequest)
        
        activeSearch.start { (response, error) in
            
            self.removeAllOverlays()
            
            UIApplication.shared.endIgnoringInteractionEvents()
            
            if response == nil
            {
                print("ERROR")
            }
            else
            {
                //Getting data
                let latitude = response?.boundingRegion.center.latitude
                let longitude = response?.boundingRegion.center.longitude
                
                //Zooming in on annotation
                let coordinate:CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude!, longitude!)
                let region = MKCoordinateRegion(center: coordinate,  latitudinalMeters: 1500, longitudinalMeters: 1500)
                self.mapscamera.setRegion(region, animated: true)
                
            }
            
        }
    }
    
    
    
    
    @objc func handleTap3(_ sender: UITapGestureRecognizer) {
        let alert = UIAlertController(title: "Previsão do Tempo", message: self.fav11[0].prev, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
  
    
    
    @objc func configTap(_ sender: UITapGestureRecognizer) {
        let vc = ConfigsViewController(nibName:"ConfigsViewController", bundle:nil)
        self.navigationController!.pushViewController(vc, animated: true)
    }

    
    @objc func saudeTap(_ sender: UITapGestureRecognizer) {
        let vc = HidratacaoNViewController(nibName:"HidratacaoNViewController", bundle:nil)
        self.navigationController!.pushViewController(vc, animated: true)
    }

    @objc func carnaTap(_ sender: UITapGestureRecognizer) {
        let vc = RadarViewController(nibName:"RadarViewController", bundle:nil)
        self.navigationController!.pushViewController(vc, animated: true)
    }
    
    @objc func interTap(_ sender: UITapGestureRecognizer) {
        
        let vc = TextViewController(nibName:"TextViewController", bundle:nil)
        vc.texto_input = self.fav20[0].texto
        vc.titulo = "Interdições programadas"
        vc.fonte_t = "COR.Rio Informa"
        self.navigationController!.pushViewController(vc, animated: true)
    }

    @objc func turTap(_ sender: UITapGestureRecognizer) {
        let vc = TurismoViewController(nibName:"TurismoViewController", bundle:nil)
        self.navigationController!.pushViewController(vc, animated: true)
    }
    
    @objc func sireneTap(_ sender: UITapGestureRecognizer) {
        let vc = ListaSirenesViewController(nibName:"ListaSirenesViewController", bundle:nil)
        vc.fav = self.fav2
        self.navigationController!.pushViewController(vc, animated: true)
    }
    
    @objc func pontoTap(_ sender: UITapGestureRecognizer) {
        let vc = MapaSireneViewController(nibName:"MapaSireneViewController", bundle:nil)
        self.navigationController!.pushViewController(vc, animated: true)
    }
    
    @objc func handleTap2(_ sender: UITapGestureRecognizer) {
        if self.fav12[0].situ.contains("Calor 4") {
            let vc = HidratacaoViewController(nibName:"HidratacaoViewController", bundle:nil)
            self.navigationController!.pushViewController(vc, animated: true)
        }
        else if self.fav12[0].situ.contains("Calor 5") {
            let vc = HidratacaoViewController(nibName:"HidratacaoViewController", bundle:nil)
            self.navigationController!.pushViewController(vc, animated: true)
        } else {
            
            let vc = SirenesViewController(nibName:"SirenesViewController", bundle:nil)
            self.navigationController!.pushViewController(vc, animated: true)
            
 
        }
       
    }
    
    
    @objc func telefoneTap(_ sender: UITapGestureRecognizer) {
        if self.lingua.contains("pt") {
            let uiAlert = UIAlertController(title: "Ligar para Defesa Civil", message: "", preferredStyle: UIAlertController.Style.alert)
            uiAlert.addAction(UIAlertAction(title: "Cancelar", style: .default, handler: { action in
                print("Click of default button")
            }))
            uiAlert.addAction(UIAlertAction(title: "Ligar", style: .default, handler: { action in
                let url: NSURL = URL(string: "TEL://199")! as NSURL
                UIApplication.shared.open(url as URL, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            }))
            self.present(uiAlert, animated: true, completion: nil)
        }
        else if self.lingua.contains("es") {
            let uiAlert = UIAlertController(title: "Llame a Defensa Civil", message: "", preferredStyle: UIAlertController.Style.alert)
            uiAlert.addAction(UIAlertAction(title: "Cancelar", style: .default, handler: { action in
                print("Click of default button")
            }))
            uiAlert.addAction(UIAlertAction(title: "Llamar", style: .default, handler: { action in
                let url: NSURL = URL(string: "TEL://199")! as NSURL
                UIApplication.shared.open(url as URL, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            }))
            self.present(uiAlert, animated: true, completion: nil)

        } else {
            let uiAlert = UIAlertController(title: "Call Civil Defense", message: "", preferredStyle: UIAlertController.Style.alert)
            uiAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { action in
                print("Click of default button")
            }))
            uiAlert.addAction(UIAlertAction(title: "Call", style: .default, handler: { action in
                let url: NSURL = URL(string: "TEL://199")! as NSURL
                UIApplication.shared.open(url as URL, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            }))
            self.present(uiAlert, animated: true, completion: nil)
        }
    }
    
    @objc func estagioTap(_ sender: UITapGestureRecognizer) {
        if self.fav4[0].estagio.contains("NORMALIDADE") {
            let uiAlert = UIAlertController(title: "Estágio 1", message: "A cidade opera dentro da normalidade, sem ocorrências relevantes ou riscos identificados que possam impactar o cotidiano dos cariocas. O trânsito flui normalmente e as operações de infraestrutura e logística seguem sem interferências significativas.", preferredStyle: UIAlertController.Style.alert)
           
           
            uiAlert.addAction(UIAlertAction(title: "Fechar", style: .default, handler: { action in
                print("Click of default button")
            }))
            self.present(uiAlert, animated: true, completion: nil)
        } else if self.fav4[0].estagio.contains("ATENÇÃO") {
            let uiAlert = UIAlertController(title: "Estágio 3", message: "Ocorrências já estão impactando a cidade, ou há certeza de que um evento de alto impacto ocorrerá em breve. Pelo menos uma região começa a sentir reflexos nas estruturas urbanas, no trânsito ou nos serviços, exigindo atenção redobrada da população e das equipes operacionais.", preferredStyle: UIAlertController.Style.alert)
           
           
            uiAlert.addAction(UIAlertAction(title: "Fechar", style: .default, handler: { action in
                print("Click of default button")
            }))
            self.present(uiAlert, animated: true, completion: nil)
        } else if self.fav4[0].estagio.contains("CRISE") {
            let uiAlert = UIAlertController(title: "Estágio 5", message: "A situação atinge um nível crítico, com diversos problemas simultâneos e graves que extrapolam significativamente a capacidade de resposta imediata da cidade. As consequências afetam severamente a infraestrutura, o trânsito e os serviços, com impactos profundos sobre a rotina da população em uma ou mais regiões.", preferredStyle: UIAlertController.Style.alert)
           
           
            uiAlert.addAction(UIAlertAction(title: "Fechar", style: .default, handler: { action in
                print("Click of default button")
            }))
            self.present(uiAlert, animated: true, completion: nil)
        } else if self.fav4[0].estagio.contains("MOBILIZAÇÃO") {
            let uiAlert = UIAlertController(title: "Estágio 2", message: "Há possibilidade de eventos que podem causar impacto na cidade, com base em previsões ou análises técnicas. Ainda não há efeitos visíveis na rotina da população, mas é importante que os cidadãos se mantenham atentos e informados sobre a evolução da situação.", preferredStyle: UIAlertController.Style.alert)
           
           
            uiAlert.addAction(UIAlertAction(title: "Fechar", style: .default, handler: { action in
                print("Click of default button")
            }))
            self.present(uiAlert, animated: true, completion: nil)
        } else if self.fav4[0].estagio.contains("ALERTA") {
            let uiAlert = UIAlertController(title: "Estágio 4", message: "A cidade enfrenta uma ou mais ocorrências graves, ou uma combinação de eventos relevantes em diferentes regiões. Esses impactos comprometem de forma importante a infraestrutura e a logística urbana, afetando diretamente a rotina de parte da população e exigindo forte mobilização das equipes de resposta.", preferredStyle: UIAlertController.Style.alert)
           
           
            uiAlert.addAction(UIAlertAction(title: "Fechar", style: .default, handler: { action in
                print("Click of default button")
            }))
            self.present(uiAlert, animated: true, completion: nil)
        }
    }
    
    @objc func metTap(_ sender: UITapGestureRecognizer) {
        if self.lingua.contains("pt") {
            let uiAlert = UIAlertController(title: "Quer saber mais?", message: "Consulte abaixo os sensores de chuva e de informações meteorológicas da prefeitura", preferredStyle: UIAlertController.Style.alert)
           
            uiAlert.addAction(UIAlertAction(title: "Informações Meteorológicas", style: .default, handler: { action in
                let vc = MapaTemperaturaViewController(nibName:"MapaTemperaturaViewController", bundle:nil)
                self.navigationController!.pushViewController(vc, animated: true)
            }))
            uiAlert.addAction(UIAlertAction(title: "Informações de Chuva", style: .default, handler: { action in
                let vc = MapaViewController(nibName:"MapaViewController", bundle:nil)
                self.navigationController!.pushViewController(vc, animated: true)
            }))
            uiAlert.addAction(UIAlertAction(title: "Fechar", style: .default, handler: { action in
                print("Click of default button")
            }))
            self.present(uiAlert, animated: true, completion: nil)
        }
        else if self.lingua.contains("es") {
            let uiAlert = UIAlertController(title: "Llame a Defensa Civil", message: "", preferredStyle: UIAlertController.Style.alert)
            uiAlert.addAction(UIAlertAction(title: "Cancelar", style: .default, handler: { action in
                print("Click of default button")
            }))
            uiAlert.addAction(UIAlertAction(title: "Llamar", style: .default, handler: { action in
                let url: NSURL = URL(string: "TEL://199")! as NSURL
                UIApplication.shared.open(url as URL, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            }))
            self.present(uiAlert, animated: true, completion: nil)

        } else {
            let uiAlert = UIAlertController(title: "Call Civil Defense", message: "", preferredStyle: UIAlertController.Style.alert)
            uiAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { action in
                print("Click of default button")
            }))
            uiAlert.addAction(UIAlertAction(title: "Call", style: .default, handler: { action in
                let url: NSURL = URL(string: "TEL://199")! as NSURL
                UIApplication.shared.open(url as URL, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            }))
            self.present(uiAlert, animated: true, completion: nil)
        }
    }
    
    
    
    @objc func calorTap(_ sender: UITapGestureRecognizer) {
        if self.fav12[0].situ.contains("Calor 4") {
            let vc = HidratacaoViewController(nibName:"HidratacaoViewController", bundle:nil)
            self.navigationController!.pushViewController(vc, animated: true)
        }
        else if self.fav12[0].situ.contains("Calor 5") {
            let vc = HidratacaoViewController(nibName:"HidratacaoViewController", bundle:nil)
            self.navigationController!.pushViewController(vc, animated: true)
        } else {
            
            let vc = SirenesViewController(nibName:"SirenesViewController", bundle:nil)
            self.navigationController!.pushViewController(vc, animated: true)
            
 
        }
       
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == self.collectionview2 {
                return self.fav18.count // Replace with count of your data for collectionViewA
            }

        return self.fav8.count
        
        }
    

    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OcorrenciasCollectionViewCell", for: indexPath) as! OcorrenciasCollectionViewCell
        
        
        if collectionView == self.collectionview2 {

            // Place content in creators cell
            
        cell.titulo.text = self.fav18[indexPath.row].tt.replacingOccurrences(of: "jumpline", with: "\n", options: NSString.CompareOptions.literal, range:nil)
              
                    
        }

        else {
          
        cell.titulo.text = self.fav8[indexPath.row].tt.replacingOccurrences(of: "jumpline", with: "\n", options: NSString.CompareOptions.literal, range:nil)
                    
        
              
    
          
            
        }
        
        return cell
        
        
    }


    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.fav9.count
        
    }
    
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.table.dequeueReusableCell(withIdentifier: "cell")! as! AssuntoTableViewCell
        cell.titulo.text = self.fav9[indexPath.row].nome
       
   
        return cell
    }
    
    func tableView(_ didSelectRowAttableView:UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.fav9[indexPath.row].audio == "Sim" {
            let vc = MateriaAudioViewController(nibName:"MateriaAudioViewController", bundle:nil)
            vc.texto_input = self.fav9[indexPath.row].mensagem
            vc.titulo = self.fav9[indexPath.row].nome
            vc.poli = self.fav9[indexPath.row].geo
            vc.url = "http://aplicativo.cocr.com.br/"+self.fav9[indexPath.row].audiourl

            vc.fonte_t = "COR RIO Informa"
            self.navigationController!.pushViewController(vc, animated: true)
            
            table.deselectRow(at: indexPath, animated: true)
        } else {
            let vc = MateriaViewController(nibName:"MateriaViewController", bundle:nil)
            vc.texto_input = self.fav9[indexPath.row].mensagem
            vc.titulo = self.fav9[indexPath.row].nome
            vc.poli = self.fav9[indexPath.row].geo

            vc.fonte_t = "COR RIO Informa"
            self.navigationController!.pushViewController(vc, animated: true)
            
            table.deselectRow(at: indexPath, animated: true)
        }
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Don't want to show a custom image if the annotation is the user's location.
        guard !(annotation is MKUserLocation) else {
            return nil
        }
        
        // Better to make this class property
        
        var annotationView: MKAnnotationView?
        if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Pin") {
            annotationView = dequeuedAnnotationView
            annotationView?.annotation = annotation
        }
        else {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "Pin")
        }
    
        if let annotationView = annotationView {
            // Configure your annotation view here
            
            if ((annotationView.annotation?.subtitle)!)!.contains("Sirene") {
                annotationView.canShowCallout = true
                if ((annotationView.annotation?.subtitle)!)!.contains("m") {
                    annotationView.image =  #imageLiteral(resourceName: "sirenesb")
                } else {
                    annotationView.image =  #imageLiteral(resourceName: "sirenesa")
                }
            } else {
                annotationView.canShowCallout = true
                annotationView.image = #imageLiteral(resourceName: "camera")
            }
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if (((view.annotation?.subtitle)!?.contains("Sirene")) == false) {
            
            let id = (view.annotation?.subtitle)!
            if id != nil {
                removeAllGradients()
                let vc = CameraViewController(nibName:"CameraViewController", bundle:nil)
                vc.camera = id!
                self.navigationController!.pushViewController(vc, animated: true)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        
        if control == view.rightCalloutAccessoryView {
            if (((view.annotation?.subtitle)!?.contains("Sirene")) == true) {
           
            let uiAlert = UIAlertController(title: (view.annotation?.title)!, message: (view.annotation?.subtitle)!, preferredStyle: UIAlertController.Style.alert)
            
            uiAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
                print("Click of default button")
            }))
            
            self.present(uiAlert, animated: true, completion: nil)
            } else {
                let id = (view.annotation?.subtitle)!
                if id != nil {
                    let vc = CameraViewController(nibName:"CameraViewController", bundle:nil)
                    vc.camera = id!
                    self.navigationController!.pushViewController(vc, animated: true)
                }
            }
            
            
        }
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        let alert = UIAlertController(title: "Previsão do Tempo", message: self.fav11[0].prev, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func removeExistingGradient() {
        // Encontrar e remover qualquer camada de gradiente existente
        if let sublayers = self.viewconfig.layer.sublayers {
            for layer in sublayers {
                if layer is CAGradientLayer {
                    layer.removeFromSuperlayer()
                }
            }
        }
    }
    
    private func removeAllGradients() {
        // Lista de todas as views que recebem gradientes
        let viewsWithGradients: [UIView] = [
            viewsaude, viewconfig, viewtelefone, viewcarnaval, viewradar,
            viewsistema, viewcameras, viewinterdicoes, viewpontosapoio, viewtempo,
            viewcalor, meteoro, sirenesview, viewfonfon, estagio_cidade
        ].compactMap { $0 } // Remove nulls, embora isso não deva ser necessário

        // Remove gradientes de todas as views
        for view in viewsWithGradients {
            if let sublayers = view.layer.sublayers {
                for layer in sublayers {
                    if layer is CAGradientLayer {
                        layer.removeFromSuperlayer()
                    }
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Sem remover os gradientes aqui, apenas garantindo que os bounds estejam atualizados
        DispatchQueue.main.async {
            // Forçar reposicionamento dos layers de gradiente para se ajustarem aos novos bounds
            for view in [self.viewsaude, self.viewconfig, self.viewtelefone, self.viewcarnaval,
                         self.viewradar, self.viewsistema, self.viewcameras, self.viewinterdicoes,
                         self.viewpontosapoio,
                         self.painelmetview,
                         self.sirenesview, self.viewfonfon, self.estagio_cidade] {
                
                if let sublayers = view!.layer.sublayers {
                    for layer in sublayers {
                        if let gradientLayer = layer as? CAGradientLayer {
                            // Atualiza o frame do gradiente para coincidir com o novo bounds da view
                            gradientLayer.frame = view!.bounds
                        }
                    }
                }
            }
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {


        super.viewWillAppear(animated)
        
        (UIApplication.shared.delegate as? AppDelegate)?.orientation = .portrait
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        UIApplication.navigationTopViewController()?.setNeedsUpdateOfSupportedInterfaceOrientations()
    
        dispatchQueue.async {
            OperationQueue.main.addOperation() {
                
          
                
                if ((UserDefaults.standard.string(forKey: "lingua_usu")) != nil) {
                    self.lingua = UserDefaults.standard.string(forKey: "lingua_usu")!
                } else {
                    self.lingua = UserDefaults.standard.stringArray(forKey: "AppleLanguages")![0]
                }
                
                self.removeExistingGradient()
                
                self.fav = EstacaoMet.getEsta()
                
                self.fav15 = ColetaDados_KM.getdata()
                self.fav2 = ColetaDados_Sirene.getdata()
                self.fav3 = ColetaDados_Cameras.getdata()
                self.fav4 = ColetaDados_Situ.getdata()
                self.fav6 = EstacaoSer.getEsta()
                
                self.fav19 = ColetaDados_ComandoFiltro.getdata()
                
                self.fav11 = ColetaDados_Prev.getdata()
                self.fav12 = ColetaDados_NCSitu.getdata()
                
                self.fav20 = ColetaDados_InterdicoesSite.getdata()
                
                
                self.fav13 = EstacaoMetCeu.getEsta()
                self.fav14 = Porenascer.getEsta()
                
                if self.lingua.contains("pt") {
                    self.fav8 = ColetaDados_TTT.getdata()
                   
                } else if self.lingua.contains("es") {
                    self.fav8 = ColetaDados_TTT_ES.getdata()
                } else {
                    self.fav8 = ColetaDados_TTT_EN.getdata()
                }
                
                
                if self.fav20[0].condicao == "1" {
                    
                
                    
                    self.cardHeightConstraint.constant = 40

                }
                
                var tempo_r = self.isNightTime()
                var ultimo_tempo = self.fav13[0].ceu
                
                
                if self.fav4[0].estagio.contains("NORMALIDADE") {
                    
                    if self.lingua.contains("pt") {
                        self.cidade_text.text = "Estágio 1"
                       
                    } else if self.lingua.contains("es") {
                        self.cidade_text.text = "Nivel 1"
                    } else {
                        self.cidade_text.text = "Stage 1"
                    }
                    
                    self.estagio_img.image = UIImage(named: "05.png")
                    self.estagio_cidade.isHidden = true
                    self.estagio_cidade.isHidden = false

                  

                } else if self.fav4[0].estagio.contains("ATENÇÃO") {
                    if self.lingua.contains("pt") {
                        self.cidade_text.text = "Estágio 3"
                       
                    } else if self.lingua.contains("es") {
                        self.cidade_text.text = "Nivel 3"
                    } else {
                        self.cidade_text.text = "Stage 3"
                    }
                    self.estagio_img.image = UIImage(named: "03.png")
                    self.estagio_cidade.isHidden = true
                    self.estagio_cidade.isHidden = false

                                    
                                    
                } else if self.fav4[0].estagio.contains("CRISE") {
                    if self.lingua.contains("pt") {
                        self.cidade_text.text = "Estágio 5"
                       
                    } else if self.lingua.contains("es") {
                        self.cidade_text.text = "Nivel 5"
                    } else {
                        self.cidade_text.text = "Stage 5"
                    }
                    self.estagio_img.image = UIImage(named: "01.png")
                    self.estagio_cidade.isHidden = true
                    self.estagio_cidade.isHidden = false
                    

                                
                } else if self.fav4[0].estagio.contains("MOBILIZAÇÃO") {
                    if self.lingua.contains("pt") {
                        self.cidade_text.text = "Estágio 2"
                       
                    } else if self.lingua.contains("es") {
                        self.cidade_text.text = "Nivel 2"
                    } else {
                        self.cidade_text.text = "Stage 2"
                    }
                    self.estagio_img.image = UIImage(named: "04.png")
                    self.estagio_cidade.isHidden = true
                    self.estagio_cidade.isHidden = false
                  
                              

                } else if self.fav4[0].estagio.contains("ALERTA") {
                    if self.lingua.contains("pt") {
                        self.cidade_text.text = "Estágio 4"
                       
                    } else if self.lingua.contains("es") {
                        self.cidade_text.text = "Nivel 4"
                    } else {
                        self.cidade_text.text = "Stage 4"
                    }
                    self.estagio_img.image = UIImage(named: "02.png")
                    self.estagio_cidade.isHidden = true
                    self.estagio_cidade.isHidden = false
                    
                   
                                    


                }
                
                
               var x = 0
               var chuva_med = 0.0
                                      var chuv = ""
                                      var est = 1
                                      while x != self.fav6.count {
                                          if self.fav6[x].situ.contains("atraso") == false {
                                            if Double(self.fav6[x].chuva_1) > chuva_med {
                                                chuva_med = Double(self.fav6[x].chuva_1)
                                            }
                                              est += 1
                                          }
                                          x += 1
                                      }
                
                            print(chuva_med)
                                      
                print(chuva_med)
                
                let date = Date()
                let tz = TimeZone.current
                
                print(tz.isDaylightSavingTime(for: date))
            
                
                if Int(chuva_med) == 0 {
                    
                    if self.lingua.contains("pt") {
                        chuv = "Sem chuva"
                    } else if self.lingua.contains("es") {
                        chuv = "Sin lluvia"
                    } else {
                        chuv = "No rain"
                    }
                    
                    if ultimo_tempo == "0" {
                        if tempo_r == false {
                            self.fundovale.image = UIImage(named: "claro.png")
                            //    self.meteoro.isHidden = true
                            //  self.meteoro.isHidden = false
                            //self.meteoro.applyGradient(colours: [UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09),UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09)], radius: 12, sentido: "Vertical")
                        } else {
                            self.fundovale.image = UIImage(named: "lua.png")
                            // self.meteoro.isHidden = true
                            //  self.meteoro.isHidden = false
                            // self.meteoro.applyGradient(colours: [UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09),UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09)], radius: 12, sentido: "Vertical")
                        }
                    } else if ultimo_tempo == "1" {
                        
                        if tempo_r == false {
                            self.fundovale.image = UIImage(named: "ceuclaro.png")
                            //  self.meteoro.isHidden = true
                            // self.meteoro.isHidden = false
                            // self.meteoro.applyGradient(colours: [UIColor(red: 0.26, green: 0.40, blue: 0.52, alpha: 1.00),UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00)], radius: 12, sentido: "Vertical")
                        } else {
                            self.fundovale.image = UIImage(named: "noiteclaro.png")
                            // self.meteoro.isHidden = true
                            // self.meteoro.isHidden = false
                            // self.meteoro.applyGradient(colours: [UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1.00),UIColor(red: 0.17, green: 0.36, blue: 0.52, alpha: 1.00)], radius: 12, sentido: "Vertical")
                        }
                    } else if ultimo_tempo == "2" {
                        if tempo_r == false {

                            self.fundovale.image = UIImage(named: "ceuclaro.png")
                            //  self.meteoro.isHidden = true
                            //  self.meteoro.isHidden = false
                            //  self.meteoro.applyGradient(colours: [UIColor(red: 0.26, green: 0.40, blue: 0.52, alpha: 1.00),UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00)], radius: 12, sentido: "Vertical")

                        } else {
                            self.fundovale.image = UIImage(named: "noiteclaro.png")
                            //    self.meteoro.isHidden = true
                            //  self.meteoro.isHidden = false
                            //  self.meteoro.applyGradient(colours: [UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1.00),UIColor(red: 0.17, green: 0.36, blue: 0.52, alpha: 1.00)], radius: 12, sentido: "Vertical")
                        }
                    } else if ultimo_tempo == "3" {
                        
                        // self.condicao.image = UIImage(named: "fechado.png")
                        //  self.meteoro.isHidden = true
                        // self.meteoro.isHidden = false
                        // self.meteoro.applyGradient(colours: [UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1.00),UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00)], radius: 12, sentido: "Vertical")
                    }
                    
                    
                } else if Int(chuva_med) > 0 && Int(chuva_med) <= 5 {
                    
                    if self.lingua.contains("pt") {
                        chuv = "Chuva fraca"
                    } else if self.lingua.contains("es") {
                        chuv = "Llovizna"
                    } else {
                        chuv = "Light rain"
                    }
                    
                    self.fundovale.image = UIImage(named: "gota_chuva.png")
                    //self.meteoro.isHidden = true
                    // self.meteoro.isHidden = false
                    //self.meteoro.applyGradient(colours: [UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1.00),UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00)], radius: 12, sentido: "Vertical")

                    
                } else if Int(chuva_med) > 5 && Int(chuva_med) <= 25 {
                    
                    if self.lingua.contains("pt") {
                        chuv = "Chuva moderada"
                    } else if self.lingua.contains("es") {
                        chuv = "Lluvia moderada"
                    } else {
                        chuv = "Moderate Rain"
                    }
                    //
                    self.fundovale.image = UIImage(named: "gota_chuva.png")
                    //self.meteoro.isHidden = true
                    //self.meteoro.isHidden = false
                    //self.meteoro.applyGradient(colours: [UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1.00),UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00)], radius: 12, sentido: "Vertical")

                } else if Int(chuva_med) > 25 && Int(chuva_med) <= 50 {
                    
                    if self.lingua.contains("pt") {
                        chuv = "Chuva forte"
                    } else if self.lingua.contains("es") {
                        chuv = "Lluvia fuerte"
                    } else {
                        chuv = "Heavy rain"
                    }
                    
                    self.fundovale.image = UIImage(named: "gota_chuva.png")
                    //self.meteoro.isHidden = true
                    //self.meteoro.isHidden = false
                    //self.meteoro.applyGradient(colours: [UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1.00),UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00)], radius: 12, sentido: "Vertical")

                } else if Int(chuva_med) > 50 {
                    
                    if self.lingua.contains("pt") {
                        chuv = "Chuva muito forte"
                    } else if self.lingua.contains("es") {
                        chuv = "Lluvias muy intensas"
                    } else {
                        chuv = "Very Heavy Rain"
                    }
                    
                    self.fundovale.image = UIImage(named: "gota_chuva.png")
                    //self.meteoro.isHidden = true
                    //self.meteoro.isHidden = false
                    //self.meteoro.applyGradient(colours: [UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1.00),UIColor(red: 0.22, green: 0.51, blue: 0.75, alpha: 1.00)], radius: 12, sentido: "Vertical")

                }
                                      
                                      //let st = 33+((10*((self.fav[0].vel_med*3.6).squareRoot()))+10.45 - self.fav[0].vel_med*3.6)*(((self.fav[0].tem_med)-33)/22)
                                      
        
                 
                                    var vento = ""
                                var vento_max = 1.0
                    
                                    x = 0
                                    while x != self.fav.count {
                                        if Double(self.fav[x].vel_med) > vento_max {
                                            vento_max = Double(self.fav[x].vel_med)
                                                     }
                                                       
                                                   x += 1
                                    }
                
                if vento_max > -1 && vento_max <= 5.1 {
                    
                    if self.lingua.contains("pt") {
                        vento = "Vento fraco"
                    } else if self.lingua.contains("es") {
                        vento = "Viento suave"
                    } else {
                        vento = "Soft wind"
                    }
                     
                 } else if vento_max > 5.1 && vento_max <= 14.4 {
                     
                     if self.lingua.contains("pt") {
                         vento = "Vento moderado"
                     } else if self.lingua.contains("es") {
                         vento = "Viento moderado"
                     } else {
                         vento = "Moderate wind"
                     }
                    
                 } else if vento_max > 14.4 && vento_max <= 21.0 {
                     
                     if self.lingua.contains("pt") {
                         vento = "Vento forte"
                     } else if self.lingua.contains("es") {
                         vento = "Viento fuerte"
                     } else {
                         vento = "Strong wind"
                     }
                   
                 } else if vento_max > 21.0 {
                     
                     if self.lingua.contains("pt") {
                         vento = "Vento muito forte"
                     } else if self.lingua.contains("es") {
                         vento = "viento muy fuerte"
                     } else {
                         vento = "Very strong wind"
                     }
                     
                 }
                
                                            var umd_max = 1.0
                                
                                                x = 0
                                                while x != self.fav.count {
                                                    if Double(self.fav[x].umd_med) > umd_max {
                                                        umd_max = Double(self.fav[x].umd_med)
                                                                 }
                                                                   
                                                               x += 1
                                                }
                                      
                var tem_max = 1.0
                var tem_min = 100.0
                
                x = 0
                while x != self.fav.count {
                    if Double(self.fav[x].tem_med) > tem_max {
                        tem_max = Double(self.fav[x].tem_med)
                    }
                               
                    x += 1
                }
                
                x = 0
                while x != self.fav.count {
                    if Double(self.fav[x].tem_med) < tem_min {
                        tem_min = Double(self.fav[x].tem_med)
                    }
                               
                    x += 1
                }
                      
                
                
                
                self.temperatura.text = "Calor 1"
                self.chuva.text = "\(String(format: chuv))"
                self.vento.text = "\(String(format: vento)) "
                
                
                
            
                
                if self.lingua.contains("pt") {
                    self.fav9 = ColetaDados_Alertas.getdata()
                } else if self.lingua.contains("es") {
                    self.fav9 = ColetaDados_Alertas_ES.getdata()
                } else {
                    self.fav9 = ColetaDados_Alertas_EN.getdata()
                }
                
                if self.lingua.contains("pt") {
                    self.fav18 = ColetaDados_TTA.getdata()
                } else if self.lingua.contains("es") {
                    self.fav18 = ColetaDados_TTA_ES.getdata()
                } else {
                    self.fav18 = ColetaDados_TTA_EN.getdata()
                }
                
                
                x = 0
                while x != self.fav3.count {
                    let point = StoreAnnotation(coordinate:  CLLocationCoordinate2D(latitude: CLLocationDegrees(self.fav3[x].lat) , longitude: CLLocationDegrees(self.fav3[x].lon)))
                    point.title = self.fav3[x].nome
                    point.subtitle = String(self.fav3[x].id)
                    self.mapscamera.addAnnotation(point)
                    x += 1
                }
                
                self.mapscamera.reloadInputViews()
                
                let allAnnotations = self.mapasirene.annotations
                self.mapasirene.removeAnnotations(allAnnotations)
                
                x = 0
                while x != self.fav2.count {
                    let point = StoreAnnotation(coordinate:  CLLocationCoordinate2D(latitude: CLLocationDegrees(self.fav2[x].lat) , longitude: CLLocationDegrees(self.fav2[x].lon)))
                    point.title = self.fav2[x].nome
                    
                 
                    if self.lingua.contains("pt") {
                        if self.fav2[x].status.contains("m") {
                            point.subtitle = "Sirene Mobilizada"
                        } else  {
                            point.subtitle =  "Sirene Desmobilizada"
                        }
                    } else if self.lingua.contains("es") {
                        if self.fav2[x].status.contains("m") {
                            point.subtitle = "Sirena Movilizados"
                        } else  {
                            point.subtitle =  "Sirena desmovilizada"
                        }
                    } else {
                        if self.fav2[x].status.contains("m") {
                        point.subtitle = "Mobilized Siren"
                    } else  {
                        point.subtitle =  "Demobilized Siren"
                    }
                    }
                    
                 
                    self.mapasirene.addAnnotation(point)
                    x += 1
                    // Do any additional setup after loading the view.
                }
                
                self.table.reloadData()
                
                self.table.estimatedRowHeight = 90 // Um valor aproximado
                self.table.rowHeight = UITableView.automaticDimension
                self.table.isScrollEnabled = false
                self.table.translatesAutoresizingMaskIntoConstraints = false
                self.ajustarAlturaDaTableView()
                self.mapasirene.reloadInputViews()
                self.collectionview.reloadData()
                self.collectionview2.reloadData()

                self.mapasirene.layer.cornerRadius = 6
                self.mapscamera.layer.cornerRadius = 6

                self.webView.layer.cornerRadius = 6
                
                
             
                
                

                
                if CLLocationManager.locationServicesEnabled() {
                    switch(CLLocationManager.authorizationStatus()) {
                    case .notDetermined, .restricted, .denied:
                        
                        let alert = UIAlertController(title: "Localização", message: "Seus serviços de localização não foram autorizados. Eles são fundamentais para a visualização das informações. Permita a localização para poder ver o conteúdo.", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        
                        var x = 0
                        while x != self.fav2.count {
                            if self.fav2[x].status.contains("m") {

                        
                                 self.mob += 1
                            }
                            x += 1
                        }
                        
                        if  self.mob != 0  {
                            self.sirenesview.applyGradient(colours: [UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09),UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09)], radius: 12, sentido: "Horizontal")

                            if self.lingua.contains("pt") {
                                self.sirenes_ativas.text = "Sirenes acionadas no momento"
                            } else if self.lingua.contains("es") {
                                self.sirenes_ativas.text = "Sirenas activadas al momento"
                            } else {
                                self.sirenes_ativas.text = "Sirens activated at the moment"
                            }
                            
                        } else {
                            self.sirenesview.applyGradient(colours: [UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09),UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09)], radius: 12, sentido: "Horizontal")


                            if self.lingua.contains("pt") {
                                self.sirenes_ativas.text = "Sem sirenes acionadas no momento"
                            } else if self.lingua.contains("es") {
                                self.sirenes_ativas.text = "No hay sirenas activadas en este momento."
                            } else {
                                self.sirenes_ativas.text = "No sirens activated at the moment"
                            }
                        }
                        
                        
                    case .authorizedAlways, .authorizedWhenInUse:
                        self.locManager.startUpdatingLocation()
                        var x = 0
                        var perto = 0
                        while x != self.fav2.count {
                            if self.fav2[x].status.contains("m") {

                                let distanceInMeters = CLLocation(latitude: self.fav2[x].lat, longitude: self.fav2[x].lon).distance(from: CLLocation(latitude: (self.locManager.location?.coordinate.latitude)!, longitude: (self.locManager.location?.coordinate.longitude)!))
                                if distanceInMeters > 2000 {
                                    perto += 1
                                }
                                self.mob += 1
                            }
                            x += 1
                        }
                        
                        
                        
                        if  self.mob != 0 && perto == 0 {
                           
                            
                            self.sirenesview.applyGradient(colours: [UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09),UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09)], radius: 12, sentido: "Horizontal")
                            
                            if self.lingua.contains("pt") {
                                self.sirenes_ativas.text = "Sirenes acionadas no momento"
                            } else if self.lingua.contains("es") {
                                self.sirenes_ativas.text = "Sirenas activadas al momento"
                            } else {
                                self.sirenes_ativas.text = "Sirens activated at the moment"
                            }
                        } else if  self.mob != 0 && perto != 0 {
                            
                            
                            self.sirenesview.applyGradient(colours: [UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09),UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09)], radius: 12, sentido: "Horizontal")
                            
                             self.sirenes_ativas.text = "Sirenes acionadas nas próximidades"
                            
                            if self.lingua.contains("pt") {
                                self.sirenes_ativas.text = "Sirenes acionadas nas próximidades"
                            } else if self.lingua.contains("es") {
                                self.sirenes_ativas.text = "Sirenas activadas cerca"
                            } else {
                                self.sirenes_ativas.text = "Sirens activated nearby"
                            }
                            
                        } else {
                            
                            self.sirenesview.applyGradient(colours: [UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09),UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09)], radius: 12, sentido: "Horizontal")
                            

                            if self.lingua.contains("pt") {
                                self.sirenes_ativas.text = "Sem sirenes acionadas no momento"
                            } else if self.lingua.contains("es") {
                                self.sirenes_ativas.text = "No hay sirenas activadas en este momento."
                            } else {
                                self.sirenes_ativas.text = "No sirens activated at the moment"
                            }
                        }
                    }
                        
                } else {
                    let alert = UIAlertController(title: "Localização", message: "Estamos enfretando problemas com sua localização, estamos tentando restabelecer a conexão.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                    var x = 0
                    while x != self.fav2.count {
                        if self.fav2[x].status.contains("m") {
                    
                            
                             self.mob += 1
                        }
                        x += 1
                    }
                    
                    if  self.mob != 0  {
                        self.sirenesview.applyGradient(colours: [UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09),UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09)], radius: 12, sentido: "Horizontal")
                        
                        if self.lingua.contains("pt") {
                            self.sirenes_ativas.text = "Sirenes acionadas no momento"
                        } else if self.lingua.contains("es") {
                            self.sirenes_ativas.text = "Sirenas activadas al momento"
                        } else {
                            self.sirenes_ativas.text = "Sirens activated at the moment"
                        }


                        
                    } else {
                        self.sirenesview.applyGradient(colours: [UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09),UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09)], radius: 12, sentido: "Horizontal")
                        
                        if self.lingua.contains("pt") {
                            self.sirenes_ativas.text = "Sem sirenes acionadas no momento"
                        } else if self.lingua.contains("es") {
                            self.sirenes_ativas.text = "No hay sirenas activadas en este momento."
                        } else {
                            self.sirenes_ativas.text = "No sirens activated at the moment"
                        }
                        
                    
                        
                    }
                }
                
        
                
                if self.lingua.contains("pt") {
                    if self.fav15[0].tt == ("normal para o horário") {
                        self.viewfonfon.applyGradient(colours: [UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09),UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09)], radius: 12, sentido: "Horizontal")

                            
                    } else if self.fav15[0].tt == ("acima do normal para o horário") {
                        self.viewfonfon.applyGradient(colours: [UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09),UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09)], radius: 12, sentido: "Horizontal")

                    } else if self.fav15[0].tt == ("muito acima do normal para o horário") {
                        self.viewfonfon.applyGradient(colours: [UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09),UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09)], radius: 12, sentido: "Horizontal")

                    }

                    self.quilometro.text = "Trânsito "+(self.fav15[0].tt)
                   
                } else if self.lingua.contains("es") {
                    if self.fav15[0].tt == ("normal para o horário") {
                        self.viewfonfon.applyGradient(colours: [UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09),UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09)], radius: 12, sentido: "Horizontal")
                        self.quilometro.text = "Tráfico normal"

                            
                    } else if self.fav15[0].tt == ("acima do normal para o horário") {
                        self.viewfonfon.applyGradient(colours: [UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09),UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09)], radius: 12, sentido: "Horizontal")
                        self.quilometro.text = "tráfico por encima del normal"

                    } else if self.fav15[0].tt == ("muito acima do normal para o horário") {
                        self.viewfonfon.applyGradient(colours: [UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09),UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09)], radius: 12, sentido: "Horizontal")
                        self.quilometro.text = "tráfico mucho más alto de lo normal"

                    }

                    
                } else {
                    if self.fav15[0].tt == ("normal para o horário") {
                        self.viewfonfon.applyGradient(colours: [UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09),UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09)], radius: 12, sentido: "Horizontal")
                        self.quilometro.text = "Usual traffic for time"

                            
                    } else if self.fav15[0].tt == ("acima do normal para o horário") {
                        self.viewfonfon.applyGradient(colours: [UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09),UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09)], radius: 12, sentido: "Horizontal")
                        self.quilometro.text = "traffic higher than normal"

                    } else if self.fav15[0].tt == ("muito acima do normal para o horário") {
                        self.viewfonfon.applyGradient(colours: [UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09),UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.09)], radius: 12, sentido: "Horizontal")
                        self.quilometro.text = "traffic much higher than normal"

                    }

                }
                
                
                
                self.applySoftUIStyle(to: self.viewtwittertempo)
                self.applySoftUIStyle(to: self.viewtransito)
                self.applySoftUIStyle(to: self.viewpontosapoio)
                self.applySoftUIStyle(to: self.viewinterdicoes)
                self.applySoftUIStyle(to: self.viewcameras)
                self.applySoftUIStyle(to: self.viewcarnaval)
                self.applySoftUIStyle(to: self.viewsistema)
                self.applySoftUIStyle(to: self.viewtelefone)
                self.applySoftUIStyle(to: self.viewconfig)
                self.applySoftUIStyle(to: self.viewsaude)
                self.applySoftUIStyle(to: self.viewalertas)
                self.applySoftUIStyle(to: self.viewradar)
                self.applySoftUIStyle(to: self.painelmetview)
                
            }
            
            
            
        }
        
        
        
    }
    
    func applySoftUIStyle(to view: UIView) {
        view.applyGradient(colours: [UIColor(red: 0.455, green: 0.624, blue: 0.851, alpha: 0.70),UIColor(red: 0.404, green: 0.557, blue: 0.788, alpha: 0.50)], radius: 12, sentido: "Horizontal")
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.8
        view.layer.shadowRadius = 4
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
    
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        ajustarAlturaDaTableView()
    }
    
    func isNightTime() -> Bool {
        let date = Date()
        let calendar = Calendar.current
        
        // Obter o mês e a hora atual
        let month = calendar.component(.month, from: date)
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let currentTimeInMinutes = hour * 60 + minute
        
        // Estimar horários de nascer e pôr do sol baseado no mês (para latitude aproximada 40°N)
        var sunriseHour = 0
        var sunriseMinute = 0
        var sunsetHour = 0
        var sunsetMinute = 0
        
        switch month {
        case 12, 1, 2: // Inverno
            sunriseHour = 7
            sunriseMinute = 30
            sunsetHour = 17
            sunsetMinute = 0
        case 3, 4, 5: // Primavera
            sunriseHour = 6
            sunriseMinute = 30
            sunsetHour = 19
            sunsetMinute = 0
        case 6, 7, 8: // Verão
            sunriseHour = 5
            sunriseMinute = 30
            sunsetHour = 20
            sunsetMinute = 30
        case 9, 10, 11: // Outono
            sunriseHour = 6
            sunriseMinute = 30
            sunsetHour = 18
            sunsetMinute = 30
        default:
            break
        }
        
        // Converter horários para minutos desde meia-noite
        let sunriseTimeInMinutes = sunriseHour * 60 + sunriseMinute
        let sunsetTimeInMinutes = sunsetHour * 60 + sunsetMinute
        
        // Determinar se é dia ou noite
        // Retorna true para noite, false para dia (como na função original)
        return currentTimeInMinutes < sunriseTimeInMinutes || currentTimeInMinutes >= sunsetTimeInMinutes
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: - Enums para condições climáticas e período do dia

fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
