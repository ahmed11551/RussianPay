import Foundation
import UIKit
import AVFoundation
import CoreImage

/// Сервис для работы с QR-кодами в платежах
class QRCodeService: NSObject, ObservableObject {
    
    // MARK: - Properties
    @Published var isGenerating = false
    @Published var isScanning = false
    @Published var generatedQRCode: UIImage?
    @Published var scannedData: String?
    @Published var errorMessage: String?
    
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var qrCodeFrameView: UIView?
    
    // MARK: - QR Code Generation
    
    /// Генерация QR-кода для платежа
    func generatePaymentQR(amount: Double, merchantId: String, description: String? = nil) -> UIImage? {
        isGenerating = true
        errorMessage = nil
        
        // Создание данных для QR-кода
        let paymentData = createPaymentData(amount: amount, merchantId: merchantId, description: description)
        
        // Генерация QR-кода
        let qrCode = generateQRCode(from: paymentData)
        
        isGenerating = false
        return qrCode
    }
    
    /// Генерация QR-кода для получения платежа
    func generateReceiveQR(amount: Double, merchantId: String, description: String? = nil) -> UIImage? {
        isGenerating = true
        errorMessage = nil
        
        // Создание данных для получения платежа
        let receiveData = createReceiveData(amount: amount, merchantId: merchantId, description: description)
        
        // Генерация QR-кода
        let qrCode = generateQRCode(from: receiveData)
        
        isGenerating = false
        return qrCode
    }
    
    /// Генерация QR-кода для подключения к устройству
    func generateConnectionQR(deviceId: String, serviceType: String) -> UIImage? {
        isGenerating = true
        errorMessage = nil
        
        // Создание данных для подключения
        let connectionData = createConnectionData(deviceId: deviceId, serviceType: serviceType)
        
        // Генерация QR-кода
        let qrCode = generateQRCode(from: connectionData)
        
        isGenerating = false
        return qrCode
    }
    
    // MARK: - QR Code Scanning
    
    /// Запуск сканирования QR-кода
    func startScanning() -> AVCaptureVideoPreviewLayer? {
        guard !isScanning else { return videoPreviewLayer }
        
        isScanning = true
        errorMessage = nil
        
        // Создание сессии захвата
        captureSession = AVCaptureSession()
        
        guard let captureSession = captureSession else {
            errorMessage = "Не удалось создать сессию захвата"
            isScanning = false
            return nil
        }
        
        // Настройка устройства камеры
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            errorMessage = "Камера недоступна"
            isScanning = false
            return nil
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                errorMessage = "Не удалось добавить вход камеры"
                isScanning = false
                return nil
            }
        } catch {
            errorMessage = "Ошибка настройки камеры: \(error.localizedDescription)"
            isScanning = false
            return nil
        }
        
        // Настройка выхода для метаданных
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            errorMessage = "Не удалось добавить выход метаданных"
            isScanning = false
            return nil
        }
        
        // Создание слоя предварительного просмотра
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        
        // Запуск сессии
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
        
        return videoPreviewLayer
    }
    
    /// Остановка сканирования
    func stopScanning() {
        isScanning = false
        captureSession?.stopRunning()
        captureSession = nil
        videoPreviewLayer = nil
    }
    
    // MARK: - Private Methods
    
    private func createPaymentData(amount: Double, merchantId: String, description: String?) -> String {
        var data: [String: Any] = [
            "type": "payment",
            "amount": amount,
            "merchantId": merchantId,
            "timestamp": Date().timeIntervalSince1970,
            "currency": "RUB"
        ]
        
        if let description = description {
            data["description"] = description
        }
        
        // Добавление подписи
        data["signature"] = createSignature(for: data)
        
        return encodeToJSON(data)
    }
    
    private func createReceiveData(amount: Double, merchantId: String, description: String?) -> String {
        var data: [String: Any] = [
            "type": "receive",
            "amount": amount,
            "merchantId": merchantId,
            "timestamp": Date().timeIntervalSince1970,
            "currency": "RUB"
        ]
        
        if let description = description {
            data["description"] = description
        }
        
        // Добавление подписи
        data["signature"] = createSignature(for: data)
        
        return encodeToJSON(data)
    }
    
    private func createConnectionData(deviceId: String, serviceType: String) -> String {
        let data: [String: Any] = [
            "type": "connection",
            "deviceId": deviceId,
            "serviceType": serviceType,
            "timestamp": Date().timeIntervalSince1970,
            "signature": createSignature(for: [
                "deviceId": deviceId,
                "serviceType": serviceType
            ])
        ]
        
        return encodeToJSON(data)
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        guard let data = string.data(using: .utf8) else {
            errorMessage = "Не удалось преобразовать строку в данные"
            return nil
        }
        
        // Создание фильтра QR-кода
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            errorMessage = "Не удалось создать фильтр QR-кода"
            return nil
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        guard let outputImage = filter.outputImage else {
            errorMessage = "Не удалось сгенерировать QR-код"
            return nil
        }
        
        // Увеличение размера QR-кода
        let scaleX = 200.0 / outputImage.extent.size.width
        let scaleY = 200.0 / outputImage.extent.size.height
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // Преобразование в UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else {
            errorMessage = "Не удалось создать изображение QR-кода"
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func createSignature(for data: [String: Any]) -> String {
        // Создание подписи для данных
        let sortedKeys = data.keys.sorted()
        let signatureString = sortedKeys.map { "\($0)=\(data[$0] ?? "")" }.joined(separator: "&")
        
        // Простая подпись (в реальном приложении используйте криптографическую подпись)
        return signatureString.hashValue.description
    }
    
    private func encodeToJSON(_ data: [String: Any]) -> String {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            errorMessage = "Не удалось преобразовать данные в JSON"
            return ""
        }
        
        return jsonString
    }
    
    private func decodeFromJSON(_ jsonString: String) -> [String: Any]? {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }
        
        return json
    }
    
    // MARK: - Data Processing
    
    /// Обработка отсканированных данных
    func processScannedData(_ data: String) -> QRCodeData? {
        guard let json = decodeFromJSON(data) else {
            errorMessage = "Неверный формат данных QR-кода"
            return nil
        }
        
        guard let type = json["type"] as? String else {
            errorMessage = "Тип данных не определен"
            return nil
        }
        
        switch type {
        case "payment":
            return processPaymentData(json)
        case "receive":
            return processReceiveData(json)
        case "connection":
            return processConnectionData(json)
        default:
            errorMessage = "Неизвестный тип данных: \(type)"
            return nil
        }
    }
    
    private func processPaymentData(_ json: [String: Any]) -> QRCodeData? {
        guard let amount = json["amount"] as? Double,
              let merchantId = json["merchantId"] as? String,
              let timestamp = json["timestamp"] as? TimeInterval else {
            errorMessage = "Неверные данные платежа"
            return nil
        }
        
        let description = json["description"] as? String
        let signature = json["signature"] as? String
        
        return QRCodeData(
            type: .payment,
            amount: amount,
            merchantId: merchantId,
            description: description,
            timestamp: Date(timeIntervalSince1970: timestamp),
            signature: signature
        )
    }
    
    private func processReceiveData(_ json: [String: Any]) -> QRCodeData? {
        guard let amount = json["amount"] as? Double,
              let merchantId = json["merchantId"] as? String,
              let timestamp = json["timestamp"] as? TimeInterval else {
            errorMessage = "Неверные данные получения платежа"
            return nil
        }
        
        let description = json["description"] as? String
        let signature = json["signature"] as? String
        
        return QRCodeData(
            type: .receive,
            amount: amount,
            merchantId: merchantId,
            description: description,
            timestamp: Date(timeIntervalSince1970: timestamp),
            signature: signature
        )
    }
    
    private func processConnectionData(_ json: [String: Any]) -> QRCodeData? {
        guard let deviceId = json["deviceId"] as? String,
              let serviceType = json["serviceType"] as? String,
              let timestamp = json["timestamp"] as? TimeInterval else {
            errorMessage = "Неверные данные подключения"
            return nil
        }
        
        let signature = json["signature"] as? String
        
        return QRCodeData(
            type: .connection,
            amount: nil,
            merchantId: deviceId,
            description: serviceType,
            timestamp: Date(timeIntervalSince1970: timestamp),
            signature: signature
        )
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension QRCodeService: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = metadataObject.stringValue else {
            return
        }
        
        // Обработка отсканированных данных
        if let qrData = processScannedData(stringValue) {
            scannedData = stringValue
            stopScanning()
        }
    }
}

