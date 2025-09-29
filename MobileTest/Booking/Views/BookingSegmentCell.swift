//
//  BookingSegmentCell.swift
//  MobileTest
//
//  Created by 郭嘉俊 on 2025/9/28.
//

import UIKit

class BookingSegmentCell: UITableViewCell {

    @IBOutlet weak var segment: UILabel!
    @IBOutlet weak var destinationCity: UILabel!
    @IBOutlet weak var otherInfo: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(with shipSegment: Segment) {
        segment.text = "航段 #\(shipSegment.id)"
        let pair = shipSegment.originAndDestinationPair

        destinationCity.text = "\(pair.origin.displayName) → \(pair.destination.displayName)"
//
//        originCity.text = "000"
//        
//        
//        destinationCity.text =  "111"
//        
        otherInfo.text = "\(pair.origin.code) - \(pair.origin.displayName)"
    }
    
}
