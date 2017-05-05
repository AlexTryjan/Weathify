//
//  Song.swift
//  Weathify
//
//  Created by Alexander Tryjankowski on 5/4/17.
//  Copyright © 2017 Alexander Tryjankowski. All rights reserved.
//

import Foundation

class Song {
    var title : String?
    var artist : String?
    var albumName : String?
    var albumArt : NSData?
    
    init(title:String?,artist:String?,albumName:String?,albumArt:NSData?) {
        self.title = title
        self.artist = artist
        self.albumName = albumName
        self.albumArt = albumArt
    }
}
