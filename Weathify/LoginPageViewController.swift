//
//  ViewController.swift
//  Weathify
//
//  Created by Alexander Tryjankowski on 5/4/17.
//  Copyright © 2017 Alexander Tryjankowski. All rights reserved.
//

import UIKit
import SafariServices
import AVFoundation

class LoginPageViewController: UIViewController, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate {
    
    // Variables
    var auth = SPTAuth.defaultInstance()!
    var session:SPTSession!
    
    // Initialzed in either updateAfterFirstLogin: (if first time login) or in viewDidLoad (when there is a check for a session object in User Defaults
    var player: SPTAudioStreamingController?
    var loginUrl: URL?
    
    //Search Term From WeatherAPI
    var searchTerm : String?
    
    //URI for song
    var songURI : String?
    let testURI = "spotify:track:58s6EuEYJdlb0kO7awm3Vp"
    
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
        
        //move this to main page button Action
        NotificationCenter.default.addObserver(self, selector: #selector(LoginPageViewController.updateAfterFirstLogin), name: NSNotification.Name(rawValue: "loginSuccessfull"), object: nil)
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
            self.player?.playSpotifyURI(testURI, startingWith: 0, startingWithPosition: 0, callback: { (error) in
                if (error != nil) {
                    print("playing!")
                }
            })
        }
    }
    
    func updateAfterFirstLogin () {
        
        loginButton.isHidden = true
        playButton.isHidden = false
        songNameLabel.isHidden = false
        weatherTypeLabel.isHidden = false
        artistNameLabel.isHidden = false
        for i in 0..<displayLabels.count {
            displayLabels[i].isHidden = false
        }
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
        self.player?.playSpotifyURI(testURI, startingWith: 0, startingWithPosition: 0, callback: { (error) in
            if (error != nil) {
                print("playing!")
            }
        })
        
    }
    
    func updateWeather() {
        
    }
    
    func updateURI() {
        //let testValue = "Sunny"
    }
    
    @IBAction func play(_ sender: UIButton) {
        updateWeather()
        updateURI()
        playCurrentURI()
    }
    
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        if UIApplication.shared.openURL(loginUrl!) {
            if !auth.canHandle(auth.redirectURL) {
                print("Connection Error - Invalid RedirectURL")
            }
        }
    }
    
    
    
}
