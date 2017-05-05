//
//  Song.swift
//  Weathify
//
//  Created by Alexander Tryjankowski on 5/4/17.
//  Copyright © 2017 Alexander Tryjankowski. All rights reserved.
//

import Foundation

struct Song {
    var title : String?
    var artist : String?
    var albumName : String?
    var albumArt : UIImage?
    
    init(title:String?,artist:String?,albumName:String?,albumArt:UIImage?) {
        self.title = title
        self.artist = artist
        self.albumName = albumName
        self.albumArt = albumArt
    }
}
