//
//  MainViewController.swift
//  CodeTesting01
//
//  由 郭嘉俊 创建于 2025/9/26.
//

import UIKit
/**
 * 主视图控制器
 * 应用的入口点，提供导航到预订列表的界面
 */
class MainViewController: BaseViewController {

    /**
     * 视图加载完成
     * 设置用户界面
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        setupUI()
    }
    

    
    /**
     * 显示预订列表按钮点击事件
     * 创建并展示预订列表视图控制器
     */
    @objc private func tappedShowBookingList() {
        self.navigationController?.pushViewController(BookingListViewController(), animated: true)
    }
    
    
    /// 运行数据管理器的测试并显示提示
    @objc private func tappedRunTest() {
        print("【MainViewController】: 正在运行数据管理器测试")
        print("【MainViewController】: ==================")
        TestingBookingDataManager.runTests()

        // 显示提示信息
        let alert = UIAlertController(
            title: "控制台 模拟 测试",
            message: "请查看控制台获取测试结果。测试正在后台运行。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
        print("【MainViewController】: ==================")
    }
    
    /// 运行演示
    @objc private func tappedRunDemo() {
        print("【MainViewController】: 正在运行数据管理器测试")
        print("【MainViewController】: ==================")
        TestingBookingDataManager.runDemo()
        // 显示提示信息
        let alert = UIAlertController(
            title: "演示运行中",
            message: "请查看控制台获取演示输出。演示正在后台运行。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
        print("【MainViewController】: ==================")
    }
    
    
    
    /*
     UI 部分
     */
    
    
    /// 创建UI
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        
        // 创建 跳转到预订列表的按钮
        let btn_showBookingList = self.createButton(title: "显示预订列表", bgColor: .systemBlue, action: #selector(tappedShowBookingList))
        let btn_dataTest = self.createButton(title: "Data Manager测试", bgColor: .systemRed, action: #selector(tappedRunTest))
        let btn_controlTest = self.createButton(title: "Control运行演示", bgColor: .systemGreen, action: #selector(tappedRunDemo))

        view.addSubview(btn_showBookingList)
        view.addSubview(btn_dataTest)
        view.addSubview(btn_controlTest)

        btn_showBookingList.snp.makeConstraints { make in
            make.width.equalTo(250)
            make.height.equalTo(50)
            make.center.equalToSuperview()
        }
        btn_dataTest.snp.makeConstraints { make in
            make.width.equalTo(250)
            make.height.equalTo(50)
            make.centerX.equalToSuperview()
            make.top.equalTo(btn_showBookingList.snp.bottom).offset(20)
        }
        btn_controlTest.snp.makeConstraints { make in
            make.width.equalTo(250)
            make.height.equalTo(50)
            make.centerX.equalToSuperview()
            make.top.equalTo(btn_dataTest.snp.bottom).offset(20)
        }
    }
    
    /// 快速创建按钮
    /// - Parameters:
    ///   - title: 标题
    ///   - bgColor: 背景色
    ///   - action: 事件
    private func createButton(title: String, bgColor: UIColor, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = bgColor
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
}
