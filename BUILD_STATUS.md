# 🔍 Статус сборки RussianPay

## 📊 **Проверка сборки на GitHub**

### 1. **GitHub Actions Status**
Перейдите на: **[https://github.com/ahmed11551/RussianPay/actions](https://github.com/ahmed11551/RussianPay/actions)**

**Доступные Workflows:**
- ✅ **Code Quality** - проверка кода с SwiftLint
- ✅ **iOS Build and Test** - сборка и тестирование
- ✅ **Release** - создание релизов

### 2. **Последние коммиты:**
```
ab32c2a - Fix SwiftLint configuration and workflow path
54efae8 - Add GitHub Actions workflows for iOS build, testing, and releases
5ece6e3 - Add quick GitHub setup guide
7bfe184 - Add GitHub setup instructions
29a2e48 - Add .gitignore for iOS project
```

## 🚀 **Где можно запустить проект:**

### **1. На GitHub (Автоматически)**
- **Триггеры:** Push в main, Pull Request, Manual
- **Статус:** ✅ Настроено и работает
- **Артефакты:** IPA файлы, архивы приложения

### **2. Локально на macOS**
```bash
# Клонирование репозитория
git clone https://github.com/ahmed11551/RussianPay.git
cd RussianPay

# Открытие в Xcode
open RussianPay.xcodeproj

# Сборка через командную строку
xcodebuild -project RussianPay.xcodeproj -scheme RussianPay -configuration Debug

# Запуск тестов
xcodebuild -project RussianPay.xcodeproj -scheme RussianPay test
```

### **3. На Windows (Ограниченно)**
- ❌ **Xcode недоступен** на Windows
- ✅ **Можно:** Просматривать код, редактировать
- ✅ **Можно:** Запускать GitHub Actions
- ✅ **Можно:** Использовать VS Code с Swift расширением

### **4. В облаке (Рекомендуется)**
- **GitHub Codespaces** - полноценная среда разработки
- **MacStadium** - облачные Mac для сборки
- **MacinCloud** - аренда Mac в облаке

## 🔧 **Настройка для сборки:**

### **Требования:**
- macOS 12.0+ (для локальной сборки)
- Xcode 14.0+
- iOS 14.0+ (целевая платформа)
- Apple Developer Account (для подписи)

### **Bundle Identifier:**
```
com.russianpay.app
```

### **Поддерживаемые устройства:**
- iPhone (iOS 14.0+)
- iPad (iPadOS 14.0+)
- Apple Watch (watchOS 7.0+)

## 📱 **Результаты сборки:**

### **Артефакты GitHub Actions:**
- **RussianPay.xcarchive** - Архив приложения
- **RussianPay.ipa** - Установочный файл
- **Build logs** - Логи сборки

### **Скачивание артефактов:**
1. Перейдите в Actions → Последний запуск
2. Прокрутите вниз до "Artifacts"
3. Скачайте нужные файлы

## 🚨 **Устранение проблем:**

### **Если сборка не запускается:**
1. Проверьте статус в Actions
2. Убедитесь, что все файлы загружены
3. Проверьте конфигурацию workflow

### **Если есть ошибки SwiftLint:**
1. Проверьте файл `.swiftlint.yml`
2. Запустите `swiftlint lint` локально
3. Исправьте найденные проблемы

### **Если не собирается iOS:**
1. Проверьте версию Xcode
2. Убедитесь в правильности Bundle ID
3. Проверьте сертификаты разработчика

## 📞 **Поддержка:**

- **GitHub Issues:** [Создать issue](https://github.com/ahmed11551/RussianPay/issues)
- **Документация:** [README.md](README.md)
- **Инструкции:** [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md)

---

**RussianPay** - проверяем сборку и запускаем проект! 🇷🇺
