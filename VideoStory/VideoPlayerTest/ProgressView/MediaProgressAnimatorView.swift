//
//  MediaProgressAnimatorView.swift
//  VideoPlayerTest
//
//  Created by nihar chadhei on 23/07/19.
//  Copyright © 2019. All rights reserved.
//

import UIKit


final class MediaProgressAnimatorView: UIView, ProgerssViewAnimator {
    var storyIdentifier: String?
    var snapIndex: Int?
    var isCancelledAbruptly: Bool = false
}

protocol ProgerssViewAnimator: class {
    func start(with duration: TimeInterval, width: CGFloat, completion: @escaping (_ snapIndex: Int, _ isCancelledAbruptly: Bool) -> Void)
    func resume()
    func pause()
    func stop()
    func reset()
}
extension ProgerssViewAnimator where Self: MediaProgressAnimatorView {
    func start(with duration: TimeInterval, width: CGFloat, completion: @escaping (_ snapIndex: Int, _ isCancelledAbruptly: Bool) -> Void) {
        UIView.animate(withDuration: duration, delay: 0.0, options: [.curveLinear], animations: {[weak self] in
            if let _self = self {
                _self.frame.size.width = width
            }
        }) { [weak self] (finished) in
            guard let strongSelf = self else {
                return completion(0, true)
            }
            strongSelf.isCancelledAbruptly = !finished
            if finished == true {
                 return completion(strongSelf.snapIndex!, strongSelf.isCancelledAbruptly)
            } else {
                return completion(strongSelf.snapIndex ?? 0, strongSelf.isCancelledAbruptly )
            }
        }
    }
    func resume() {
        let pausedTime = layer.timeOffset
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        layer.beginTime = timeSincePause
    }
    
    func pause() {
        let pausedTime = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0.0
        layer.timeOffset = pausedTime
    }
    
    func stop() {
        resume()
        layer.removeAllAnimations()
    }
    
    func reset() {
        isCancelledAbruptly = true
        frame.size.width = 0
    }
    
    
}

