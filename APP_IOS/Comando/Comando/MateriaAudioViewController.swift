//
//  MateriaViewController.swift
//  ClipRJ
//
//  Created by Candido Bugarin on 28/09/19.
//  Copyright © 2019 Candido Bugarin. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import AVFoundation
class MateriaAudioViewController: UIViewController, MKMapViewDelegate,AVAudioPlayerDelegate {

    @IBOutlet weak var fonte: UILabel!
    @IBOutlet weak var temalabel: UILabel!
    @IBOutlet weak var imagem: UIImageView!
    @IBOutlet weak var view_fora: UIView!
    @IBOutlet weak var texto: UITextView!
    @IBOutlet weak var titulolabel: UILabel!
    
    
    @IBOutlet weak var mapView: MKMapView!
    
    var player:AVPlayer?
    var playerItem:AVPlayerItem?
    
    fileprivate let seekDuration: Float64 = 10
    @IBOutlet weak var playbackSlider: UISlider!
    @IBOutlet weak var ButtonPlay: UIButton!
    
    
    var texto_input = ""
    var fonte_t = ""
    var data = ""
    var titulo = ""
    var poli = ""
    var url = ""
    var points = [CLLocationCoordinate2D]()

    var lingua = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        if #available(iOS 15, *) {
            
            let logoContainer = UIView(frame: CGRect(x: 0, y: 0, width: 270, height: 30))
            
            let myimage = UIImage(named: "logo_cor.png")?.withRenderingMode(.alwaysOriginal)

            let attributes = [NSAttributedString.Key.font: UIFont(name: "Raleway-Bold", size: 18)!, NSAttributedString.Key.foregroundColor: UIColor.white]

            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
           
