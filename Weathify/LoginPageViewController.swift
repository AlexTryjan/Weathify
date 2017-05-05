//
//  ViewController.swift
//  Weathify
//
//  Created by Alexander Tryjankowski on 5/4/17.
//  Copyright © 2017 Alexander Tryjankowski. All rights reserved.
//

import UIKit
import Alamofire
import CoreLocation

class LoginPageViewController: UIViewController, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate, CLLocationManagerDelegate {
    
    // Variables
    var auth = SPTAuth.defaultInstance()!
    var session:SPTSession!
    var isLogin = true //Tells app if the user has logged in
    var weather : String? //Search term from weather API
    var locManager = CLLocationManager()
    var latitude = 41.4993
    var longitude = -81.6944
    var problemCharacters : [Character] = ["O"]
    var player: SPTAudioStreamingController?
    var loginUrl : URL?
    
    //URI for song
    var songURI : String?
    
    //Outlets
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet var displayLabels: [UILabel]!
    @IBOutlet weak var weatherTypeLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var albumCoverImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setup()
        
        locManager.requestWhenInUseAuthorization()
        
        NotificationCenter.default.addObserver(self, selector: #selector(LoginPageViewController.updateAfterFirstLogin), name: NSNotification.Name(rawValue: "loginSuccessfull"), object: nil)
        
        updateWeather()
    }
    
    func setup () {
        auth.redirectURL = URL(string: redirectURL)
        auth.clientID = clientID
        auth.requestedScopes = [SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope, SPTAuthPlaylistModifyPublicScope, SPTAuthPlaylistModifyPrivateScope]
        loginUrl = auth.spotifyWebAuthenticationURL()
    }
    
    func isProblemCharacter(char:Character) -> Bool {
        for i in 0..<problemCharacters.count {
            if problemCharacters[i] == char {
                return true
            }
        }
        return false
    }
    
    func initializePlayer(authSession:SPTSession){
        if self.player == nil {
            self.player = SPTAudioStreamingController.sharedInstance()
            self.player!.playbackDelegate = self
            self.player!.delegate = self
            try! player?.start(withClientId: auth.clientID)
            self.player!.login(withAccessToken: authSession.accessToken)
        } else {
            self.player?.playSpotifyURI(songURI, startingWith: 0, startingWithPosition: 0, callback: { (error) in
                if (error != nil) {
                    print("playing!")
                }
            })
        }
    }
    
