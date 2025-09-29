//
//  TestingBookingDataManager.swift
//  MobileTest
//
//  Created by 郭嘉俊 on 2025/9/27.
//

import Foundation

/**
 * BookingDataManager 的测试类
 * 用户测试主流程。 代替单元测试
 */
class TestingBookingDataManager {
    
    /**
     * 运行所有测试
     * 执行基本数据加载、缓存功能和错误处理测试
     */
    static func runTests() {
        print("【TestingBookingDataManager】： 开始预订数据管理器测试...")
        
        // 测试1：基本数据加载
        testBasicDataLoading()
        
        // 测试2：缓存功能
        testCacheFunctionality()
        
        // 测试3：错误处理
        testErrorHandling()
        
        print("【TestingBookingDataManager】：所有测试完成！")
    }
    
    /**
     * 测试基本数据加载
     * 验证数据管理器能够成功加载预订数据
     */
    private static func testBasicDataLoading() {
        print("\n📋 测试1：基本数据加载")
        
        let dataManager = BookingDataManager()
        
        Task {
            do {
                let response = try await dataManager.getBookingData()
                print("✅ 测试1通过：成功加载预订数据")
                print("📊 船舶参考号：\(response.booking.shipReference)")
                print("📊 航段数量：\(response.booking.segments.count)")
                print("📊 来自缓存：\(response.isCache)")
            } catch {
                print("❌ 测试1失败：\(error.localizedDescription)")
            }
        }
    }
    
    /**
     * 测试缓存功能
     * 验证缓存保存和读取功能是否正常工作
     */
    private static func testCacheFunctionality() {
        print("\n📋 测试2：缓存功能")
        
        let dataManager = BookingDataManager()
        
        Task {
            do {
                // 第一次加载（应该缓存）
                let response1 = try await dataManager.getBookingData(forceRefresh: true)
                print("✅ 第一次加载完成")
                
                // 第二次加载（应该使用缓存）
                let response2 = try await dataManager.getBookingData()
                print("✅ 第二次加载完成")
                print("📊 第一次加载来自缓存：\(response1.isCache)")
                print("📊 第二次加载来自缓存：\(response2.isCache)")
                
                if response2.isCache {
                    print("✅ 测试2通过：缓存功能正常工作")
                } else {
                    print("❌ 测试2失败：缓存未正常工作")
                }
            } catch {
                print("❌ 测试2失败：\(error.localizedDescription)")
            }
        }
    }
    
    /**
     * 测试错误处理
     * 验证系统在遇到错误时的处理能力
     */
    private static func testErrorHandling() {
        print("\n📋 测试3：错误处理")
        
        
        let mockService = TestMockBookingService(mockResult: false)
        let dataManager = BookingDataManager(service: mockService, cacheManager: BookingCacheManager())
        
        Task {
            do {
                let _ = try await dataManager.getBookingData()
                print("❌ 测试3失败：应该抛出错误")
            } catch {
                print("✅ 测试3通过：错误处理正常工作 - \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - 演示用法

extension TestingBookingDataManager {
    
    /**
     * 运行演示
     * 展示数据管理器的完整功能流程
     */
    static func runDemo() {
        print("🎬 开始预订数据管理器演示...")
        
        let dataManager = BookingDataManager.shared
        
        // 演示1：加载数据
        Task {
            do {
                print("\n🔄 演示1：加载预订数据...")
                let response = try await dataManager.getBookingData()
                print("✅ 演示1完成：数据加载成功")
                print("📊 响应详情：")
                print("   - 船舶参考号：\(response.booking.shipReference)")
                print("   - 船舶令牌：\(response.booking.shipToken)")
                print("   - 航段数量：\(response.booking.segments.count)")
                print("   - 可以签发票务：\(response.booking.canIssueTicketChecking)")
                print("   - 持续时间：\(response.booking.duration) 分钟")
                print("   - 来自缓存：\(response.isCache)")
                
                // 演示2：显示航段
                print("\n🔄 演示2：显示航段...")
                for (index, segment) in response.booking.segments.enumerated() {
                    let pair = segment.originAndDestinationPair
                    print("   航段 \(index + 1)：")
                    print("     - ID：\(segment.id)")
                    print("     - 路线：\(pair.originCity) → \(pair.destinationCity)")
                    print("     - 出发地：\(pair.origin.code) - \(pair.origin.displayName)")
                    print("     - 目的地：\(pair.destination.code) - \(pair.destination.displayName)")
                }
                
                // 演示3：缓存信息
                print("\n🔄 演示3：缓存信息...")
                if let cacheInfo = dataManager.getCacheInfo() {
                    print("   - 缓存时间：\(Date(timeIntervalSince1970: cacheInfo.cachedDate.timeIntervalSince1970))")
                    print("   - 过期时间：\(Date(timeIntervalSince1970: cacheInfo.expiresDate.timeIntervalSince1970))")
                    print("   - 是否过期：\(cacheInfo.isExpired)")
                    print("   - 剩余时间：\(Int(cacheInfo.timeRemaining)) 秒")
                } else {
                    print("   - 无缓存信息可用")
                }
                
                print("\n✅ 演示成功完成！")
                
            } catch {
                print("❌ 演示失败：\(error.localizedDescription)")
            }
        }
    }
}