            if self.traitCollection.userInterfaceStyle == .dark {
                appearance.backgroundColor = UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1.00)
            } else {
                appearance.backgroundColor = UIColor(red: 0.30, green: 0.50, blue: 0.73, alpha: 1.00)
            }
            
            
            appearance.shadowColor = .none
            appearance.titleTextAttributes = attributes
            
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationItem.titleView = logoContainer
            
            navigationController?.navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance
            
            let rightBarButton = UIBarButtonItem(image: myimage, style: UIBarButtonItem.Style.plain, target: self, action: "")
            self.navigationItem.rightBarButtonItem = rightBarButton
            
            
        }
        
        self.titulolabel.text = titulo
        title = fonte_t
        
        self.texto.text = texto_input.replacingOccurrences(of: "pulalinha", with: "\n").replacingOccurrences(of: "pontovirgula", with: ";")

        view_fora.layer.cornerRadius = 5
        view_fora.layer.masksToBounds = false
        
        view_fora.layer.shadowColor = UIColor.gray.cgColor
        view_fora.layer.shadowOpacity = 0.5
        view_fora.layer.shadowOffset = CGSize.zero
        view_fora.layer.shadowRadius = 3
        
        let defaults = UserDefaults.standard
         
        let array = defaults.object(forKey:"SavedArray") as? [String] ?? [String]()
        
         self.texto.isSelectable = true
         self.texto.dataDetectorTypes = .link
        
        mapView.delegate = self as! MKMapViewDelegate
        mapView.layer.cornerRadius = 5


        let latitude:CLLocationDegrees = -22.9241421//insert latitutde
        let longitude:CLLocationDegrees = -43.4405087 //insert longitud
        let location = CLLocationCoordinate2DMake(latitude, longitude)
        
        let viewRegion = MKCoordinateRegion(center: location, latitudinalMeters: 45000, longitudinalMeters: 45000)
        
        mapView.setRegion(viewRegion, animated: false)
        
        if poli.count != 0 {
        let myStrings = poli.components(separatedBy: "],")
        let characters = Array(myStrings)
        var x = 0
        while x != (characters.count) {
            let lat = Double(characters[x].split(separator: ",")[1].replacingOccurrences(of: "[",with: "").replacingOccurrences(of: "]",with: "").replacingOccurrences(of: " ",with: "")) ?? 0.0
            let lon = Double(characters[x].split(separator: ",")[0].replacingOccurrences(of: "[",with: "").replacingOccurrences(of: "]",with: "").replacingOccurrences(of: " ",with: "")) ?? 0.0
            points.append(CLLocationCoordinate2DMake(lat, lon))
            
            let point = StoreAnnotation(coordinate:  CLLocationCoordinate2D(latitude: lat , longitude: lon))
            self.mapView.addAnnotation(point)
            
            x += 1
            }
        }
        
        let polygon = MKPolyline(coordinates: points, count: points.count)
        print(polygon)
        mapView.addOverlay(polygon)
        
        
        let playerItem:AVPlayerItem = AVPlayerItem(url: URL(string: url)!)
        player = AVPlayer(playerItem: playerItem)
        
        playbackSlider.minimumValue = 0
        
        let duration : CMTime = playerItem.asset.duration
        let seconds : Float64 = CMTimeGetSeconds(duration)
        
        let currentDuration : CMTime = playerItem.currentTime()
        let currentSeconds : Float64 = CMTimeGetSeconds(currentDuration)
        
        playbackSlider.maximumValue = Float(seconds)
        playbackSlider.isContinuous = true
        
        player!.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: DispatchQueue.main) { (CMTime) -> Void in
        if self.player!.currentItem?.status == .readyToPlay {
        let time : Float64 = CMTimeGetSeconds(self.player!.currentTime());
        self.playbackSlider.value = Float ( time );
        }
        let playbackLikelyToKeepUp = self.player?.currentItem?.isPlaybackLikelyToKeepUp
        if playbackLikelyToKeepUp == false{
        self.ButtonPlay.isHidden = true
        } else {
        //stop the activity indicator
        self.ButtonPlay.isHidden = false
        }
        }
        
        playbackSlider.addTarget(self, action: #selector(playbackSliderValueChanged(_:)), for: .valueChanged)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.finishedPlaying(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        


        
        // Do any additional setup after loading the view.
    }

    

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
       if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.fillColor = UIColor.black.withAlphaComponent(0.9)
              renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 2.5
              return renderer
        }
        
        return MKOverlayRenderer()
    }
    
    
    @IBAction func share_act(_ sender: UIButton) {
    
    let myWebsite = NSURL(string:"https://apps.apple.com/br/app/cor-rio/id1478320199")
    let shareAll = [myWebsite]
    let activityViewController = UIActivityViewController(activityItems: shareAll, applicationActivities: nil)
    activityViewController.popoverPresentationController?.sourceView = self.view
    self.present(activityViewController, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the navigation bar on the this view controller
        self.tabBarController?.tabBar.isHidden = true
        self.tabBarController?.navigationItem.hidesBackButton = false
        self.navigationController?.navigationBar.isHidden = false
        
        if player != nil {
            player?.pause()
        }
        

        // Show the navigation bar on other view controllers
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Show the navigation bar on other view controllers
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.navigationBar.isHidden = false
        if player != nil {
            player?.pause()
        }
        
    }
    
    @IBAction func seekBackWards(_ sender: Any) {
        if player == nil {
            return
        }
        let playerCurrenTime = CMTimeGetSeconds(player!.currentTime())
        var newTime = playerCurrenTime - seekDuration
    if newTime < 0 {
        newTime = 0
    }
    player?.pause()
    let selectedTime: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
    player?.seek(to: selectedTime)
    player?.play()
    }
    
    @IBAction func seekForward(_ sender: Any) {
    if player == nil { return }
    if let duration = player!.currentItem?.duration {
       let playerCurrentTime = CMTimeGetSeconds(player!.currentTime())
       let newTime = playerCurrentTime + seekDuration
       if newTime < CMTimeGetSeconds(duration)
       {
          let selectedTime: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
          player!.seek(to: selectedTime)
       }
       player?.pause()
       player?.play()
      }
    }
    
    @IBAction func playButton(_ sender: Any) {
    if player?.rate == 0
    {
    player!.play()
    self.ButtonPlay.isHidden = true
    ButtonPlay.setImage(UIImage(systemName: "pause.fill"), for: .normal)
    } else {
    player!.pause()
        self.ButtonPlay.isHidden = false
    ButtonPlay.setImage(UIImage(systemName: "play.fill"), for: .normal)
    }
    }
    
    func stringFromTimeInterval(interval: TimeInterval) -> String {
    let interval = Int(interval)
    let seconds = interval % 60
    let minutes = (interval / 60) % 60
    let hours = (interval / 3600)
        return "ta indo"
    }
    
    @objc func playbackSliderValueChanged(_ playbackSlider:UISlider) {
    let seconds : Int64 = Int64(playbackSlider.value)
    let targetTime:CMTime = CMTimeMake(value: seconds, timescale: 1)
    player!.seek(to: targetTime)
    if player!.rate == 0 {
    player?.play()
     }
    }
    
    @objc func finishedPlaying( _ myNotification:NSNotification) {
    ButtonPlay.setImage(UIImage(named: "ic_play"), for: UIControl.State.normal)
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