// MARK: - Supporting Types
struct QRCodeData {
    let type: QRCodeType
    let amount: Double?
    let merchantId: String
    let description: String?
    let timestamp: Date
    let signature: String?
    
    enum QRCodeType {
        case payment
        case receive
        case connection
    }
}

// MARK: - QR Code Generator
class QRCodeGenerator {
    
    /// Генерация QR-кода с настройками
    static func generateQRCode(
        from string: String,
        size: CGSize = CGSize(width: 200, height: 200),
        correctionLevel: String = "M"
    ) -> UIImage? {
        guard let data = string.data(using: .utf8) else { return nil }
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(correctionLevel, forKey: "inputCorrectionLevel")
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let scaleX = size.width / outputImage.extent.size.width
        let scaleY = size.height / outputImage.extent.size.height
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Генерация QR-кода с логотипом
    static func generateQRCodeWithLogo(
        from string: String,
        logo: UIImage?,
        size: CGSize = CGSize(width: 200, height: 200)
    ) -> UIImage? {
        guard let qrCode = generateQRCode(from: string, size: size) else { return nil }
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        // Рисование QR-кода
        qrCode.draw(in: CGRect(origin: .zero, size: size))
        
        // Рисование логотипа в центре
        if let logo = logo {
            let logoSize = CGSize(width: size.width * 0.2, height: size.height * 0.2)
            let logoRect = CGRect(
                x: (size.width - logoSize.width) / 2,
                y: (size.height - logoSize.height) / 2,
                width: logoSize.width,
                height: logoSize.height
            )
            logo.draw(in: logoRect)
        }
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return finalImage
    }
}

// MARK: - QR Code Scanner
class QRCodeScanner: NSObject, ObservableObject {
    
    @Published var isScanning = false
    @Published var scannedData: String?
    @Published var errorMessage: String?
    
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    func startScanning() -> AVCaptureVideoPreviewLayer? {
        guard !isScanning else { return videoPreviewLayer }
        
        isScanning = true
        errorMessage = nil
        
        captureSession = AVCaptureSession()
        
        guard let captureSession = captureSession else {
            errorMessage = "Не удалось создать сессию захвата"
            isScanning = false
            return nil
        }
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            errorMessage = "Камера недоступна"
            isScanning = false
            return nil
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                errorMessage = "Не удалось добавить вход камеры"
                isScanning = false
                return nil
            }
        } catch {
            errorMessage = "Ошибка настройки камеры: \(error.localizedDescription)"
            isScanning = false
            return nil
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            errorMessage = "Не удалось добавить выход метаданных"
            isScanning = false
            return nil
        }
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
        
        return videoPreviewLayer
    }
    
    func stopScanning() {
        isScanning = false
        captureSession?.stopRunning()
        captureSession = nil
        videoPreviewLayer = nil
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension QRCodeScanner: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = metadataObject.stringValue else {
            return
        }
        
        scannedData = stringValue
        stopScanning()
    }
}
