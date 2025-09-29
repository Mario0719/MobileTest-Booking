//
//  BookingListViewController.swift
//  MobileTest
//
//  Created by 郭嘉俊 on 2025/9/27.
//

import UIKit
import Combine

class BookingListViewController: BaseViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    
    /// 下拉刷新控制器
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        return refreshControl
    }()
    
    /// 加载指示器，显示数据加载状态
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    /// 错误标签，显示错误信息
    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .systemRed
        label.font = .systemFont(ofSize: 16)
        label.isHidden = true
        return label
    }()
    
    
    /// BookingDataManager  管理类 (相当于ViewModel)
    private let dataManager: BookingDataManagerProtocol
    /// Combine订阅集合
    private var cancellables = Set<AnyCancellable>()
    
    /// 当前的预定数据
    private var bookingData: BookingModel?
    
    /// 数据是否来自缓存
    private var isFromCache = false
    
    
    
    init(dataManager: BookingDataManagerProtocol = BookingDataManager.shared) {
        self.dataManager = dataManager
        super.init(nibName: "BookingListViewController", bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        self.dataManager = BookingDataManager.shared
        super.init(coder: coder)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.setupDataBinding()
        loadData() // 加载数据
    }

    
    // MARK: - 数据加载
    
    /**
     * 加载数据
     * 从数据管理器获取预订数据
     */
    private func loadData() {
        print("📱 BookingListViewController: 正在加载数据...")
        
        Task {
            do {
                let response = try await dataManager.getBookingData(forceRefresh: true)
                await MainActor.run {
                    handleDataUpdate(response)
                }
            } catch {
                await MainActor.run {
                    handleError(error)
                }
            }
        }
    }
    
    /**
     * 刷新数据
     * 下拉刷新时调用，强制获取最新数据
     */
    @objc private func refreshData() {
        print("🔄 BookingListViewController: 正在刷新数据...")
        
        Task {
            do {
                let response = try await dataManager.refreshData()
                await MainActor.run {
                    handleDataUpdate(response)
                    refreshControl.endRefreshing()
                }
            } catch {
                await MainActor.run {
                    handleError(error)
                    refreshControl.endRefreshing()
                }
            }
        }
    }
    
    // MARK: - 数据处理
    
    /**
     * 处理数据更新
     * @param response 预订响应数据
     */
    private func handleDataUpdate(_ response: BookingResponse) {
        print("📊 BookingListViewController: 收到数据更新")
        print("📊 BookingListViewController: 船舶参考号: \(response.booking.shipReference)")
        print("📊 BookingListViewController: 航段数量: \(response.booking.segments.count)")
        print("📊 BookingListViewController: 来自缓存: \(response.isCache)")
        
        bookingData = response.booking
        isFromCache = response.isCache
        
        hideError()
        tableView.reloadData()
        
        // 更新导航标题以显示数据来源
        title = isFromCache ? "预订详情 (缓存)" : "预订详情"
    }
    
    /**
     * 处理错误
     * @param error 错误对象
     */
    private func handleError(_ error: Error) {
        print("❌ BookingListViewController: 加载数据时出错 - \(error.localizedDescription)")
        
        errorLabel.text = "错误: \(error.localizedDescription)"
        showError()
    }
    
    /**
     * 更新加载状态
     * @param isLoading 是否正在加载
     */
    private func updateLoadingState(_ isLoading: Bool) {
        if isLoading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }
    
    /**
     * 显示错误信息
     * 隐藏表格视图，显示错误标签
     */
    private func showError() {
        errorLabel.isHidden = false
        tableView.isHidden = true
    }
    
    /**
     * 隐藏错误信息
     * 隐藏错误标签，显示表格视图
     */
    private func hideError() {
        errorLabel.isHidden = true
        tableView.isHidden = false
    }

}

extension BookingListViewController {
    func setupUI() {
        title = "预订详情"
        view.backgroundColor = .systemGroupedBackground
        
        // 添加导航栏刷新按钮
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshData)
        )
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        // 注册自定义单元格
        tableView.register(UINib(nibName: "BookingInfoCell", bundle: nil), forCellReuseIdentifier: "BookingInfoCell")
        tableView.register(UINib(nibName: "BookingSegmentCell", bundle: nil), forCellReuseIdentifier: "BookingSegmentCell")
        tableView.backgroundColor = .systemGroupedBackground
        
        // 为表格视图添加下拉刷新控件
        tableView.refreshControl = refreshControl
        
        // 添加子视图
        view.addSubview(loadingIndicator)
        view.addSubview(errorLabel)
        
        
        // 设置约束
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        errorLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    /**
     * 设置数据绑定
     * 订阅数据管理器的响应式更新
     */
    private func setupDataBinding() {
        // 监听数据管理器的数据更新
        dataManager.dataPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                self?.handleDataUpdate(response)
            }
            .store(in: &cancellables)
        
        // 监听刷新状态变化
        dataManager.isRefreshingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRefreshing in
                self?.updateLoadingState(isRefreshing)
            }
            .store(in: &cancellables)
    }
}

// MARK: - UITableViewDataSource


extension BookingListViewController: UITableViewDataSource {
    
    /**
     * 返回表格视图的节数
     * @param tableView 表格视图
     * @return Int 节数（预订信息节 + 航段节）
     */
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // 预订信息节 + 航段节
    }
    
    /**
     * 返回指定节的行数
     * @param tableView 表格视图
     * @param section 节索引
     * @return Int 行数
     */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let booking = bookingData else { return 0 }
        
        switch section {
        case 0: // 预订信息节
            return 1
        case 1: // 航段节
            return booking.segments.count
        default:
            return 0
        }
    }
    
    /**
     * 返回指定索引路径的单元格
     * @param tableView 表格视图
     * @param indexPath 索引路径
     * @return UITableViewCell 配置好的单元格
     */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let booking = bookingData else {
            return UITableViewCell()
        }
        
        switch indexPath.section {
        case 0: // 预订信息
            let cell = tableView.dequeueReusableCell(withIdentifier:"BookingInfoCell", for: indexPath) as! BookingInfoCell
            cell.configure(with: booking, isFromCache: isFromCache)
            return cell
            
        case 1: // 航段
            let cell = tableView.dequeueReusableCell(withIdentifier: "BookingSegmentCell", for: indexPath) as! BookingSegmentCell
            let segment = booking.segments[indexPath.row]
            cell.configure(with: segment)
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    /**
     * 返回指定节的标题
     * @param tableView 表格视图
     * @param section 节索引
     * @return String? 节标题
     */
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "预订信息"
        case 1:
            return "航段 (\(bookingData?.segments.count ?? 0))"
        default:
            return nil
        }
    }
}

// MARK: - UITableViewDelegate

/**
 * 表格视图代理扩展
 * 处理表格视图的交互和配置
 */
extension BookingListViewController: UITableViewDelegate {
    
    /**
     * 返回指定行的高度
     * @param tableView 表格视图
     * @param indexPath 索引路径
     * @return CGFloat 行高度
     */
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return UITableView.automaticDimension
        case 1:
            return 120
        default:
            return UITableView.automaticDimension
        }
    }
    
    /**
     * 处理行选择事件
     * @param tableView 表格视图
     * @param indexPath 索引路径
     */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            let segment = bookingData?.segments[indexPath.row]
            print("📱 BookingListViewController: 选择了航段 \(segment?.id ?? 0)")
        }
    }
}

