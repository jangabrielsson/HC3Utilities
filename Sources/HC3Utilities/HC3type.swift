
//
//  HC3types.swift
//  Test
//
//  Created by Jan Gabrielsson on 2023-08-17.
//

import Foundation
//import OptionallyDecodable // https://github.com/idrougge/OptionallyDecodable

// MARK: - Encode/decode helpers

public extension HC3Utilities {
    enum types {
        public class JSONNull: Codable, Hashable {
            
            public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
                return true
            }
            
            public var hashValue: Int {
                return 0
            }
            
            public func hash(into hasher: inout Hasher) {
                // No-op
            }
            
            public init() {}
            
            public required init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if !container.decodeNil() {
                    throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
                }
            }
            
            public func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encodeNil()
            }
        }
        
        class JSONCodingKey: CodingKey, Equatable {
            let key: String
            
            static func == (lhs: JSONCodingKey, rhs: JSONCodingKey) -> Bool {
                return (lhs.key == rhs.key)
            }
            
            required init?(intValue: Int) {
                return nil
            }
            
            required init?(stringValue: String) {
                key = stringValue
            }
            
            var intValue: Int? {
                return nil
            }
            
            var stringValue: String {
                return key
            }
        }
        
        public class JSONAny: Codable {
            
            let value: Any
            
            static func decodingError(forCodingPath codingPath: [CodingKey]) -> DecodingError {
                let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode JSONAny")
                return DecodingError.typeMismatch(JSONAny.self, context)
            }
            
            static func encodingError(forValue value: Any, codingPath: [CodingKey]) -> EncodingError {
                let context = EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode JSONAny")
                return EncodingError.invalidValue(value, context)
            }
            
            static func decode(from container: SingleValueDecodingContainer) throws -> Any {
                if let value = try? container.decode(Bool.self) {
                    return value
                }
                if let value = try? container.decode(Int64.self) {
                    return value
                }
                if let value = try? container.decode(Double.self) {
                    return value
                }
                if let value = try? container.decode(String.self) {
                    return value
                }
                if container.decodeNil() {
                    return JSONNull()
                }
                throw decodingError(forCodingPath: container.codingPath)
            }
            
            static func decode(from container: inout UnkeyedDecodingContainer) throws -> Any {
                if let value = try? container.decode(Bool.self) {
                    return value
                }
                if let value = try? container.decode(Int64.self) {
                    return value
                }
                if let value = try? container.decode(Double.self) {
                    return value
                }
                if let value = try? container.decode(String.self) {
                    return value
                }
                if let value = try? container.decodeNil() {
                    if value {
                        return JSONNull()
                    }
                }
                if var container = try? container.nestedUnkeyedContainer() {
                    return try decodeArray(from: &container)
                }
                if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self) {
                    return try decodeDictionary(from: &container)
                }
                throw decodingError(forCodingPath: container.codingPath)
            }
            
            static func decode(from container: inout KeyedDecodingContainer<JSONCodingKey>, forKey key: JSONCodingKey) throws -> Any {
                if let value = try? container.decode(Bool.self, forKey: key) {
                    return value
                }
                if let value = try? container.decode(Int64.self, forKey: key) {
                    return value
                }
                if let value = try? container.decode(Double.self, forKey: key) {
                    return value
                }
                if let value = try? container.decode(String.self, forKey: key) {
                    return value
                }
                if let value = try? container.decodeNil(forKey: key) {
                    if value {
                        return JSONNull()
                    }
                }
                if var container = try? container.nestedUnkeyedContainer(forKey: key) {
                    return try decodeArray(from: &container)
                }
                if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key) {
                    return try decodeDictionary(from: &container)
                }
                throw decodingError(forCodingPath: container.codingPath)
            }
            
            static func decodeArray(from container: inout UnkeyedDecodingContainer) throws -> [Any] {
                var arr: [Any] = []
                while !container.isAtEnd {
                    let value = try decode(from: &container)
                    arr.append(value)
                }
                return arr
            }
            
            static func decodeDictionary(from container: inout KeyedDecodingContainer<JSONCodingKey>) throws -> [String: Any] {
                var dict = [String: Any]()
                for key in container.allKeys {
                    let value = try decode(from: &container, forKey: key)
                    dict[key.stringValue] = value
                }
                return dict
            }
            
            static func encode(to container: inout UnkeyedEncodingContainer, array: [Any]) throws {
                for value in array {
                    if let value = value as? Bool {
                        try container.encode(value)
                    } else if let value = value as? Int64 {
                        try container.encode(value)
                    } else if let value = value as? Double {
                        try container.encode(value)
                    } else if let value = value as? String {
                        try container.encode(value)
                    } else if value is JSONNull {
                        try container.encodeNil()
                    } else if let value = value as? [Any] {
                        var container = container.nestedUnkeyedContainer()
                        try encode(to: &container, array: value)
                    } else if let value = value as? [String: Any] {
                        var container = container.nestedContainer(keyedBy: JSONCodingKey.self)
                        try encode(to: &container, dictionary: value)
                    } else {
                        throw encodingError(forValue: value, codingPath: container.codingPath)
                    }
                }
            }
            
            static func encode(to container: inout KeyedEncodingContainer<JSONCodingKey>, dictionary: [String: Any]) throws {
                for (key, value) in dictionary {
                    let key = JSONCodingKey(stringValue: key)!
                    if let value = value as? Bool {
                        try container.encode(value, forKey: key)
                    } else if let value = value as? Int64 {
                        try container.encode(value, forKey: key)
                    } else if let value = value as? Double {
                        try container.encode(value, forKey: key)
                    } else if let value = value as? String {
                        try container.encode(value, forKey: key)
                    } else if value is JSONNull {
                        try container.encodeNil(forKey: key)
                    } else if let value = value as? [Any] {
                        var container = container.nestedUnkeyedContainer(forKey: key)
                        try encode(to: &container, array: value)
                    } else if let value = value as? [String: Any] {
                        var container = container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
                        try encode(to: &container, dictionary: value)
                    } else {
                        throw encodingError(forValue: value, codingPath: container.codingPath)
                    }
                }
            }
            
            static func encode(to container: inout SingleValueEncodingContainer, value: Any) throws {
                if let value = value as? Bool {
                    try container.encode(value)
                } else if let value = value as? Int64 {
                    try container.encode(value)
                } else if let value = value as? Double {
                    try container.encode(value)
                } else if let value = value as? String {
                    try container.encode(value)
                } else if value is JSONNull {
                    try container.encodeNil()
                } else {
                    throw encodingError(forValue: value, codingPath: container.codingPath)
                }
            }
            
            public required init(from decoder: Decoder) throws {
                if var arrayContainer = try? decoder.unkeyedContainer() {
                    self.value = try JSONAny.decodeArray(from: &arrayContainer)
                } else if var container = try? decoder.container(keyedBy: JSONCodingKey.self) {
                    self.value = try JSONAny.decodeDictionary(from: &container)
                } else {
                    let container = try decoder.singleValueContainer()
                    self.value = try JSONAny.decode(from: container)
                }
            }
            
            public func encode(to encoder: Encoder) throws {
                if let arr = self.value as? [Any] {
                    var container = encoder.unkeyedContainer()
                    try JSONAny.encode(to: &container, array: arr)
                } else if let dict = self.value as? [String: Any] {
                    var container = encoder.container(keyedBy: JSONCodingKey.self)
                    try JSONAny.encode(to: &container, dictionary: dict)
                } else {
                    var container = encoder.singleValueContainer()
                    try JSONAny.encode(to: &container, value: self.value)
                }
            }
        }
        
        // MARK: - QuickAppVariable
        public struct QuickAppVariable: Codable, Equatable {
            var name: String
            var value: JSONAny
            
            public static func == (lhs: QuickAppVariable, rhs: QuickAppVariable) -> Bool {
                return lhs.name == rhs.name
            }
            
        }
        
        // MARK: - FavoritePosition
        public struct FavoritePosition: Codable, Hashable {
            var name, label: String?
            var value: Int?
        }
        
        // MARK: - Icon
        public struct Icon: Codable, Hashable {
            var path, source, overlay: String?
        }
        
        // MARK: - UICallbacks
        public struct UICallbacks : Codable, Hashable {
            var callback, eventType, name : String
        }
        
        // MARK: - DeviceParameter
        public struct DeviceParameter : Codable, Hashable {
            var lastReportedValue, size, lastSetValue, id, value: Int?
            var readyOnly,setDefault : Bool?
        }
        
        // MARK: - CentralSceneSupport
        public struct CentralSceneSupport : Codable, Hashable {
            var keyAttributes : [String]
            var keyId : Int
        }
        
        // MARK: - Value
        public enum Value: Codable, Hashable {
            case bool(Bool)
            case integer(Int)
            case string(String)
            case double(Double)
            
            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let x = try? container.decode(Bool.self) {
                    self = .bool(x)
                    return
                }
                if let x = try? container.decode(Int.self) {
                    self = .integer(x)
                    return
                }
                if let x = try? container.decode(Double.self) {
                    self = .double(x)
                    return
                }
                if let x = try? container.decode(String.self) {
                    self = .string(x)
                    return
                }
                throw DecodingError.typeMismatch(Value.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for Value"))
            }
            
            public func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .bool(let x):
                    try container.encode(x)
                case .integer(let x):
                    try container.encode(x)
                case .double(let x):
                    try container.encode(x)
                case .string(let x):
                    try container.encode(x)
                }
            }
            
            func getInt() -> Int {
                switch self {
                case .integer(let num):
                    return num
                default:
                    return 0
                }
            }
            
            func getDouble() -> Double {
                switch self {
                case .double(let num):
                    return num
                default:
                    return 0
                }
            }
            
            func getBool() -> Bool {
                switch self {
                case .bool(let b):
                    return b
                default:
                    return false
                }
            }
            
            func getString() -> String {
                switch self {
                case .string(let str):
                    return str
                default:
                    return ""
                }
            }
            
        }
        
        
        // MARK: - Power
        public enum Power: Codable, Hashable {
            case bool(Bool)
            case double(Double)
            
            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let x = try? container.decode(Bool.self) {
                    self = .bool(x)
                    return
                }
                if let x = try? container.decode(Double.self) {
                    self = .double(x)
                    return
                }
                throw DecodingError.typeMismatch(Power.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for Power"))
            }
            
            public func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .bool(let x):
                    try container.encode(x)
                case .double(let x):
                    try container.encode(x)
                }
            }
        }
        
        // MARK: - Properties
        public struct Properties: Codable {
            var alarmLevel : Int?
            var alarmType : Int?
            var armed : Bool?
            //var zwaveResources [ResourceTypeDto{...}
            // example: OrderedMap { "name": "MultilevelSensor", "type": 1, "scales": List [ 3 ], "rateType": 1 }]
            var associationMode : Int?
            var availableDoorLockModes : [String]?
            // Enum:
            // [ Unsecured, UnsecuredWithTimeout, UnsecuredFromInside, UnsecuredFromInsideWithTimeout, UnsecuredFromOutside, UnsecuredFromOutsideWithTimeout, Unknown, Secured ]
            var availablePositions : [[String : String]]?
            var availableScenes : [[String: Int]]?
            var batteryLevel : Int?
            var batteryLowNotification : Bool?
            // var blackBox BlackBoxDto{...}
            // example: OrderedMap { "fileName": "fileName", "state": "Empty", "timestamp": 0 }
            var buttonHold : Int?
            var buttonsType : String?
            var currentHumidity : Int?
            var showFreezeAlarm : Bool?
            var showFireAlarm : Bool?
            var buttonType : Int?
            // anyOf -> String, Int?
            var motorInversion : Bool?
            var steeringInversion : Bool?
            var movingUpTime : Int?
            var movingDownTime : Int?
            var slatsRotationTime : Int?
            var virtualBottomLimit : Int?
            var cameraType : Int?
            var categories : [String]?
            var calibrationVariants : [String]?
            // example: List [ "dimmerCalibrationWithBypass", "dimmerCalibrationWithoutBypass" ]
            var calibrated : Bool?
            var centralSceneSupport : [CentralSceneSupport]?
            var channel1 : String?
            var channel2 : String?
            var channel3 : String?
            var channel4 : String?
            var climateZoneHash : String?
            var climateZoneId : Int?
            var configured : Bool?
            var dead : Bool?
            var position : String?
            var port : Double?
            var strategy : String?
            var deadReason : String?
            var defInterval : Int?
            var defaultPartyTime : Int?
            var defaultTone : Int?
            var defaultWateringTime : Int?
            var deviceControlType : Int?
            var deviceRole : String?
            var supportedDeviceRoles : [String]?
            var deviceGroup : [Int]?
            var deviceGroupMaster : Int?
            var deviceIcon : Int?
            var devices : [Int]?
            var devicesInitializationProcess : String?
            var DeviceUID : String?
            var displayOnMainPage : Int?
            var doorLockMode : String?
            var emailNotificationID : Int?
            var emailNotificationType : Int?
            var endPointId : Int?
            var externalSensorConnected : Bool?
            var favoritePositionsNativeSupport : Bool?
            var favoritePositions : [FavoritePosition]?
            var fgrgbwMode : String?
            var fidUuid : String?
            var fidLastSynchronizationTimestamp : Int?
            var fidRole : String?
            //var firmwareUpdate DeviceFirmwareUpdateDto{...}
            // example: OrderedMap { "updateVersion": "updateVersion", "progress": 5, "info": "info", "status": "status" }
            var gatewayId : String?
            var humidityThreshold : Int?
            var httpsEnabled : Bool?
            var icon : Icon?
            var includeInEnergyPanel : Bool?
            //var inputToChannelMap DeviceInputToChannelMapDto{...}
            // example: OrderedMap { "close": List [ 4 ], "open": List [], "partialOpen1": List [], "step": List [ 1, 3 ], "stop": List [ 5 ] }
            var ip : String?
            var isLight : Bool?
            var jpgPath : String?
            var lastBreached : Double?
            var lastHealthy : Double?
            var lastLoggedUser : Double?
            var lastModerate : Double?
            var liliOffCommand : String?
            var liliOnCommand : String?
            var linkedDeviceType : String?
            var localProtectionState : Int?
            var localProtectionSupport : Int?
            var log : String?
            var logTemp : String?
            var manufacturer : String?
            var markAsDead : Bool?
            var maxInterval : Int?
            var maxUsers : Int?
            var maxValue : Int?
            var maxVoltage : Int?
            var minInterval : Int?
            var minValue : Int?
            var minVoltage : Int?
            var mjpgPath : String?
            var mode : Double?
            var model : String?
            var moveDownPath : String?
            var moveLeftPath : String?
            var moveRightPath : String?
            var moveStopPath : String?
            var moveUpPath : String?
            var networkStatus : String?
            var niceId : Int?
            var niceProtocol : String?
            var nodeId : Int?
            var numberOfSupportedButtons : Int?
            var offset : Int?
            var output1Id : Double?
            var output2Id : Double?
            var panicMode : Bool?
            var parameters : [DeviceParameter]?
            var parametersTemplate : Value?
            var password : String?
            var pendingActions : Bool?
            var pollingDeadDevice : Bool?
            var pollingInterval : Double?
            var pollingTimeSec : Int?
            var power : Power?
            var productInfo : String?
            var protectionExclusiveControl : Int?
            //        //var protectionExclusiveControlSupport : Number?
            var protectionState : Int?
            var protectionTimeout : Double?
            var protectionTimeoutSupport : Bool?
            var pushNotificationID : Int?
            var pushNotificationType : Double?
            var rateType : String?
            var refreshTime : Int?
            var remoteId : Int?
            var remoteGatewayId : Int?
            var RFProtectionState : Int?
            var RFProtectionSupport : Int?
            var rtspPath : String?
            var rtspPort : Int?
            var saveLogs : Bool?
            var slatsRange : Int?
            var slatsRangeMin : Int?
            var slatsRangeMax : Int?
            var storeEnergyData : Bool?
            var saveToEnergyPanel : Bool?
            // var schedules [...]
            var securityLevel : String?
            var securitySchemes : [String]?
            var sendStopAfterMove : Bool?
            var serialNumber : String?
            var showEnergy : Bool?
            var state : Value?
            // anyOf -> Bool, Int, String
            var energy : Double?
            var sipUserPassword : String?
            var sipDisplayName : String?
            var sipUserID : String?
            var sipUserEnabled : Bool?
            var smsNotificationID : Int?
            var smsNotificationType : Double?
            var softwareVersion : String?
            var stepInterval : Double?
            var supportedThermostatFanModes : [String]?
            var supportedThermostatModes : [String]?
            // var supportedTones [{...}]
            var tamperMode : String?
            var targetLevel : Double?
            var targetLevelDry : Double?
            var targetLevelHumidify : Double?
            var targetLevelMax : Double?
            var targetLevelMin : Double?
            var targetLevelStep : Double?
            var targetLevelTimestamp : Double?
            var thermostatFanMode : String?
            var thermostatFanOff : Bool?
            var thermostatFanState : String?
            var thermostatMode : String?
            var thermostatModeFuture : String?
            var thermostatOperatingState : String?
            var thermostatModeManufacturerData : [Int]?
            var thermostatState : String?
            var powerConsumption : Double?
            var timestamp : Int?
            var tone : Int?
            var unit : String?
            var updateVersion : String?
            var useTemplate : Bool?
            //var userCodes [UserCodeDto{...}
            // example: OrderedMap { "id": 0, "name": "User 1", "status": "Occupied", "update": "Ok" }]
            var userDescription : String?
            var username : String?
            var wakeUpTime : Double?
            var zwaveCompany : String?
            var zwaveInfo : String?
            // var zwaveScheduleClimatePanelCompatibileBlocks [{...}]
            var zwaveVersion : String?
            var value : Value?
            // anyOf -> Int, Bool, String
            var viewLayout : JSONAny?
            var volume : Int?
            var mainFunction : String?
            var uiCallbacks : [UICallbacks]?
            var quickAppVariables : [QuickAppVariable]?
            // var colorComponents {
            var walliOperatingMode : String?
            var ringUpperColor : String?
            var ringBottomColor : String?
            var ringBrightness : Double?
            var ringLightMode : String?
            var ringConfirmingTime : Double?
            var encrypted : Bool?
        }
        
        public struct Device : Codable, Equatable {
            var id: Int
            var name: String
            var roomID: Int
            var view: [JSONAny]
            var type, baseType: String
            var interfaces: [String]
            var enabled, visible, isPlugin: Bool
            var parentId: Int
            var viewXml, hasUIView, configXml: Bool
            var properties: Properties
            var actions: [String: Int]
            var remoteGatewayId: Int?
            var created, modified, sortOrder: Int
            
            public static func == (lhs: Device, rhs: Device) -> Bool {
                return (lhs.id == rhs.id)
            }
        }
        
        // MARK: - PropertiesSimple
        public struct PropertiesSimple: Codable {
            var armed : Bool?
            var batteryLevel : Int?
            var categories : [String]?
            //var centralSceneSupport : [CentralSceneSupport]?
            var dead : Bool?
            var position : String?
            var deadReason : String?
            var deviceControlType : Int?
            var deviceRole : String?
            var icon : Icon?
            var includeInEnergyPanel : Bool?
            var isLight : Bool?
            var jpgPath : String?
            var lastBreached : Double?
            var lastHealthy : Double?
            var lastLoggedUser : Double?
            var log : String?
            var logTemp : String?
            var manufacturer : String?
            var markAsDead : Bool?
            var model : String?
            var power : Power?
            var productInfo : String?
            var rateType : String?
            var storeEnergyData : Bool?
            var saveToEnergyPanel : Bool?
            var serialNumber : String?
            var showEnergy : Bool?
            var state : Value?
            var energy : Double?
            var softwareVersion : String?
            var thermostatFanMode : String?
            var thermostatFanOff : Bool?
            var thermostatFanState : String?
            var thermostatMode : String?
            var thermostatModeFuture : String?
            var thermostatOperatingState : String?
            var thermostatModeManufacturerData : [Int]?
            var thermostatState : String?
            var powerConsumption : Double?
            var timestamp : Int?
            var unit : String?
            var updateVersion : String?
            var useTemplate : Bool?
            var userDescription : String?
            var wakeUpTime : Double?
            var zwaveCompany : String?
            var zwaveInfo : String?
            var zwaveVersion : String?
            var value : Value?
            var volume : Int?
            var uiCallbacks : [UICallbacks]?
            var quickAppVariables : [QuickAppVariable]?
        }
        
        public struct DeviceSimple : Codable, Equatable {
            var id: Int
            var name: String
            var roomID: Int
            var view: [JSONAny]
            var type, baseType: String
            var interfaces: [String]
            var enabled, visible, isPlugin: Bool
            var parentId: Int
            var viewXml, hasUIView, configXml: Bool
            var properties: PropertiesSimple
            var actions: [String: Int]
            var remoteGatewayId: Int?
            var created, modified, sortOrder: Int
            
            public static func == (lhs: DeviceSimple, rhs: DeviceSimple) -> Bool {
                return (lhs.id == rhs.id)
            }
        }
        
        
        // MARK: - GlobalVariable
        public struct GlobalVariable: Codable, Hashable {
            var name, value: String
            var readOnly, isEnum: Bool
            var enumValues: [String]
            var created, modified: Int
        }
    }
}
