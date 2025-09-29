iOS_Swift_Booking

MainViewController 下有3个按钮 分别是：

Push到 Booking 的列表页面
测试缓存功能（控制台）
测试demo运行（控制台）
所有关于Booking 的代码都在 Booking的目录中。 （一个目录一个功能模块）

BookingCacheManager （缓存管理器）
- 
保存Booking 数据到缓存 func saveBooking(_ booking: BookingModel) throws

从缓存获取 Booking数据 func getBookingFromCached() throws -> BookingModel?

清空缓存数据 func clearCache() throws

检查缓存数据是否依然有效 func isCacheValid() -> Bool

获取缓存数据 func getCacheInfo() -> CacheInfo?

BookingService （网络服务）
- 
异步获取网络数据（模拟） func fetchBookingData() async throws -> BookingModel

BookingDataManager (DataManager)
-
相当于ViewModel的存在；负责调度 BookingService 、 BookingCacheManager 、 通知渲染UI

BookingModel 预定数据Model
-
数据模型
