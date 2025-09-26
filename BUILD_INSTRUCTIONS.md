# 🚀 Инструкция по сборке RussianPay

## 📋 Требования

### Системные требования
- **macOS** 12.0 или новее
- **Xcode** 14.0 или новее
- **iOS SDK** 16.0 или новее
- **Swift** 5.7 или новее

### Устройства для тестирования
- **iPhone** 7 или новее (для NFC)
- **iPad** (6-го поколения) или новее
- **Apple Watch** Series 3 или новее (опционально)

## 🔧 Установка и настройка

### 1. Клонирование проекта
```bash
git clone https://github.com/yourusername/russianpay.git
cd russianpay
```

### 2. Открытие проекта в Xcode
```bash
open RussianPay.xcodeproj
```

### 3. Настройка Bundle Identifier
1. Выберите проект в навигаторе
2. Выберите target "RussianPay"
3. В разделе "General" измените "Bundle Identifier" на ваш уникальный идентификатор
4. Например: `com.yourcompany.russianpay`

### 4. Настройка команды разработки
1. В разделе "Signing & Capabilities"
2. Выберите вашу команду разработки (Development Team)
3. Убедитесь, что "Automatically manage signing" включено

### 5. Настройка разрешений
Убедитесь, что в `Info.plist` и `RussianPay.entitlements` настроены все необходимые разрешения:
- NFC Reader Usage
- Apple Pay
- Bluetooth
- Camera
- Face ID / Touch ID

## 🏗 Сборка проекта

### Debug сборка
```bash
# Через командную строку
xcodebuild build -scheme RussianPay -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 14'

# Или через Xcode
# Product → Build (⌘+B)
```

### Release сборка
```bash
# Через командную строку
xcodebuild build -scheme RussianPay -configuration Release -destination 'platform=iOS Simulator,name=iPhone 14'

# Или через Xcode
# Product → Archive
```

## 🧪 Тестирование

### Unit тесты
```bash
# Через командную строку
xcodebuild test -scheme RussianPay -destination 'platform=iOS Simulator,name=iPhone 14'

# Или через Xcode
# Product → Test (⌘+U)
```

### UI тесты
```bash
# Через командную строку
xcodebuild test -scheme RussianPayUITests -destination 'platform=iOS Simulator,name=iPhone 14'

# Или через Xcode
# Product → Test (⌘+U)
```

## 📱 Запуск на устройстве

### 1. Подключение устройства
1. Подключите iPhone/iPad к Mac через USB
2. Разблокируйте устройство
3. Доверьтесь компьютеру при появлении запроса

### 2. Выбор устройства
1. В Xcode выберите ваше устройство в списке устройств
2. Убедитесь, что устройство выбрано как destination

### 3. Запуск приложения
1. Нажмите кнопку "Run" (▶️) или ⌘+R
2. Дождитесь установки и запуска приложения

## 🔐 Настройка безопасности

### 1. NFC разрешения
Убедитесь, что в `Info.plist` добавлены:
```xml
<key>NFCReaderUsageDescription</key>
<string>RussianPay использует NFC для бесконтактных платежей</string>
```

### 2. Apple Pay настройки
В `RussianPay.entitlements` должны быть:
```xml
<key>com.apple.developer.payment-pass-provisioning</key>
<true/>
<key>com.apple.developer.payment-pass-library</key>
<true/>
```

### 3. Bluetooth разрешения
В `Info.plist`:
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>RussianPay использует Bluetooth для альтернативных способов связи</string>
```

## 🐛 Решение проблем

### Ошибка компиляции
1. Проверьте версию Xcode и iOS SDK
2. Очистите проект: Product → Clean Build Folder (⌘+Shift+K)
3. Перезапустите Xcode

### Ошибки подписи
1. Проверьте настройки команды разработки
2. Убедитесь, что Bundle Identifier уникален
3. Проверьте профили подписи в Apple Developer Portal

### Ошибки NFC
1. Убедитесь, что устройство поддерживает NFC
2. Проверьте настройки NFC в настройках устройства
3. Убедитесь, что приложение имеет необходимые разрешения

### Ошибки Apple Pay
1. Проверьте настройки Apple Pay в настройках устройства
2. Убедитесь, что добавлены карты в Wallet
3. Проверьте entitlements файл

## 📊 Производительность

### Оптимизация сборки
1. Используйте Release конфигурацию для финальной сборки
2. Включите оптимизации компилятора
3. Используйте профилирование для выявления узких мест

### Мониторинг
1. Используйте Instruments для профилирования
2. Мониторьте использование памяти
3. Проверяйте производительность криптографических операций

## 🚀 Развертывание

### App Store
1. Создайте архив: Product → Archive
2. Загрузите в App Store Connect
3. Настройте метаданные и скриншоты
4. Отправьте на ревью

### Ad Hoc
1. Создайте профиль Ad Hoc в Apple Developer Portal
2. Настройте подпись для Ad Hoc
3. Создайте архив и экспортируйте для Ad Hoc

### Enterprise
1. Создайте профиль Enterprise
2. Настройте подпись для Enterprise
3. Создайте архив и экспортируйте для Enterprise

## 📞 Поддержка

Если у вас возникли проблемы со сборкой:

1. **Проверьте логи** в Xcode Console
2. **Очистите проект** и попробуйте снова
3. **Обновите Xcode** до последней версии
4. **Создайте issue** в GitHub репозитории

## 🎉 Готово!

После успешной сборки вы сможете:
- ✅ Тестировать NFC эмулятор
- ✅ Использовать Apple Pay функции
- ✅ Работать с альтернативными протоколами
- ✅ Проводить безопасные платежи

**RussianPay** готов к использованию! 🇷🇺
