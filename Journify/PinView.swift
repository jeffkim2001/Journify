//
//  PinView.swift
//  Journify
//
//  Created by Jeff Kim on 10/20/18.
//  Copyright © 2018 Jeff Kim. All rights reserved.
//

import UIKit

protocol PinDelegate {
    func openDetailScreen()
}

class PinView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var eventTitle: UILabel!
    @IBOutlet weak var userEmail: UILabel!
    var eventName: String = ""
    var email: String = ""
    var delegate: PinDelegate!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("PinView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        eventTitle.text = eventName
        userEmail.text = email
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openDetails))
        self.addGestureRecognizer(tapGesture)
    }
    
    @objc func openDetails() {
        self.delegate.openDetailScreen()
    }

}
