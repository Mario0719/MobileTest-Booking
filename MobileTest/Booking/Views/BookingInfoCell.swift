//
//  BookingInfoCell.swift
//  MobileTest
//
//  Created by 郭嘉俊 on 2025/9/28.
//

import UIKit

class BookingInfoCell: UITableViewCell {

    @IBOutlet weak var shipReference: UILabel!
    
    @IBOutlet weak var shipToken: UILabel!
    
    @IBOutlet weak var expireTime: UILabel!
    
    @IBOutlet weak var issueTicketChecking: UILabel!
    
    @IBOutlet weak var duration: UILabel!
    
    
    @IBOutlet weak var cachedData: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(with booking: BookingModel, isFromCache: Bool) {
        shipReference.text = "船舶参考号: \(booking.shipReference)"
        shipToken.text = "令牌: \(booking.shipToken)"
        
        // 格式化过期时间
        if let expiryDate = booking.expiryDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            expireTime.text = "过期时间: \(formatter.string(from: expiryDate))"
            
            // 根据过期状态改变颜色
            if booking.isExpired {
                expireTime.textColor = .systemRed
                expireTime.text = "⚠️ 已过期: \(formatter.string(from: expiryDate))"
            } else {
                expireTime.textColor = .systemOrange
            }
        } else {
            expireTime.text = "过期时间: 无效时间戳"
            expireTime.textColor = .systemRed
        }
        
        // 格式化持续时间
        let hours = booking.duration / 60
        let minutes = booking.duration % 60
        duration.text = "持续时间: \(hours)小时 \(minutes)分钟"
        
        // 票务检查状态
        issueTicketChecking.text = booking.canIssueTicketChecking ? "✅ 可以签发票务" : "❌ 无法签发票务"
        issueTicketChecking.textColor = booking.canIssueTicketChecking ? .systemGreen : .systemRed
        
        // 缓存指示器
        cachedData.isHidden = !isFromCache
    }
    
}
