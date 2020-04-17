//
//  MediaProgressView.swift
//  VideoPlayerTest
//
//  Created by nihar chadhei on 23/07/19.
//  Copyright © 2019. All rights reserved.
//

import UIKit


extension Int {
    var toFloat: CGFloat {
        return CGFloat(self)
    }
}

extension Array {
    func sortedArrayByPosition() -> [Element] {
        return sorted(by: { (obj1 : Element, obj2 : Element) -> Bool in
            
            let view1 = obj1 as! UIView
            let view2 = obj2 as! UIView
            
            let x1 = view1.frame.minX
            let y1 = view1.frame.minY
            let x2 = view2.frame.minX
            let y2 = view2.frame.minY
            
            if y1 != y2 {
                return y1 < y2
            } else {
                return x1 < x2
            }
        })
    }
}

struct MediaProgressViewScreen {
    static let width = UIScreen.main.bounds.width
    static let height = UIScreen.main.bounds.height
}

let progressViewTag = 99
let progressIndicatorViewTag = 88

final class MediaProgressView: UIView {
    
    let maxSnaps = 30
    private var progressView:UIView?
    var getProgressView: UIView {
        if let progressView = self.progressView {
            return progressView
        }
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        self.progressView = v
        return v
    }
    var snaps:Int = 0
    var mediaCount: Int = 0 {
        didSet {
            snaps = mediaCount < maxSnaps ? mediaCount : maxSnaps
            createSnapProgressors()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.frame = frame
        loadUIElements()
        installLayoutConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadUIElements()
        installLayoutConstraints()
    }
    
    private func loadUIElements(){
        backgroundColor = .clear
        addSubview(getProgressView)
    }
    
    private func installLayoutConstraints(){
        let pv = getProgressView
        NSLayoutConstraint.activate([
            pv.leftAnchor.constraint(equalTo: self.leftAnchor),
            pv.topAnchor.constraint(equalTo: self.topAnchor),
            pv.rightAnchor.constraint(equalTo: self.rightAnchor),
            pv.bottomAnchor.constraint(equalTo: self.bottomAnchor)])
        
        layoutIfNeeded()
    }
    
    private func applyProperties<T:UIView>(_ view:T,with tag:Int,alpha:CGFloat = 1.0)->T {
        view.layer.cornerRadius = 1
        view.layer.masksToBounds = true
        view.backgroundColor = UIColor.white.withAlphaComponent(alpha)
        view.tag = tag
        return view
    }
    
    func createSnapProgressors(){
        let padding:CGFloat = 8 //GUI-Padding
        let height:CGFloat = 3
        var x:CGFloat = padding
        let y:CGFloat = (self.getProgressView.frame.height/2)-height
        let width = (MediaProgressViewScreen.width - ((snaps + 1).toFloat * padding))/snaps.toFloat
        for i in 0..<snaps {
            let pvIndicator = UIView.init(frame: CGRect(x: x, y: y, width: width, height: height))
            getProgressView.addSubview(applyProperties(pvIndicator, with: i + progressIndicatorViewTag, alpha:0.2))
            let pv = MediaProgressAnimatorView.init(frame: CGRect(x: x, y: y, width: 0, height: height))
            getProgressView.addSubview(applyProperties(pv, with: i + progressViewTag))
            x = x + width + padding
        }
    }
    
    func resetProgressBar() {
        for i in 0..<snaps {
            if let pv = getProgressView.subviews.filter({v in v.tag == i + progressViewTag}).first as? MediaProgressAnimatorView {
                pv.frame.size.width = 0
            }
        }
    }
}

