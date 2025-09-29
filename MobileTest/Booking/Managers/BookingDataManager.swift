//
//  BookingDataManager.swift
//  MobileTest
//
//  Created by 郭嘉俊 on 2025/9/27.
//

import Foundation
import Combine

// MARK:- 数据管理器


protocol BookingDataManagerProtocol {
    
    
    /// 获取Booking 数据
    /// - Parameter forceRefresh: 是否强制刷新； 默认false
    /// - Returns: booking 响应数据
    func getBookingData(forceRefresh: Bool) async throws -> BookingResponse
    
    /// 刷新数据
    /// - Returns: 最新的 Booking 响应数据
    func refreshData() async throws -> BookingResponse
    
    /// 获取缓存数据 （从缓存获取数据，不经过Service）
    /// - Returns: 缓存中的响应数据
    func getCachedData() throws -> BookingResponse?
    
    /// 清除缓存
    func clearCache() throws
    
    /// 是否正在刷新数据
    var isRefreshing: Bool {get}
    
    /// 刷新状态发布者
    var isRefreshingPublisher: AnyPublisher<Bool, Never> {get}
    
    /// 数据发布者
    var dataPublisher: AnyPublisher<BookingResponse, Never> {get}
}

class BookingDataManager: BookingDataManagerProtocol {
    
    /// Service 服务层 实例对象
    private let service: BookingServiceProtocol
    /// 缓存管理器 实例对象
    private let cacheManager: BookingCacheManagerProtocol
    /// 数据发布者（通知UI层 刷新数据）
    private let dataSubject = PassthroughSubject<BookingResponse, Never>()
    
    /// 是否正在刷新数据
    @Published private(set) var isRefreshing: Bool = false
    
    /// 数据发布者
    var dataPublisher: AnyPublisher<BookingResponse, Never> {
        dataSubject.eraseToAnyPublisher()
    }
    
    var isRefreshingPublisher: AnyPublisher<Bool, Never> {
        $isRefreshing.eraseToAnyPublisher()
    }
    
    /// 初始化 DataManager
    /// - Parameters:
    ///   - service: 默认使用BookingService
    ///   - cacheManager: 默认使用BookingCacheManager
    init(service: BookingServiceProtocol = BookingService(),
         cacheManager: BookingCacheManagerProtocol = BookingCacheManager()) {
        self.service = service
        self.cacheManager = cacheManager
    }
    
    func getBookingData(forceRefresh: Bool = false) async throws -> BookingResponse {
        print("【BookingDataManager】: 获取Booking 数据！！（强制刷新->\(forceRefresh)）")
        
        if forceRefresh == false {
            do {
                if let cachedBooking = try cacheManager.getBookingFromCached() {
                    let response = BookingResponse(booking: cachedBooking, isCache: true)
                    print("【BookingDataManager】: 返回缓存数据")
                    dataSubject.send(response)
                    return response
                }
            } catch {
                print("【BookingDataManager】: 访问缓存时出错: \(error.localizedDescription)")
            }
        }
        
        
        return try await fetchFreshData()
    }
    
    /// 刷新数据
    func refreshData() async throws -> BookingResponse {
        print("【BookingDataManager】: 刷新数据...")
        return try await fetchFreshData()
    }
    
    /// 获取缓存数据
    func getCachedData() throws -> BookingResponse? {
        print("【BookingDataManager】: 仅获取缓存数据...")
        
        guard let cachedBooking = try cacheManager.getBookingFromCached() else {
            print("【BookingDataManager】: 无可用缓存数据")
            return nil
        }
        
        let response = BookingResponse(booking: cachedBooking, isCache: true)
        print("【BookingDataManager】: 返回缓存数据")
        return response
    }
    
    /**
     * 清除缓存
     * @throws BookingError 如果清除失败
     */
    func clearCache() throws {
        print("【BookingDataManager】: 清除缓存...")
        try cacheManager.clearCache()
        print("【BookingDataManager】: 缓存清除成功")
    }
    
    // MARK: - 私有方法
    
    /**
     * 获取新数据
     * 从服务层获取数据并更新缓存
     * @return BookingResponse 新的预订响应数据
     * @throws BookingError 可能抛出各种错误
     */
    private func fetchFreshData() async throws -> BookingResponse {
        print("【BookingDataManager】: 从服务层获取新数据...")
        
        isRefreshing = true
        
        do {
            // 从服务层获取数据
            let booking = try await service.fetchBookingData()
            
            // 保存到缓存
            do {
                try cacheManager.saveBooking(booking)
            } catch {
                print("【BookingDataManager】: 保存到缓存失败: \(error.localizedDescription)")
                // 不抛出错误，因为我们仍然有有效数据
            }
            
            let response = BookingResponse(booking: booking, isCache: false)
            print("【BookingDataManager】: 成功获取新数据")
            print("【BookingDataManager】: 船舶参考信息: \(booking.shipReference)")
            print("【BookingDataManager】: 航段数量: \(booking.segments.count)")
            
            // 通知订阅者
            dataSubject.send(response)
            isRefreshing = false
            return response
            
        } catch {
            print("【BookingDataManager】: 获取新数据失败: \(error.localizedDescription)")
            isRefreshing = false
            
            // 如果服务层失败，尝试返回缓存数据作为后备
            if let cachedBooking = try? cacheManager.getBookingFromCached() {
                print("【BookingDataManager】: 由于服务层失败，回退到缓存数据")
                let response = BookingResponse(booking: cachedBooking, isCache: true)
                dataSubject.send(response)
                return response
            }
            
            throw error
        }
    }
}



// MARK: - 拓展 ｜ BookingDataManager 是一个全局单例
extension BookingDataManager {
    // 单例
    static let shared = BookingDataManager()
}

// MARK: - 拓展 ｜ 处理管理数据、方法调用

extension BookingDataManager {
    
    // 获取预订数据（自动缓存处理）
    func getBookingData() async throws -> BookingResponse {
        return try await getBookingData(forceRefresh: false)
    }
    
    // 检查是否有有效的缓存数据
    func hasValidCachedData() -> Bool {
        return cacheManager.isCacheValid()
    }
    
    // 获取缓存信息
    func getCacheInfo() -> CacheInfo? {
        return cacheManager.getCacheInfo()
    }
    
    // 强制刷新并返回新数据
    func forceRefresh() async throws -> BookingResponse {
        return try await getBookingData(forceRefresh: true)
    }
}

// MARK: - 拓展 ｜ 处理错误

extension BookingDataManager {
    
    /// 处理错误并提供后备策略
    func handleError(_ error: Error) -> BookingResponse? {
        print("【BookingDataManager】: 处理错误: \(error.localizedDescription)")
        
        // 尝试获取缓存数据作为后备
        do {
            if let cachedBooking = try cacheManager.getBookingFromCached() {
                print("【BookingDataManager】: 使用缓存数据作为后备")
                return BookingResponse(booking: cachedBooking, isCache: true)
            }
        } catch {
            print("【BookingDataManager】: 后备到缓存也失败: \(error.localizedDescription)")
        }
        return nil
    }
}
