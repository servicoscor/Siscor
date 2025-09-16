//
//  ConfigsViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 31/07/23.
//  Copyright © 2023 Candido Bugarin. All rights reserved.
//

import UIKit
import Firebase
import FirebaseInstanceID
import FirebaseMessaging

private let SectionVegetables = 0
private let SectionDesserts = 1
private let NumberOfSections = 2

class ConfigsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,MessagingDelegate,UISearchBarDelegate {
    
    @IBOutlet weak var linguatitulo: UILabel!
    @IBOutlet weak var esb: UIButton!
    @IBOutlet weak var enb: UIButton!
    @IBOutlet weak var ptb: UIButton!
    @IBOutlet weak var prev: UIButton!
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var titulo: UILabel!
    
    var fav: Array<Bairros> = []
    
    var lingua = ""
        
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)

    var vegetables = ["Todos","Abolição","Acari","Água Santa","Alto da Boa Vista","Anchieta","Andaraí","Anil","Bancários","Bangu","Barra da Tijuca","Barra de Guaratiba","Barros Filho","Benfica","Bento Ribeiro","Bonsucesso","Botafogo","Brás de Pina","Cachambi","Cacuia","Caju","Camorim","Campinho","Campo dos Afonsos","Campo Grande","Cascadura","Catete","Catumbi","Cavalcanti","Centro","Cidade de Deus","Cidade Nova","Cidade Universitária","Cocotá","Coelho Neto","Colégio","Complexo do Alemão","Copacabana","Cordovil","Cosme Velho","Cosmos","Costa Barros","Curicica","Del Castilho","Deodoro","Encantado","Engenheiro Leal","Engenho da Rainha","Engenho de Dentro","Engenho Novo","Estácio","Flamengo","Freguesia (Ilha)","Freguesia (Jacarepaguá)","Galeão","Gamboa","Gardênia Azul","Gávea","Glória","Grajaú","Grumari","Guadalupe","Guaratiba","Higienópolis","Honório Gurgel","Humaitá","Inhaúma","Inhoaíba","Ipanema","Irajá","Itanhangá","Jacaré","Jacarepaguá","Jacarezinho","Jardim América","Jardim Botânico","Jardim Carioca","Jardim Guanabara","Jardim Sulacap","Joá","Lagoa","Laranjeiras","Leblon","Leme","Lins de Vasconcelos","Madureira","Magalhães Bastos","Mangueira","Manguinhos","Maracanã","Maré","Marechal Hermes","Maria da Graça","Méier","Moneró","Olaria","Osvaldo Cruz","Paciência","Padre Miguel","Parada de Lucas","Parque Anchieta","Parque Colúmbia","Pavuna","Pechincha","Pedra de Guaratiba","Penha","Penha Circular","Piedade","Pilares","Pitangueiras","Portuguesa","Praça da Bandeira","Praça Seca","Praia da Bandeira","Quintino Bocaiúva","Ramos","Realengo","Recreio dos Bandeirantes","Riachuelo","Ribeira","Ricardo de Albuquerque","Rio Comprido","Rocha","Rocha Miranda","Rocinha","Sampaio","Santa Cruz","Santa Teresa","Santíssimo","Santo Cristo","São Conrado","São Cristóvão","São Francisco Xavier","Saúde","Senador Camará","Senador Vasconcelos","Sepetiba","Tanque","Taquara","Tauá","Tijuca","Todos os Santos","Tomás Coelho","Turiaçú","Urca","Vargem Grande","Vargem Pequena","Vasco da Gama","Vaz Lobo","Vicente de Carvalho","Vidigal","Vigário Geral","Vila da Penha","Vila Isabel","Vila Kosmos","Vila Militar","Vila Valqueire","Vista Alegre","Zumbi"]
    
    var meus_bairros = [String]()
    
    var filteredData = [String]()

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
      
        
        table.dataSource = self
        table.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        table.allowsMultipleSelectionDuringEditing = true
        table.setEditing(true, animated: true)
        
        
     
        
        
        
        
        if #available(iOS 15, *) {
            
            let logoContainer = UIView(frame: CGRect(x: 0, y: 0, width: 270, height: 30))
            
            let myimage = UIImage(named: "logo_cor.png")?.withRenderingMode(.alwaysOriginal)


            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
           
            if self.traitCollection.userInterfaceStyle == .dark {
                appearance.backgroundColor = UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1.00)
            } else {
                appearance.backgroundColor = UIColor(red: 0.30, green: 0.50, blue: 0.73, alpha: 1.00)
            }
            
            
            appearance.shadowColor = .none
            
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationItem.titleView = logoContainer
            
            navigationController?.navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance
            
            let rightBarButton = UIBarButtonItem(image: myimage, style: UIBarButtonItem.Style.plain, target: self, action: "")
            self.navigationItem.rightBarButtonItem = rightBarButton
            
            
        }
        
      
        
    }
    

    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return vegetables.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
            cell.textLabel?.text = vegetables[indexPath.item]
            
            return cell
    }

    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if meus_bairros.contains(where: {(($0 as AnyObject) as! String) == vegetables[indexPath.item]}) {
            table.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    
        
    }
    

    @IBAction func salvar_infos(_ sender: UIButton) {
        
        let lista = table.indexPathsForSelectedRows
        
        var array = [String]()
        
        if (lista?.count) != nil {
            
            var x = 0
            while x != lista?.count {
            
            let sub = (lista![x])
            array.append(vegetables[sub[1]])
            x += 1
        }
        
        }
        
        if Messaging.messaging().fcmToken != nil {
                   
            let jsonData = try? JSONSerialization.data(withJSONObject: array, options: [])
                   
            let url = URL(string: "https://aplicativo.cocr.com.br/bairros_insert/"+Messaging.messaging().fcmToken!)!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
                   
                   // insert json data to the request
            request.httpBody = jsonData
                   
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    print(error?.localizedDescription ?? "No data")
                    return
                }
                let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
                    if let responseJSON = responseJSON as? [String: Any] {
                        print(responseJSON)
                    }
                }
                   
                task.resume()
                   
            }
    
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return true
        
    }
    @IBAction func es_ac(_ sender: Any) {
        
        if ((UserDefaults.standard.string(forKey: "lingua_usu")) != nil) {
            lingua = UserDefaults.standard.string(forKey: "lingua_usu")!
        } else {
            lingua = UserDefaults.standard.stringArray(forKey: "AppleLanguages")![0]
        }
        
        
        if lingua.contains("pt") {
            title = "Configurar alertas"
           
        } else if lingua.contains("es") {
            title = "Configurar alertas"
            self.titulo.text = "Seleccione los vecindarios de los cuales desea recibir alertas."
            self.prev.setTitle("Guardar", for: UIControl.State.normal)
            self.enb.setTitle("🇺🇸 Inglés", for: UIControl.State.normal)
            self.ptb.setTitle("🇧🇷 Portugués", for: UIControl.State.normal)
            self.esb.setTitle("🇪🇸 Español", for: UIControl.State.normal)
            self.linguatitulo.text = "Seleccione su idioma preferido:"

        } else {
            title = "Configure alerts"
            self.linguatitulo.text = "Select your preferred language:"
            self.titulo.text = "Select below which neighborhoods you want to receive alerts."
            self.prev.setTitle("Save", for: UIControl.State.normal)
            self.enb.setTitle("🇺🇸 English", for: UIControl.State.normal)
            self.ptb.setTitle("🇧🇷 Portuguese", for: UIControl.State.normal)
            self.esb.setTitle("🇪🇸 Spanish", for: UIControl.State.normal)

        }
        
        UserDefaults.standard.set("es", forKey: "lingua_usu")
        
        if ((UserDefaults.standard.string(forKey: "lingua_usu")) != nil) {
            lingua = UserDefaults.standard.string(forKey: "lingua_usu")!
        } else {
            lingua = UserDefaults.standard.stringArray(forKey: "AppleLanguages")![0]
        }
        
        
        if lingua.contains("pt") {
            title = "Configurar alertas"
           
        } else if lingua.contains("es") {
            title = "Configurar alertas"
            self.titulo.text = "Seleccione los vecindarios de los cuales desea recibir alertas."
            self.prev.setTitle("Guardar", for: UIControl.State.normal)
            self.enb.setTitle("🇺🇸 Inglés", for: UIControl.State.normal)
            self.ptb.setTitle("🇧🇷 Portugués", for: UIControl.State.normal)
            self.esb.setTitle("🇪🇸 Español", for: UIControl.State.normal)
            self.linguatitulo.text = "Seleccione su idioma preferido:"

        } else {
            title = "Configure alerts"
            self.linguatitulo.text = "Select your preferred language:"
            self.titulo.text = "Select below which neighborhoods you want to receive alerts."
            self.prev.setTitle("Save", for: UIControl.State.normal)
            self.enb.setTitle("🇺🇸 English", for: UIControl.State.normal)
            self.ptb.setTitle("🇧🇷 Portuguese", for: UIControl.State.normal)
            self.esb.setTitle("🇪🇸 Spanish", for: UIControl.State.normal)

        }
   
    }
    
    @IBAction func en_ac(_ sender: Any) {
        
        if ((UserDefaults.standard.string(forKey: "lingua_usu")) != nil) {
            lingua = UserDefaults.standard.string(forKey: "lingua_usu")!
        } else {
            lingua = UserDefaults.standard.stringArray(forKey: "AppleLanguages")![0]
        }
        
        
        if lingua.contains("pt") {
            title = "Configurar alertas"
           
        } else if lingua.contains("es") {
            title = "Configurar alertas"
            self.titulo.text = "Seleccione los vecindarios de los cuales desea recibir alertas."
            self.prev.setTitle("Guardar", for: UIControl.State.normal)
            self.enb.setTitle("🇺🇸 Inglés", for: UIControl.State.normal)
            self.ptb.setTitle("🇧🇷 Portugués", for: UIControl.State.normal)
            self.esb.setTitle("🇪🇸 Español", for: UIControl.State.normal)
            self.linguatitulo.text = "Seleccione su idioma preferido:"

        } else {
            title = "Configure alerts"
            self.linguatitulo.text = "Select your preferred language:"
            self.titulo.text = "Select below which neighborhoods you want to receive alerts."
            self.prev.setTitle("Save", for: UIControl.State.normal)
            self.enb.setTitle("🇺🇸 English", for: UIControl.State.normal)
            self.ptb.setTitle("🇧🇷 Portuguese", for: UIControl.State.normal)
            self.esb.setTitle("🇪🇸 Spanish", for: UIControl.State.normal)

        }
        
        UserDefaults.standard.set("en", forKey: "lingua_usu")
        
        if ((UserDefaults.standard.string(forKey: "lingua_usu")) != nil) {
            lingua = UserDefaults.standard.string(forKey: "lingua_usu")!
        } else {
            lingua = UserDefaults.standard.stringArray(forKey: "AppleLanguages")![0]
        }
        
        
        if lingua.contains("pt") {
            title = "Configurar alertas"
           
        } else if lingua.contains("es") {
            title = "Configurar alertas"
            self.titulo.text = "Seleccione los vecindarios de los cuales desea recibir alertas."
            self.prev.setTitle("Guardar", for: UIControl.State.normal)
            self.enb.setTitle("🇺🇸 Inglés", for: UIControl.State.normal)
            self.ptb.setTitle("🇧🇷 Portugués", for: UIControl.State.normal)
            self.esb.setTitle("🇪🇸 Español", for: UIControl.State.normal)
            self.linguatitulo.text = "Seleccione su idioma preferido:"

        } else {
            title = "Configure alerts"
            self.linguatitulo.text = "Select your preferred language:"
            self.titulo.text = "Select below which neighborhoods you want to receive alerts."
            self.prev.setTitle("Save", for: UIControl.State.normal)
            self.enb.setTitle("🇺🇸 English", for: UIControl.State.normal)
            self.ptb.setTitle("🇧🇷 Portuguese", for: UIControl.State.normal)
            self.esb.setTitle("🇪🇸 Spanish", for: UIControl.State.normal)

        }
    }
    
    @IBAction func pt_ac(_ sender: Any) {
        
        if ((UserDefaults.standard.string(forKey: "lingua_usu")) != nil) {
            lingua = UserDefaults.standard.string(forKey: "lingua_usu")!
        } else {
            lingua = UserDefaults.standard.stringArray(forKey: "AppleLanguages")![0]
        }
        
        
        if lingua.contains("pt") {
            title = "Configurar alertas"
           
        } else if lingua.contains("es") {
            title = "Configurar alertas"
            self.titulo.text = "Seleccione los vecindarios de los cuales desea recibir alertas."
            self.prev.setTitle("Guardar", for: UIControl.State.normal)
            self.enb.setTitle("🇺🇸 Inglés", for: UIControl.State.normal)
            self.ptb.setTitle("🇧🇷 Portugués", for: UIControl.State.normal)
            self.esb.setTitle("🇪🇸 Español", for: UIControl.State.normal)
            self.linguatitulo.text = "Seleccione su idioma preferido:"

        } else {
            title = "Configure alerts"
            self.linguatitulo.text = "Select your preferred language:"
            self.titulo.text = "Select below which neighborhoods you want to receive alerts."
            self.prev.setTitle("Save", for: UIControl.State.normal)
            self.enb.setTitle("🇺🇸 English", for: UIControl.State.normal)
            self.ptb.setTitle("🇧🇷 Portuguese", for: UIControl.State.normal)
            self.esb.setTitle("🇪🇸 Spanish", for: UIControl.State.normal)

        }
        
        UserDefaults.standard.set("pt", forKey: "lingua_usu")
        
        if ((UserDefaults.standard.string(forKey: "lingua_usu")) != nil) {
            lingua = UserDefaults.standard.string(forKey: "lingua_usu")!
        } else {
            lingua = UserDefaults.standard.stringArray(forKey: "AppleLanguages")![0]
        }
        
        
        if lingua.contains("pt") {
            title = "Configurar alertas"
           
        } else if lingua.contains("es") {
            title = "Configurar alertas"
            self.titulo.text = "Seleccione los vecindarios de los cuales desea recibir alertas."
            self.prev.setTitle("Guardar", for: UIControl.State.normal)
            self.enb.setTitle("🇺🇸 Inglés", for: UIControl.State.normal)
            self.ptb.setTitle("🇧🇷 Portugués", for: UIControl.State.normal)
            self.esb.setTitle("🇪🇸 Español", for: UIControl.State.normal)
            self.linguatitulo.text = "Seleccione su idioma preferido:"

        } else {
            title = "Configure alerts"
            self.linguatitulo.text = "Select your preferred language:"
            self.titulo.text = "Select below which neighborhoods you want to receive alerts."
            self.prev.setTitle("Save", for: UIControl.State.normal)
            self.enb.setTitle("🇺🇸 English", for: UIControl.State.normal)
            self.ptb.setTitle("🇧🇷 Portuguese", for: UIControl.State.normal)
            self.esb.setTitle("🇪🇸 Spanish", for: UIControl.State.normal)

        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.section == SectionVegetables else { return false }
        return true
    }
    
    enum LoadError: Error {
        case fetchFailed, decodeFailed
    }
    
    func fetchQuotes(id_us: String) async {
        let downloadTask = Task { () -> String in
            let url = URL(string: "https://aplicativo.cocr.com.br/bairros/"+id_us)!
            let data: Data

            do {
                (data, _) = try await URLSession.shared.data(from: url)
            } catch {
                throw LoadError.fetchFailed
            }

            if let string = String(data: data, encoding: .utf8) {
                return string
            } else {
                throw LoadError.decodeFailed
            }
        }

        let result = await downloadTask.result

        do {
            let string = try result.get()
            print(string)
        } catch LoadError.fetchFailed {
            print("Unable to fetch the quotes.")
        } catch LoadError.decodeFailed {
            print("Unable to convert quotes to text.")
        } catch {
            print("Unknown error.")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if ((UserDefaults.standard.string(forKey: "lingua_usu")) != nil) {
            lingua = UserDefaults.standard.string(forKey: "lingua_usu")!
        } else {
            lingua = UserDefaults.standard.stringArray(forKey: "AppleLanguages")![0]
        }
        
        
        if lingua.contains("pt") {
            title = "Configurar alertas"
           
        } else if lingua.contains("es") {
            title = "Configurar alertas"
            self.titulo.text = "Seleccione los vecindarios de los cuales desea recibir alertas."
            self.prev.setTitle("Guardar", for: UIControl.State.normal)
            self.enb.setTitle("🇺🇸 Inglés", for: UIControl.State.normal)
            self.ptb.setTitle("🇧🇷 Portugués", for: UIControl.State.normal)
            self.esb.setTitle("🇪🇸 Español", for: UIControl.State.normal)
            self.linguatitulo.text = "Seleccione su idioma preferido:"

        } else {
            title = "Configure alerts"
            self.linguatitulo.text = "Select your preferred language:"
            self.titulo.text = "Select below which neighborhoods you want to receive alerts."
            self.prev.setTitle("Save", for: UIControl.State.normal)
            self.enb.setTitle("🇺🇸 English", for: UIControl.State.normal)
            self.ptb.setTitle("🇧🇷 Portuguese", for: UIControl.State.normal)
            self.esb.setTitle("🇪🇸 Spanish", for: UIControl.State.normal)

        }
        
        dispatchQueue.async {
            OperationQueue.main.addOperation() {
                
                if Messaging.messaging().fcmToken != nil {
                    
                    self.fav = Bairro.getEsta(id_us: Messaging.messaging().fcmToken!)
                    var x = 0
                    while x != self.fav.count {
                        print(self.fav[x].nome)
                        
                        self.meus_bairros.append(self.fav[x].nome)
                      
                        x += 1
                    }
                }
                
                self.filteredData = self.vegetables
                self.table.reloadData()
                
                
                
                self.prev.applyGradient(colours: [UIColor(red: 0.16, green: 0.41, blue: 0.56, alpha: 1.00), UIColor(red: 0.26, green: 0.73, blue: 0.92, alpha: 1.00)], radius: 12, sentido: "Horizontal")
                
                self.esb.applyGradient(colours: [UIColor(red: 0.16, green: 0.41, blue: 0.56, alpha: 1.00), UIColor(red: 0.26, green: 0.73, blue: 0.92, alpha: 1.00)], radius: 12, sentido: "Horizontal")
                
                self.ptb.applyGradient(colours: [UIColor(red: 0.16, green: 0.41, blue: 0.56, alpha: 1.00), UIColor(red: 0.26, green: 0.73, blue: 0.92, alpha: 1.00)], radius: 12, sentido: "Horizontal")
                
                self.enb.applyGradient(colours: [UIColor(red: 0.16, green: 0.41, blue: 0.56, alpha: 1.00), UIColor(red: 0.26, green: 0.73, blue: 0.92, alpha: 1.00)], radius: 12, sentido: "Horizontal")
                
                
            }
        }
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


