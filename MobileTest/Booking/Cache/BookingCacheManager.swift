//
//  BookingCacheManager.swift
//  MobileTest
//
//  Created by 郭嘉俊 on 2025/9/27.
//

import Foundation

// MARK: - 缓存方法相关协议

protocol BookingCacheManagerProtocol {
    
    /// 保存Booking 数据到缓存
    /// - Parameter booking: booking Model数据
    ///  失败时 throws 异常数据
    func saveBooking(_ booking: BookingModel) throws
    
    /// 从缓存获取 Booking数据
    /// - Returns: 获取到的Booking数据
    /// 失败时 throws 异常数据
    func getBookingFromCached() throws -> BookingModel?
    
    /// 清空缓存数据
    // 失败时 throws 异常数据
    func clearCache() throws
    
    /// 检查缓存数据是否依然有效
    /// - Returns: 缓存存在 & 未过期 返回true
    func isCacheValid() -> Bool
    
    /// 获取缓存数据
    func getCacheInfo() -> CacheInfo?
}


/// 缓存信息（状态）
struct CacheInfo {
    /// 缓存时间
    let cachedDate: Date
    /// 过期时间
    let expiresDate: Date
    /// 是否过期
    let isExpired: Bool
    /// 有效期剩余时间
    let timeRemaining: TimeInterval
}

class BookingCacheManager: BookingCacheManagerProtocol {
    
    private let cacheKey = "cached_BookingModel"
    private let userDefaults = UserDefaults.standard
    private let cacheDuration: TimeInterval
    
    /// 初始化
    /// - Parameter cacheDuration: 缓存持续时间（s）；默认10分钟
    init(cacheDuration: TimeInterval = 600) {
        self.cacheDuration = cacheDuration
    }
    
    
    // 实现协议方法
    
    
    /// 保存Booking
    /*
     将数据序列话后保存到UserDefaults(coreData 或者 sql 都可以)
     */
    func saveBooking(_ booking: BookingModel) throws {
        print("【BookingCacheManager】: 正在保存BookingModel...")
        let cachedData = CacheBookingData(booking: booking, cacheDuration: cacheDuration)
        
        do {
            // 序列化缓存数据
            let encoder = JSONEncoder()
            let data = try encoder.encode(cachedData)
            userDefaults.set(data, forKey: cacheKey)
            print("【BookingCacheManager】: Booking成功保存✅")
            print("【BookingCacheManager】: 缓存过期时间: \(Date(timeIntervalSince1970: cachedData.expiresTimeInterval))")
            
        } catch {
            print("【BookingCacheManager】: Booking保存失败❌ - \(error.localizedDescription)")
            throw BookingError.cacheError("保存Booking到缓存失败: \(error.localizedDescription)")
        }
    }
    
    /// 从缓存获取Booking
    /*
     UserDefaults 获取数据并反序列化
     */
    func getBookingFromCached() throws -> BookingModel? {
        print("【BookingCacheManager】: 正在从缓存获取BookingModel...")
        
        guard let data = userDefaults.data(forKey: cacheKey) else { print("【BookingCacheManager】: 没找到数据")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let cachedData = try decoder.decode(CacheBookingData.self, from: data)
            
            if cachedData.isExpired {
                print("【BookingCacheManager】：缓存数据已经过期")
                try clearCache()
                return nil
            }
            print("【BookingCacheManager】：成功获取有效期内的缓存数据（有效期剩余（\((Date().timeIntervalSince1970 - cachedData.cachedTimeInterval))秒））")
            
            return cachedData.booking
        } catch {
            print("【BookingCacheManager】: 解码缓存数据失败 - \(error.localizedDescription)")
            try clearCache()
            throw BookingError.cacheError("【BookingCacheManager】:解码缓存数据失败: \(error.localizedDescription)")
        }
        
    }
    
    /// 清空缓存
    func clearCache() throws {
        print("【BookingCacheManager】: 正在清除缓存...")
        userDefaults.removeObject(forKey: cacheKey)
        print("【BookingCacheManager】: 缓存清除成功")
    }
    
