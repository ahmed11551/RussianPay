import XCTest

class RussianPayUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - App Launch Tests
    
    func testAppLaunch() throws {
        XCTAssertTrue(app.waitForExistence(timeout: 5.0))
    }
    
    func testMainTabBar() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5.0))
        
        // Проверка наличия всех вкладок
        let cardsTab = tabBar.buttons["Карты"]
        let nfcTab = tabBar.buttons["NFC"]
        let applePayTab = tabBar.buttons["Apple Pay"]
        let transactionsTab = tabBar.buttons["Транзакции"]
        let settingsTab = tabBar.buttons["Настройки"]
        
        XCTAssertTrue(cardsTab.exists)
        XCTAssertTrue(nfcTab.exists)
        XCTAssertTrue(applePayTab.exists)
        XCTAssertTrue(transactionsTab.exists)
        XCTAssertTrue(settingsTab.exists)
    }
    
    // MARK: - Cards Tab Tests
    
    func testCardsTab() throws {
        let cardsTab = app.tabBars.buttons["Карты"]
        cardsTab.tap()
        
        // Проверка заголовка
        let navigationBar = app.navigationBars["Мои карты"]
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5.0))
        
        // Проверка кнопки добавления карты
        let addButton = navigationBar.buttons["plus"]
        XCTAssertTrue(addButton.exists)
    }
    
    func testAddCardFlow() throws {
        let cardsTab = app.tabBars.buttons["Карты"]
        cardsTab.tap()
        
        let addButton = app.navigationBars["Мои карты"].buttons["plus"]
        addButton.tap()
        
        // Проверка открытия формы добавления карты
        let addCardView = app.navigationBars["Добавить карту"]
        XCTAssertTrue(addCardView.waitForExistence(timeout: 5.0))
        
        // Проверка полей формы
        let cardNumberField = app.textFields["1234 5678 9012 3456"]
        let cardholderField = app.textFields["IVAN IVANOV"]
        let cvvField = app.secureTextFields["123"]
        
        XCTAssertTrue(cardNumberField.exists)
        XCTAssertTrue(cardholderField.exists)
        XCTAssertTrue(cvvField.exists)
        
        // Заполнение формы
        cardNumberField.tap()
        cardNumberField.typeText("1234567890123456")
        
        cardholderField.tap()
        cardholderField.typeText("IVAN IVANOV")
        
        cvvField.tap()
        cvvField.typeText("123")
        
        // Проверка кнопки сохранения
        let saveButton = app.navigationBars["Добавить карту"].buttons["Сохранить"]
        XCTAssertTrue(saveButton.exists)
        XCTAssertTrue(saveButton.isEnabled)
    }
    
    // MARK: - NFC Tab Tests
    
    func testNFCTab() throws {
        let nfcTab = app.tabBars.buttons["NFC"]
        nfcTab.tap()
        
        // Проверка заголовка
        let navigationBar = app.navigationBars["NFC Эмулятор"]
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5.0))
        
        // Проверка статуса NFC
        let statusView = app.otherElements.containing(.staticText, identifier: "Статус NFC").firstMatch
        XCTAssertTrue(statusView.exists)
        
        // Проверка кнопок управления
        let startButton = app.buttons["Запустить"]
        let stopButton = app.buttons["Остановить"]
        
        XCTAssertTrue(startButton.exists)
        XCTAssertTrue(stopButton.exists)
    }
    
    func testNFCEmulation() throws {
        let nfcTab = app.tabBars.buttons["NFC"]
        nfcTab.tap()
        
        let startButton = app.buttons["Запустить"]
        startButton.tap()
        
        // Проверка изменения состояния
        let stopButton = app.buttons["Остановить"]
        XCTAssertTrue(stopButton.waitForExistence(timeout: 5.0))
        
        // Остановка эмуляции
        stopButton.tap()
        
        // Проверка возврата к начальному состоянию
        XCTAssertTrue(startButton.waitForExistence(timeout: 5.0))
    }
    
    // MARK: - Apple Pay Tab Tests
    
    func testApplePayTab() throws {
        let applePayTab = app.tabBars.buttons["Apple Pay"]
        applePayTab.tap()
        
        // Проверка заголовка
        let navigationBar = app.navigationBars["Apple Pay"]
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5.0))
        
        // Проверка статуса Apple Pay
        let statusView = app.otherElements.containing(.staticText, identifier: "Apple Pay").firstMatch
        XCTAssertTrue(statusView.exists)
        
        // Проверка формы платежа
        let amountField = app.textFields["0.00"]
        let merchantField = app.textFields["com.russianpay.merchant"]
        let descriptionField = app.textFields["Товары и услуги"]
        
        XCTAssertTrue(amountField.exists)
        XCTAssertTrue(merchantField.exists)
        XCTAssertTrue(descriptionField.exists)
    }
    
    func testApplePayPayment() throws {
        let applePayTab = app.tabBars.buttons["Apple Pay"]
        applePayTab.tap()
        
        // Заполнение формы платежа
        let amountField = app.textFields["0.00"]
        amountField.tap()
        amountField.typeText("100.00")
        
        let descriptionField = app.textFields["Товары и услуги"]
        descriptionField.tap()
        descriptionField.typeText("Test Payment")
        
        // Проверка кнопки оплаты
        let payButton = app.buttons["Оплатить через Apple Pay"]
        XCTAssertTrue(payButton.exists)
        XCTAssertTrue(payButton.isEnabled)
    }
    
    // MARK: - Transactions Tab Tests
    
    func testTransactionsTab() throws {
        let transactionsTab = app.tabBars.buttons["Транзакции"]
        transactionsTab.tap()
        
        // Проверка заголовка
        let navigationBar = app.navigationBars["Транзакции"]
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5.0))
        
        // Проверка пустого состояния
        let emptyView = app.otherElements.containing(.staticText, identifier: "Нет транзакций").firstMatch
        XCTAssertTrue(emptyView.exists)
    }
    
    // MARK: - Settings Tab Tests
    
    func testSettingsTab() throws {
        let settingsTab = app.tabBars.buttons["Настройки"]
        settingsTab.tap()
        
        // Проверка заголовка
        let navigationBar = app.navigationBars["Настройки"]
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5.0))
        
        // Проверка секций настроек
        let profileSection = app.otherElements.containing(.staticText, identifier: "Профиль").firstMatch
        let nfcSection = app.otherElements.containing(.staticText, identifier: "NFC").firstMatch
        let securitySection = app.otherElements.containing(.staticText, identifier: "Безопасность").firstMatch
        
        XCTAssertTrue(profileSection.exists)
        XCTAssertTrue(nfcSection.exists)
        XCTAssertTrue(securitySection.exists)
    }
    
    func testSettingsFields() throws {
        let settingsTab = app.tabBars.buttons["Настройки"]
        settingsTab.tap()
        
        // Проверка поля имени пользователя
        let usernameField = app.textFields["Имя пользователя"]
        XCTAssertTrue(usernameField.exists)
        
        // Проверка переключателей
        let autoConnectToggle = app.switches["Автоподключение"]
        let debugModeToggle = app.switches["Режим отладки"]
        
        XCTAssertTrue(autoConnectToggle.exists)
        XCTAssertTrue(debugModeToggle.exists)
        
        // Проверка кнопок
        let changeKeysButton = app.buttons["Сменить ключи"]
        let clearDataButton = app.buttons["Очистить данные"]
        
        XCTAssertTrue(changeKeysButton.exists)
        XCTAssertTrue(clearDataButton.exists)
    }
    
    // MARK: - Payment Flow Tests
    
    func testPaymentFlow() throws {
        // Переход на вкладку карт
        let cardsTab = app.tabBars.buttons["Карты"]
        cardsTab.tap()
        
        // Добавление карты
        let addButton = app.navigationBars["Мои карты"].buttons["plus"]
        addButton.tap()
        
        // Заполнение формы карты
        let cardNumberField = app.textFields["1234 5678 9012 3456"]
        cardNumberField.tap()
        cardNumberField.typeText("1234567890123456")
        
        let cardholderField = app.textFields["IVAN IVANOV"]
        cardholderField.tap()
        cardholderField.typeText("IVAN IVANOV")
        
        let cvvField = app.secureTextFields["123"]
        cvvField.tap()
        cvvField.typeText("123")
        
        // Сохранение карты
        let saveButton = app.navigationBars["Добавить карту"].buttons["Сохранить"]
        saveButton.tap()
        
        // Переход на вкладку Apple Pay
        let applePayTab = app.tabBars.buttons["Apple Pay"]
        applePayTab.tap()
        
        // Заполнение формы платежа
        let amountField = app.textFields["0.00"]
        amountField.tap()
        amountField.typeText("100.00")
        
        let descriptionField = app.textFields["Товары и услуги"]
        descriptionField.tap()
        descriptionField.typeText("Test Payment")
        
        // Проверка кнопки оплаты
        let payButton = app.buttons["Оплатить через Apple Pay"]
        XCTAssertTrue(payButton.isEnabled)
    }
    
    // MARK: - Navigation Tests
    
    func testTabNavigation() throws {
        let tabBar = app.tabBars.firstMatch
        
        // Тестирование навигации между вкладками
        let tabs = ["Карты", "NFC", "Apple Pay", "Транзакции", "Настройки"]
        
        for tabName in tabs {
            let tab = tabBar.buttons[tabName]
            tab.tap()
            
            // Проверка, что вкладка активна
            XCTAssertTrue(tab.isSelected)
            
            // Небольшая пауза для стабилизации UI
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabels() throws {
        let cardsTab = app.tabBars.buttons["Карты"]
        cardsTab.tap()
        
        // Проверка accessibility labels
        let addButton = app.navigationBars["Мои карты"].buttons["plus"]
        XCTAssertTrue(addButton.label.contains("plus") || addButton.label.contains("добавить"))
    }
    
    // MARK: - Performance Tests
    
    func testAppLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }
    
    func testTabSwitchingPerformance() throws {
        let tabBar = app.tabBars.firstMatch
        
        measure {
            for _ in 0..<10 {
                tabBar.buttons["Карты"].tap()
                tabBar.buttons["NFC"].tap()
                tabBar.buttons["Apple Pay"].tap()
                tabBar.buttons["Транзакции"].tap()
                tabBar.buttons["Настройки"].tap()
            }
        }
    }
}
