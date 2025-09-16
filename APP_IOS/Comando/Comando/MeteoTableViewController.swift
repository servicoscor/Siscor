//
//  MeteoTableViewController.swift
//  Comando
//
//  Created by Candido Bugarin on 31/01/19.
//  Copyright © 2019 Candido Bugarin. All rights reserved.
//

import UIKit

class MeteoTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var mapa_but: UIButton!
    
    var fav3: Array<EstacaoMete> = []
    var nome: Array<String> = []
    var temperatura: Array<Double> = []
    var umidade: Array<Double> = []
    var fonte: Array<String> = []
    var vel: Array<Double> = []
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
    
    var lingua = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
      
        
        self.table.layer.cornerRadius = 10
        
        self.table.layer.shadowOpacity = 0.3
        self.table.layer.shadowOffset = CGSize.zero
        self.table.layer.shadowRadius = 5
        
        let xib = UINib(nibName: "CellAvisos", bundle: nil)
        self.table.register(xib,forCellReuseIdentifier:"cell")
        self.table.dataSource = self
        self.table.delegate = self
        table.contentInset = UIEdgeInsets.zero
        self.automaticallyAdjustsScrollViewInsets = false
        
       
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.nome.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.table.dequeueReusableCell(withIdentifier: "cell")! as! CellAvisos
        
        if lingua.contains("pt") {
            cell.cellNome.text = nome[indexPath.row]
            cell.cellDesc.text = "Temperatura: "+String(format: "%.0f",temperatura[indexPath.row])+" ºC"
           
        } else if lingua.contains("es") {
            cell.cellNome.text = nome[indexPath.row]
            cell.cellDesc.text = "Temperatura: "+String(format: "%.0f",temperatura[indexPath.row])+" ºC"

        } else {
            cell.cellNome.text = nome[indexPath.row]
            cell.cellDesc.text = "Temperature: "+String(format: "%.0f",temperatura[indexPath.row])+" ºC"

        }
        
       
        return cell
    }
    
    func tableView(_ didSelectRowAttableView:UITableView, didSelectRowAt indexPath: IndexPath) {
        var st = ""
        var linha = indexPath.row
        
        if lingua.contains("pt") {
            if vel[indexPath.row] < 999 && temperatura[indexPath.row] < 999 && vel[indexPath.row] != 0 {
                let pc1 = (10*(vel[indexPath.row]).squareRoot())+(10.45 - (vel[indexPath.row]))
                let pc2 = (((temperatura[indexPath.row])-33)/22)
                let fonte_v = fonte[indexPath.row]
                st = String(format: "%.0f",33+(pc1*pc2))
                var vento = ""
                if vel[indexPath.row] > 0 && vel[indexPath.row] <= 0.3 {
                    vento = "Calmaria"
                } else if vel[indexPath.row] > 0.3 && vel[indexPath.row] <= 7 {
                    vento = "Brisa (vento fraco)"
                } else if vel[indexPath.row] > 7 && vel[indexPath.row] <= 13.8 {
                    vento = "Moderado"
                } else if vel[indexPath.row] > 13.9 && vel[indexPath.row] <= 24.4 {
                    vento = "Forte"
                } else if vel[indexPath.row] > 24.4 {
                    vento = "Muito Forte"
                } else {
                    vento = "Sem info."
                }
                
                var texto_p = "Temperatura: "+String(format: "%.0f",temperatura[linha])+" ºC\nUmidade: "+String(format: "%.0f",umidade[linha])+" %\nSensação térmica: "+st+" ºC\nVento: "+vento+"\n"
                
                texto_p = texto_p+"Fonte: "+fonte_v+"\n"
                
                let alert = UIAlertController(title: nome[indexPath.row], message: texto_p, preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                 self.present(alert, animated: true, completion: nil)
            } else {
                st = "Sem info"
                let vento = "Sem Info"
                let alert = UIAlertController(title: nome[indexPath.row], message: "Temperatura: "+String(format: "%.0f",temperatura[indexPath.row])+" ºC\nUmidade: "+String(format: "%.0f",umidade[indexPath.row])+" %\nSensação térmica: "+st+" \nVento: "+vento+"\nFonte: "+fonte[indexPath.row]+"\n", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                table.deselectRow(at: indexPath, animated: true)
            }
        } else if lingua.contains("es") {
            if vel[indexPath.row] < 999 && temperatura[indexPath.row] < 999 && vel[indexPath.row] != 0 {
                let pc1 = (10*(vel[indexPath.row]).squareRoot())+(10.45 - (vel[indexPath.row]))
                let pc2 = (((temperatura[indexPath.row])-33)/22)
                let fonte_v = fonte[indexPath.row]
                st = String(format: "%.0f",33+(pc1*pc2))
                var vento = ""
                if vel[indexPath.row] > 0 && vel[indexPath.row] <= 0.3 {
                    vento = "Sin viento"
                } else if vel[indexPath.row] > 0.3 && vel[indexPath.row] <= 7 {
                    vento = "suave"
                } else if vel[indexPath.row] > 7 && vel[indexPath.row] <= 13.8 {
                    vento = "Moderado"
                } else if vel[indexPath.row] > 13.9 && vel[indexPath.row] <= 24.4 {
                    vento = "fuerte"
                } else if vel[indexPath.row] > 24.4 {
                    vento = "muy fuerte"
                } else {
                    vento = "Sin información"
                }
                
                var texto_p = "Temperatura: "+String(format: "%.0f",temperatura[linha])+" ºC\nHumedad del aire: "+String(format: "%.0f",umidade[linha])+" %\nSensación térmica: "+st+" ºC\nViento: "+vento+"\n"
                
                texto_p = texto_p+"Origen: "+fonte_v+"\n"
                
                let alert = UIAlertController(title: nome[indexPath.row], message: texto_p, preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                 self.present(alert, animated: true, completion: nil)
            } else {
                st = "Sin información"
                let vento = "Sin información"
                let alert = UIAlertController(title: nome[indexPath.row], message: "Temperatura: "+String(format: "%.0f",temperatura[indexPath.row])+" ºC\nHumedad del aire: "+String(format: "%.0f",umidade[indexPath.row])+" %\nSensación térmica: "+st+" \nViento: "+vento+"\nOrigen: "+fonte[indexPath.row]+"\n", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                table.deselectRow(at: indexPath, animated: true)
            }
        } else {
            if vel[indexPath.row] < 999 && temperatura[indexPath.row] < 999 && vel[indexPath.row] != 0 {
                let pc1 = (10*(vel[indexPath.row]).squareRoot())+(10.45 - (vel[indexPath.row]))
                let pc2 = (((temperatura[indexPath.row])-33)/22)
                let fonte_v = fonte[indexPath.row]
                st = String(format: "%.0f",33+(pc1*pc2))
                var vento = ""
                if vel[indexPath.row] > 0 && vel[indexPath.row] <= 0.3 {
                    vento = "No wind"
                } else if vel[indexPath.row] > 0.3 && vel[indexPath.row] <= 7 {
                    vento = "breeze"
                } else if vel[indexPath.row] > 7 && vel[indexPath.row] <= 13.8 {
                    vento = "Moderate"
                } else if vel[indexPath.row] > 13.9 && vel[indexPath.row] <= 24.4 {
                    vento = "Strong"
                } else if vel[indexPath.row] > 24.4 {
                    vento = "Very strong"
                } else {
                    vento = "no information"
                }
                
                var texto_p = "Temperature: "+String(format: "%.0f",temperatura[linha])+" ºC\nAir humidity: "+String(format: "%.0f",umidade[linha])+" %\nThermal sensation: "+st+" ºC\nWind: "+vento+"\n"
                
                texto_p = texto_p+"Source: "+fonte_v+"\n"
                
                let alert = UIAlertController(title: nome[indexPath.row], message: texto_p, preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                 self.present(alert, animated: true, completion: nil)
            } else {
                st = "no information"
                let vento = "no information"
                let alert = UIAlertController(title: nome[indexPath.row], message: "Temperature: "+String(format: "%.0f",temperatura[indexPath.row])+" ºC\nAir humidity: "+String(format: "%.0f",umidade[indexPath.row])+" %\nThermal sensation: "+st+" \nWind: "+vento+"\nSource: "+fonte[indexPath.row]+"\n", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                table.deselectRow(at: indexPath, animated: true)
            }
        }
        
        
        
       
       
    }
    
    @IBAction func mapa_act(_ sender: UIButton) {
        let vc = MapaTemperaturaViewController(nibName:"MapaTemperaturaViewController", bundle:nil)
        self.navigationController!.pushViewController(vc, animated: true)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the navigation bar on the this view controller
        
        if ((UserDefaults.standard.string(forKey: "lingua_usu")) != nil) {
            lingua = UserDefaults.standard.string(forKey: "lingua_usu")!
        } else {
            lingua = UserDefaults.standard.stringArray(forKey: "AppleLanguages")![0]
        }
        

        if lingua.contains("pt") {
            self.title = "Temperaturas"
           
        } else if lingua.contains("es") {
            self.title = "estaciones meteorológicas"

        } else {
            self.title = "weather stations"

        }
        
        
        if lingua.contains("pt") {
            let text = "Carregando"
            self.showWaitOverlayWithText(text)
        } else if lingua.contains("es") {
            let text = "Cargando"
            self.showWaitOverlayWithText(text)
        } else {
            let text = "Loading"
            self.showWaitOverlayWithText(text)
        }
        
        dispatchQueue.async {
            OperationQueue.main.addOperation() {
                
                
                self.fav3 = EstacaoMet.getEsta()
                
                var x = 0
                while x != self.fav3.count {
                    if Double(self.fav3[x].tem_med) < 60 {
                        self.nome.append(self.fav3[x].nome.replacingOccurrences(of: "Rio de Janeiro - ", with: "").replacingOccurrences(of: "-A602", with: "").replacingOccurrences(of: "-A621", with: "").replacingOccurrences(of: "-A652", with: ""))
                        self.temperatura.append(Double(self.fav3[x].tem_med))
                        self.umidade.append(Double(self.fav3[x].umd_med))
                        self.vel.append(Double(self.fav3[x].vel_med))
                        self.fonte.append((self.fav3[x].fonte))
                    }
                    x += 1
                }
                
                self.table.reloadData()
                
                self.removeAllOverlays()
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