    /// 检查缓存的Booking 是否在有效期内
    /// - Returns: 有效期内 返回true
    func isCacheValid() -> Bool {
        guard let data = userDefaults.data(forKey: cacheKey) else {
            return false
        }
        
        do {
            let decoder = JSONDecoder()
            let cachedData = try decoder.decode(CacheBookingData.self, from: data)
            return !cachedData.isExpired
        } catch {
            return false
        }
    }
    
    /// 获取缓存信息
    /// - Returns: CacheInfo? 缓存信息，如果没有缓存返回nil
    func getCacheInfo() -> CacheInfo? {
        guard let data = userDefaults.data(forKey: cacheKey) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let cachedData = try decoder.decode(CacheBookingData.self, from: data)
            
            let cachedDate = Date(timeIntervalSince1970: cachedData.cachedTimeInterval)
            
            let expiresDate = Date(timeIntervalSince1970: cachedData.expiresTimeInterval)
            
            let timeRemaining = max(0, expiresDate.timeIntervalSinceNow)
            
            return CacheInfo(
                cachedDate: cachedDate,
                expiresDate: expiresDate,
                isExpired: cachedData.isExpired,
                timeRemaining: timeRemaining
            )
        } catch {
            return nil
        }
    }
}


// MARK: - 内存缓存管理器（替代实现）

/**
 * 预订内存缓存管理器
 * 使用内存进行缓存，不进行持久化
 */
class BookingMemoryCacheManager: BookingCacheManagerProtocol {

    
    
    // MARK: - 属性
    
    /// 缓存的预订数据
    private var cachedData: CacheBookingData?
    /// 缓存持续时间（秒）
    private let cacheDuration: TimeInterval
    
    // MARK: - 初始化
    
    /**
     * 初始化方法
     * @param cacheDuration 缓存持续时间（秒），默认10分钟
     */
    init(cacheDuration: TimeInterval = 600) {
        self.cacheDuration = cacheDuration
    }
    
    // MARK: - 公共方法
    
    /**
     * 保存预订数据到内存缓存
     */
    func saveBooking(_ booking: BookingModel) throws {
        print("【BookingMemoryCacheManager】: 正在保存预订到内存缓存...")
        
        cachedData = CacheBookingData(booking: booking, cacheDuration: cacheDuration)
        print("【BookingMemoryCacheManager】: 成功保存预订到内存缓存")
        print("【BookingMemoryCacheManager】: 缓存过期时间: \(Date(timeIntervalSince1970: cachedData!.expiresTimeInterval))")
    }
    
    /**
     * 从内存缓存获取预订数据
     */
    func getBookingFromCached() throws -> BookingModel? {
        print("【BookingMemoryCacheManager】: 正在从内存缓存获取预订...")
        
        guard let cachedData = cachedData else {
            print("【BookingMemoryCacheManager】: 内存中无缓存数据")
            return nil
        }
        
        if cachedData.isExpired {
            print("【BookingMemoryCacheManager】: 缓存数据已过期")
            self.cachedData = nil
            return nil
        }
        
        print("【BookingMemoryCacheManager】: 成功获取有效期内的数据：剩余有效期 \(Date().timeIntervalSince1970 - cachedData.cachedTimeInterval) 秒")
        return cachedData.booking
    }
    
    /**
     * 清除内存缓存
     */
    func clearCache() throws {
        print("【BookingMemoryCacheManager】: 正在清除内存缓存...")
        cachedData = nil
        print("【BookingMemoryCacheManager】: 内存缓存清除成功")
    }
    
    /**
     * 检查内存缓存是否有效
     * @return Bool 如果缓存有效返回true
     */
    func isCacheValid() -> Bool {
        return cachedData?.isExpired == false
    }
    
    /**
     * 获取内存缓存信息
     * @return CacheInfo? 缓存信息，如果没有缓存返回nil
     */
    func getCacheInfo() -> CacheInfo? {
        guard let cachedData = cachedData else {
            return nil
        }
        
        let cachedDate = Date(timeIntervalSince1970: cachedData.cachedTimeInterval)
        let expiresDate = Date(timeIntervalSince1970: cachedData.expiresTimeInterval)
        let timeRemaining = max(0, expiresDate.timeIntervalSinceNow)
        
        return CacheInfo(
            cachedDate: cachedDate,
            expiresDate: expiresDate,
            isExpired: cachedData.isExpired,
            timeRemaining: timeRemaining
        )
    }
}

