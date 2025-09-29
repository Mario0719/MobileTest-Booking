//
//  BookingServices.swift
//  MobileTest
//
//  Created by 郭嘉俊 on 2025/9/27.
//

import Foundation

/*
 定义一个 获取数据的协议
 */
protocol BookingServiceProtocol {
    /// 异步获取Booking数据
    /*
     return Booking 对象
     或者
     throws error
     */
    func fetchBookingData() async throws -> BookingModel
}

class BookingService: BookingServiceProtocol {
    // 本地有一个booking.json 的文件
    private let localJsonFileName = "booking"
    private let localJsonFileExtension = "json"
    
    
    /// 读取本地的 json 数据
    /// - Returns: booking 对象
    private func loadLocalData() throws -> BookingModel {
        guard let url = Bundle.main.url(forResource: localJsonFileName, withExtension: localJsonFileExtension) else { throw BookingError.dataParsingError("数据解析错误（项目中没有找到本地Json文件）") }
        
        do {
            // url 有内容，读取数据
            let data = try Data(contentsOf: url)
            // 解码器对象
            let decoder = JSONDecoder()
            // 解析，转成BookingModel
            let bookingModel = try decoder.decode(BookingModel.self, from: data)
            // 返回拿到的数据
            return bookingModel
        } catch {
            throw BookingError.dataParsingError("解析失败，请检查属性是不是错误：\(error.localizedDescription)")
        }
    }
    
    func fetchBookingData() async throws -> BookingModel {
        print("【BookingService】: 开始获取预定数据")
        
        do {
            let booking = try loadLocalData()
            print("【BookingService】: ✅成功加载预订数据")
            print("【BookingService】: 船舶参考信息: \(booking.shipReference)")
            print("【BookingService】: 航段数量: \(booking.segments.count)")
            print("【BookingService】: 过期时间: \(booking.expiryTime)")
            return booking
        } catch {
            print("【BookingService】: ❌加载预订数据失败")
            throw BookingError.dataParsingError("【BookingService】：❌本地文件加载预订数据失败")
        }
    }
}


/*
 模拟预定数据（仅用于开发者测试功能是否能跑通，每一步执行都打印在控制台。）
 （代替单元测试）
 */

class TestMockBookingService: BookingServiceProtocol {
    /// 模拟延迟时间
    private let mockDelay: UInt64
    /// 模拟结果：true = 模拟成功的结果， false = 模拟失败的结果
    private let mockResult: Bool
    
    /// 初始化
    /// - Parameters:
    ///   - mockDelay: 延迟0.5秒
    ///   - mockResult: 模拟结果（默认失败）
    init(mockDelay: UInt64 = 500_000_000, mockResult: Bool = false) {
        self.mockDelay = mockDelay
        self.mockResult = mockResult
    }
    
    
    private func createMockBooking() -> BookingModel {
        // 计算过期时间 10分钟（600秒）
        let currentTime = Date().timeIntervalSince1970
        let expiryTime = currentTime + 600 // 10分钟后过期
        
        let origin = Location(code: "Mock始发地", displayName: "广州", url: "www.mock.guangzhou.com")
        let destination = Location(code: "Mock目的地", displayName: "上海", url: "www.mock.shanghai.com")
        
        let segment = Segment(id: 1, originAndDestinationPair: OriginDestinationPari(origin: origin, originCity: "广州", destination: destination, destinationCity: "上海"))
        
        return BookingModel(shipReference: "Mock123456", shipToken: "MockToken123", canIssueTicketChecking: true, expiryTime: String(Int(expiryTime)), duration: 120, segments: [segment])
    }
    
    
    func fetchBookingData() async throws -> BookingModel {
        print("【TestMockBookingService】：开始测试模拟获取Booking 数据")
        
        try await Task.sleep(nanoseconds: mockDelay)
        
        if mockResult == false {
            print("【TestMockBookingService】: 模拟网络失败")
            throw BookingError.networkError("模拟网络失败")
        }
        let mockBooking = createMockBooking()
        print("【TestMockBookingService】: 成功创建模拟Booking数据")
        print("【TestMockBookingService】: 船舶参考信息: \(mockBooking.shipReference)")
        print("【TestMockBookingService】: 航段数量: \(mockBooking.segments.count)")
        
        
        return mockBooking
    }
}
