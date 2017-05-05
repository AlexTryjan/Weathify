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

class LoginPageViewController: UIViewController, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate {
    
    //Constants
    let frontSpotifyUrl = "https://api.spotify.com/v1/search?q="
    let backSpotifyUrl = "&type=track&limit=50"
    let frontWeatherUrl = "https://api.weatherbit.io/v1.0/current?lat="
    let backWeatherUrl = "&APPID=" + apikey
    
    // Variables
    var auth = SPTAuth.defaultInstance()!
    var session:SPTSession!
    var isLogin = true
    var weather : String?
    var locManager = CLLocationManager()
    
    // Initialzed in either updateAfterFirstLogin: (if first time login) or in viewDidLoad (when there is a check for a session object in User Defaults
    var player: SPTAudioStreamingController?
    var loginUrl: URL?
    
    //Search Term From WeatherAPI
    var searchTerm : String?
    
    //URI for song
    var songURI : String?
    
    //Outlets
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet var displayLabels: [UILabel]!
    @IBOutlet weak var weatherTypeLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setup()
        
        locManager.requestWhenInUseAuthorization()
        
        //move this to main page button Action
        NotificationCenter.default.addObserver(self, selector: #selector(LoginPageViewController.updateAfterFirstLogin), name: NSNotification.Name(rawValue: "loginSuccessfull"), object: nil)
        
        updateWeather()
    }
    
    func setup () {
        // insert redirect your url and client ID below
        auth.redirectURL = URL(string: redirectURL)
        auth.clientID = clientID
        auth.requestedScopes = [SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope, SPTAuthPlaylistModifyPublicScope, SPTAuthPlaylistModifyPrivateScope]
        loginUrl = auth.spotifyWebAuthenticationURL()
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
    }
    
    func toggleView() {
        loginButton.isHidden = isLogin
        playButton.isHidden = !isLogin
        songNameLabel.isHidden = !isLogin
        weatherTypeLabel.isHidden = !isLogin
        artistNameLabel.isHidden = !isLogin
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
    
    func updateWeather() {
        let urlComponents = NSURLComponents()
        urlComponents.scheme = "https";
        urlComponents.host = "api.weatherbit.io";
        urlComponents.path = "/v1.0/current";
        
        // add params
        let latitudeQuery = URLQueryItem(name: "lat", value: "123")
        let longitudeQuery = URLQueryItem(name: "lon", value: "123")
        let apiKeyQuery = URLQueryItem(name: "key", value: apikey)
        urlComponents.queryItems = [latitudeQuery, longitudeQuery, apiKeyQuery]
        //let fullUrl = "https://api.weatherbit.io/v1.0/current?lat=123&lon=123&key=cfeba487bc374cda9061ef0cb44e2e44"
        let fullUrl : String? = urlComponents.url?.absoluteString
        callAlamoWeather(url: fullUrl!)
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
    
    func parseSpotifyJSON(JSONData: Data) {
        do {
            var readableJSON = try JSONSerialization.jsonObject(with: JSONData, options: .mutableContainers) as! [String:AnyObject]
            if let tracks = readableJSON["tracks"] as? [String:AnyObject] {
                if let items = tracks["items"] as? NSArray {
                    let randomNum : UInt32 = arc4random_uniform(UInt32(items.count))
                    let item = items[Int(randomNum)] as! [String:AnyObject]
                    let name = item["name"]
                    self.songNameLabel.text = name as! String?
                    songURI = item["uri"] as! String?
                }
            }
            //print(readableJSON)
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
            //print(readableJSON)
        } catch {
            print(error)
        }
    }
    
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
