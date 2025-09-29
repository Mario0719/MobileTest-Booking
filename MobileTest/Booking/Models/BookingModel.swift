//
//  BookingModel.swift
//  MobileTest
//
//  Created by 郭嘉俊 on 2025/9/27.
//

import Foundation

// MARK: - 数据模型 （拆分）

struct BookingModel: Codable {
    /// 船舶参考信息
    let shipReference: String
    /// token 令牌
    let shipToken: String
    /// 是否可以签票务检查
    let canIssueTicketChecking: Bool
    /// 有效期
    let expiryTime: String
    /// 持续时间
    let duration: Int
    /// 航段（应该是航程分段）
    let segments: [Segment]
    
    /// 检查预订是否已过期
    var isExpired: Bool {
        guard let expiryTimestamp = Double(expiryTime) else { return true }
        let expiryDate = Date(timeIntervalSince1970: expiryTimestamp)
        return Date() > expiryDate
    }
    
    /// 计算属性：获取过期日期
    var expiryDate: Date? {
        guard let expiryTimestamp = Double(expiryTime) else { return nil }
        return Date(timeIntervalSince1970: expiryTimestamp)
    }
}

/// 航段信息
struct Segment: Codable {
    /// 航段 id
    let id: Int;
    /// 起点终点 信息
    let originAndDestinationPair: OriginDestinationPari
}

/// 起点终点信息
struct OriginDestinationPari: Codable {
    /// 起始地 位置信息
    let origin: Location
    /// 起始地城市名称
    let originCity: String
    
    /// 目的地 位置信息
    let destination: Location
    /// 目的地城市名称
    let destinationCity: String
}

/// 地点信息Model
struct Location: Codable {
    /// 地点代码
    let code: String
    /// 地点名称
    let displayName: String
    /// 官网（相关地址）
    let url: String
}


// MARK： - API方法

struct BookingResponse: Codable {
    /// 预定数据Model
    let booking: BookingModel
    /// 响应时间
    let timestamp: TimeInterval
    /// 是否缓存的数据
    let isCache: Bool
    
    /// 初始化
    /// - Parameters:
    ///   - booking: 服务器（缓存）返回的数据
    ///   - isCache: 是否来自缓存； true = 从缓存来的， false = 从服务器来的
    init(booking: BookingModel, isCache: Bool) {
        self.booking = booking
        self.isCache = isCache
        self.timestamp = Date().timeIntervalSince1970
    }
}

/// Booking 错误 枚举
enum BookingError: Error, LocalizedError {
    /// 网络错误
    case networkError(String)
    /// 解析失败错误
    case dataParsingError(String)
    /// 缓存错误
    case cacheError(String)
    /// 数据过期
    case expiredData(String)
    /// 无数据
    case noData(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let msg): return "❌网络错误：\(msg)"
        case .dataParsingError(let msg): return "❌数据解析错误：\(msg)"
        case .cacheError(let msg): return "❌缓存错误：\(msg)"
        case .expiredData: return "❌数据已过期"
        case .noData: return "❌没有数据"
        }
    }
}


// MARK: - 缓存方法

struct CacheBookingData: Codable {
    /// booking 数据
    let booking: BookingModel;
    /// 缓存时间戳
    let cachedTimeInterval: TimeInterval
    /// 过期时间戳
    let expiresTimeInterval: TimeInterval
    
    
    /// 检查缓存是否已经过期
    var isExpired: Bool {
        return Date().timeIntervalSince1970 > expiresTimeInterval
    }
    
    
    
    
    /// 初始化
    /// - Parameters:
    ///   - booking: 传入需要缓存的数据
    ///   - cacheDuration: 缓存持续时间（s），默认10分钟
    init(booking: BookingModel, cacheDuration: TimeInterval = 600) {
        self.booking = booking
        let currentTimeInterval = Date().timeIntervalSince1970
        self.cachedTimeInterval = currentTimeInterval // 缓存当前的时间戳
        self.expiresTimeInterval = currentTimeInterval + cacheDuration // 当前时间戳 + 传入的规定时间 = 有效期
    }
}