    func updateAfterFirstLogin () {
        let userDefaults = UserDefaults.standard
        if let sessionObj:AnyObject = userDefaults.object(forKey: "SpotifySession") as AnyObject? {
            let sessionDataObj = sessionObj as! Data
            if NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) is NSNull {
                //login error or cancel
                if(!isLogin) {
                    toggleView()
                }
                return;
            }
        }
        if(isLogin) {
            toggleView()
        }
        updatePosition()
    }
    
    func toggleView() {
        loginButton.isHidden = isLogin
        playButton.isHidden = !isLogin
        songNameLabel.isHidden = !isLogin
        weatherTypeLabel.isHidden = !isLogin
        artistNameLabel.isHidden = !isLogin
        albumCoverImage.isHidden = !isLogin
        for i in 0..<displayLabels.count {
            displayLabels[i].isHidden = !isLogin
        }
        isLogin = !isLogin
    }
    
    func playCurrentURI() {
        let userDefaults = UserDefaults.standard
        
        if let sessionObj:AnyObject = userDefaults.object(forKey: "SpotifySession") as AnyObject? {
            let sessionDataObj = sessionObj as! Data
            let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            self.session = firstTimeSession
            initializePlayer(authSession: session)
            //self.loginButton.isHidden = true
        }
    }
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        print("logged in")
        self.player?.playSpotifyURI(songURI, startingWith: 0, startingWithPosition: 0, callback: { (error) in
            if (error != nil) {
                print("playing!")
            }
        })
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {}
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
    
    func updatePosition() {
        var currentLocation : CLLocation?
        if(CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse){
            locManager.delegate = self
            locManager.requestLocation()
            currentLocation = locManager.location
            latitude = (currentLocation?.coordinate.latitude)!
            longitude = (currentLocation?.coordinate.longitude)!
        }
    }
    
    //API query code
    func updateWeather() {
        let urlComponents = NSURLComponents()
        urlComponents.scheme = "https";
        urlComponents.host = "api.weatherbit.io";
        urlComponents.path = "/v1.0/current";
        
        updatePosition()
        
        // add params
        let latitudeQuery = URLQueryItem(name: "lat", value: String(latitude))
        let longitudeQuery = URLQueryItem(name: "lon", value: String(longitude))
        let apiKeyQuery = URLQueryItem(name: "key", value: apikey)
        urlComponents.queryItems = [latitudeQuery, longitudeQuery, apiKeyQuery]
        let fullUrl : String? = urlComponents.url?.absoluteString
        callAlamoWeather(url: fullUrl!)
        print(fullUrl!)
    }
    
    func updateURI() {
        let urlComponents = NSURLComponents()
        urlComponents.scheme = "https";
        urlComponents.host = "api.spotify.com";
        urlComponents.path = "/v1/search";
        
        // add params
        let qQuery = URLQueryItem(name: "q", value: weather!)
        let typeQuery = URLQueryItem(name: "type", value: "track")
        let limitQuery = URLQueryItem(name: "limit", value: "50")
        urlComponents.queryItems = [qQuery, typeQuery, limitQuery]
        let fullUrl : String? = urlComponents.url?.absoluteString
        print(fullUrl!)
        callAlamo(url: fullUrl!)
    }
    
    //JSON Parsing code
    func parseSpotifyJSON(JSONData: Data) {
        do {
            var readableJSON = try JSONSerialization.jsonObject(with: JSONData, options: .mutableContainers) as! [String:AnyObject]
            if let tracks = readableJSON["tracks"] as? [String:AnyObject] {
                if let items = tracks["items"] as? NSArray {
                    let randomNum : UInt32 = arc4random_uniform(UInt32(items.count))
                    let item = items[Int(randomNum)] as! [String:AnyObject]
                    let name = item["name"] as! String?
                    var artistName : String?
                    if let artists = item["artists"] as? NSArray {
                        let artistInfo = artists[0] as! [String:AnyObject]
                        artistName = artistInfo["name"] as! String?
                        self.artistNameLabel.text = artistName
                    }
                    if let albumInfo = item["album"] as? [String:AnyObject] {
                        let albumName = albumInfo["name"] as! String?
                        if let albumArts = albumInfo["images"] as? NSArray {
                            let albumCoverInfo = albumArts[0] as! [String:AnyObject]
                            let albumCoverUrl = URL(string: albumCoverInfo["url"] as! String)
                            let albumCoverData = NSData(contentsOf: albumCoverUrl!)
                            let albumCoverImage = UIImage(data: albumCoverData as! Data)
                            self.albumCoverImage.image = albumCoverImage
                            songHistory.insert(Song.init(title: name, artist: artistName, albumName: albumName, albumArt: albumCoverImage),at: 0)
                        }
                    }
                    self.songNameLabel.text = name
                    songURI = item["uri"] as! String?
                    
                }
            }
        } catch {
            print(error)
        }
    }
    
    func parseWeatherJSON(JSONData: Data) {
        do {
            var readableJSON = try JSONSerialization.jsonObject(with: JSONData, options: .mutableContainers) as! [String:AnyObject]
            if let data = readableJSON["data"] as? NSArray {
                if let instance = data[0] as? [String:AnyObject] {
                    let weather = instance["weather"] as? [String:AnyObject]
                    let description = weather?["description"] as! String?
                    self.weatherTypeLabel.text = description
                    self.weather = description
                }
            }

            if let weather = readableJSON["weather"] as? [String:AnyObject] {
                let mainDescription = weather["description"] as! String?
                weatherTypeLabel.text = mainDescription
            }
        } catch {
            print(error)
        }
        //Sometimes, weather description is too complex for Spotify -> so we remove problem words
        if isProblemCharacter(char: weather![weather!.startIndex]) {
            let components = weather!.components(separatedBy: " ")
            if components.count > 0 {
                weather! = components[1]
                weather! = weather!.capitalized
                weatherTypeLabel.text = weather
            }
        }
    }
    
    //Alamofire
    func callAlamo(url:String) {
        Alamofire.request(url).responseJSON(completionHandler: {
            response in
            self.parseSpotifyJSON(JSONData: response.data!)
        })
    }
    
    func callAlamoWeather(url:String) {
        print(url)
        Alamofire.request(url).responseJSON(completionHandler: {
            response in
            self.parseWeatherJSON(JSONData: response.data!)
        })
    }
    
    @IBAction func play(_ sender: UIButton) {
        updateURI()
        let when = DispatchTime.now() + 0.025
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.playCurrentURI()
        }
    }
    
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        UIApplication.shared.open(loginUrl!, options: [:], completionHandler: nil)
    }
    
    
    
}
