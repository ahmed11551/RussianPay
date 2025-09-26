# 🚀 GitHub Actions для RussianPay

Этот репозиторий настроен с автоматизированными процессами сборки, тестирования и релизов через GitHub Actions.

## 📋 Доступные Workflows

### 1. **iOS Build and Test** (`.github/workflows/ios-build.yml`)
- **Триггер**: Push в main/develop, Pull Request, Manual
- **Что делает**:
  - Собирает iOS проект в Debug и Release конфигурациях
  - Запускает unit тесты
  - Создает архив (.xcarchive)
  - Экспортирует IPA файл
  - Загружает артефакты сборки

### 2. **Code Quality** (`.github/workflows/code-quality.yml`)
- **Триггер**: Push в main/develop, Pull Request
- **Что делает**:
  - Проверяет код с помощью SwiftLint
  - Сканирует на наличие hardcoded секретов
  - Анализирует TODO/FIXME комментарии

### 3. **Release** (`.github/workflows/release.yml`)
- **Триггер**: Теги версий (v*), Manual
- **Что делает**:
  - Обновляет версию в Info.plist
  - Собирает релизную версию
  - Создает GitHub Release
  - Загружает архив приложения

## 🔧 Настройка

### Требования
- macOS runner (автоматически предоставляется GitHub)
- Xcode (latest-stable)
- SwiftLint (устанавливается автоматически)

### Секреты
Для полной функциональности добавьте в Settings → Secrets:
- `APPLE_ID` - Apple ID для подписи
- `APPLE_PASSWORD` - App-specific password
- `CERTIFICATE_P12` - Сертификат разработчика (base64)
- `CERTIFICATE_PASSWORD` - Пароль от сертификата
- `PROVISIONING_PROFILE` - Provisioning profile (base64)

## 📊 Статус сборки

[![iOS Build](https://github.com/ahmed11551/RussianPay/workflows/iOS%20Build%20and%20Test/badge.svg)](https://github.com/ahmed11551/RussianPay/actions)
[![Code Quality](https://github.com/ahmed11551/RussianPay/workflows/Code%20Quality/badge.svg)](https://github.com/ahmed11551/RussianPay/actions)

## 🚀 Использование

### Автоматическая сборка
1. Push в ветку `main` или `develop`
2. GitHub Actions автоматически запустит сборку
3. Проверьте статус в разделе "Actions"

### Ручная сборка
1. Перейдите в "Actions" → "iOS Build and Test"
2. Нажмите "Run workflow"
3. Выберите ветку и нажмите "Run workflow"

### Создание релиза
1. Создайте тег версии: `git tag v1.0.0`
2. Push тег: `git push origin v1.0.0`
3. GitHub Actions автоматически создаст релиз

## 📱 Артефакты

После успешной сборки доступны:
- **RussianPay.xcarchive** - Архив приложения
- **RussianPay.ipa** - Установочный файл
- **Build logs** - Логи сборки

## 🔍 Мониторинг

- **Actions**: Просмотр всех запусков
- **Artifacts**: Скачивание собранных файлов
- **Releases**: Готовые релизы приложения

## 🛠️ Локальная разработка

Для локальной сборки используйте:
```bash
# Установка зависимостей
pod install

# Сборка Debug
xcodebuild -project RussianPay.xcodeproj -scheme RussianPay -configuration Debug

# Сборка Release
xcodebuild -project RussianPay.xcodeproj -scheme RussianPay -configuration Release

# Запуск тестов
xcodebuild -project RussianPay.xcodeproj -scheme RussianPay test
```

## 📞 Поддержка

При проблемах с GitHub Actions:
1. Проверьте логи в разделе "Actions"
2. Убедитесь, что все секреты настроены
3. Проверьте совместимость версий Xcode
4. Создайте Issue с описанием проблемы

---

**RussianPay** - автоматизированная сборка для iOS! 🇷🇺
