//
//  ViewController.swift
//  VideoPlayerTest
//
//  Created by nihar chadhei on 05/07/19.
//  Copyright © 2019. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadVideoPalyer()
    }
   
    func loadVideoPalyer() {
        guard let url1 = URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4") else { return }
        guard let url2 =  URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4") else { return }
        guard let url3 = URL(string: "http://techslides.com/demos/sample-videos/small.mp4") else { return }
        guard let url4 = URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4") else { return }
        guard let url5 = URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4") else { return }
        let playerViewController = AVVideoViewController(url: [url1, url2, url3, url4, url5])
        playerViewController.configureVideoPlayer()
        playerViewController.modalPresentationStyle = .overFullScreen
        self.present(playerViewController, animated: true, completion: nil)
    }
}
