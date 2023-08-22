
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
            public var name: String
            public var value: JSONAny
            
            public static func == (lhs: QuickAppVariable, rhs: QuickAppVariable) -> Bool {
                return lhs.name == rhs.name
            }
            
        }
        
        // MARK: - FavoritePosition
        public struct FavoritePosition: Codable, Hashable {
            public var name, label: String?
            public var value: Int?
        }
        
        // MARK: - Icon
        public struct Icon: Codable, Hashable {
            public var path, source, overlay: String?
        }
        
        // MARK: - UICallbacks
        public struct UICallbacks : Codable, Hashable {
            public var callback, eventType, name : String
        }
        
        // MARK: - DeviceParameter
        public struct DeviceParameter : Codable, Hashable {
            public var lastReportedValue, size, lastSetValue, id, value: Int?
            public var readyOnly,setDefault : Bool?
        }
        
        // MARK: - CentralSceneSupport
        public struct CentralSceneSupport : Codable, Hashable {
            public var keyAttributes : [String]
            public var keyId : Int
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
            
            public func getInt() -> Int {
                switch self {
                case .integer(let num):
                    return num
                default:
                    return 0
                }
            }
            
            public func getDouble() -> Double {
                switch self {
                case .double(let num):
                    return num
                default:
                    return 0
                }
            }
            
            public func getBool() -> Bool {
                switch self {
                case .bool(let b):
                    return b
                default:
                    return false
                }
            }
            
            public func getString() -> String {
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
            public var alarmLevel : Int?
            public var alarmType : Int?
            public var armed : Bool?
            //public var zwaveResources [ResourceTypeDto{...}
            // example: OrderedMap { "name": "MultilevelSensor", "type": 1, "scales": List [ 3 ], "rateType": 1 }]
            public var associationMode : Int?
            public var availableDoorLockModes : [String]?
            // Enum:
            // [ Unsecured, UnsecuredWithTimeout, UnsecuredFromInside, UnsecuredFromInsideWithTimeout, UnsecuredFromOutside, UnsecuredFromOutsideWithTimeout, Unknown, Secured ]
            public var availablePositions : [[String : String]]?
            public var availableScenes : [[String: Int]]?
            public var batteryLevel : Int?
            public var batteryLowNotification : Bool?
            // public var blackBox BlackBoxDto{...}
            // example: OrderedMap { "fileName": "fileName", "state": "Empty", "timestamp": 0 }
            public var buttonHold : Int?
            public var buttonsType : String?
            public var currentHumidity : Int?
            public var showFreezeAlarm : Bool?
            public var showFireAlarm : Bool?
            public var buttonType : Int?
            // anyOf -> String, Int?
            public var motorInversion : Bool?
            public var steeringInversion : Bool?
            public var movingUpTime : Int?
            public var movingDownTime : Int?
            public var slatsRotationTime : Int?
            public var virtualBottomLimit : Int?
            public var cameraType : Int?
            public var categories : [String]?
            public var calibrationVariants : [String]?
            // example: List [ "dimmerCalibrationWithBypass", "dimmerCalibrationWithoutBypass" ]
            public var calibrated : Bool?
            public var centralSceneSupport : [CentralSceneSupport]?
            public var channel1 : String?
            public var channel2 : String?
            public var channel3 : String?
            public var channel4 : String?
            public var climateZoneHash : String?
            public var climateZoneId : Int?
            public var configured : Bool?
            public var dead : Bool?
            public var position : String?
            public var port : Double?
            public var strategy : String?
            public var deadReason : String?
            public var defInterval : Int?
            public var defaultPartyTime : Int?
            public var defaultTone : Int?
            public var defaultWateringTime : Int?
            public var deviceControlType : Int?
            public var deviceRole : String?
            public var supportedDeviceRoles : [String]?
            public var deviceGroup : [Int]?
            public var deviceGroupMaster : Int?
            public var deviceIcon : Int?
            public var devices : [Int]?
            public var devicesInitializationProcess : String?
            public var DeviceUID : String?
            public var displayOnMainPage : Int?
            public var doorLockMode : String?
            public var emailNotificationID : Int?
            public var emailNotificationType : Int?
            public var endPointId : Int?
            public var externalSensorConnected : Bool?
            public var favoritePositionsNativeSupport : Bool?
            public var favoritePositions : [FavoritePosition]?
            public var fgrgbwMode : String?
            public var fidUuid : String?
            public var fidLastSynchronizationTimestamp : Int?
            public var fidRole : String?
            //public var firmwareUpdate DeviceFirmwareUpdateDto{...}
            // example: OrderedMap { "updateVersion": "updateVersion", "progress": 5, "info": "info", "status": "status" }
            public var gatewayId : String?
            public var humidityThreshold : Int?
            public var httpsEnabled : Bool?
            public var icon : Icon?
            public var includeInEnergyPanel : Bool?
            //public var inputToChannelMap DeviceInputToChannelMapDto{...}
            // example: OrderedMap { "close": List [ 4 ], "open": List [], "partialOpen1": List [], "step": List [ 1, 3 ], "stop": List [ 5 ] }
            public var ip : String?
            public var isLight : Bool?
            public var jpgPath : String?
            public var lastBreached : Double?
            public var lastHealthy : Double?
            public var lastLoggedUser : Double?
            public var lastModerate : Double?
            public var liliOffCommand : String?
            public var liliOnCommand : String?
            public var linkedDeviceType : String?
            public var localProtectionState : Int?
            public var localProtectionSupport : Int?
            public var log : String?
            public var logTemp : String?
            public var manufacturer : String?
            public var markAsDead : Bool?
            public var maxInterval : Int?
            public var maxUsers : Int?
            public var maxValue : Int?
            public var maxVoltage : Int?
            public var minInterval : Int?
            public var minValue : Int?
            public var minVoltage : Int?
            public var mjpgPath : String?
            public var mode : Double?
            public var model : String?
            public var moveDownPath : String?
            public var moveLeftPath : String?
            public var moveRightPath : String?
            public var moveStopPath : String?
            public var moveUpPath : String?
            public var networkStatus : String?
            public var niceId : Int?
            public var niceProtocol : String?
            public var nodeId : Int?
            public var numberOfSupportedButtons : Int?
            public var offset : Int?
            public var output1Id : Double?
            public var output2Id : Double?
            public var panicMode : Bool?
            public var parameters : [DeviceParameter]?
            public var parametersTemplate : Value?
            public var password : String?
            public var pendingActions : Bool?
            public var pollingDeadDevice : Bool?
            public var pollingInterval : Double?
            public var pollingTimeSec : Int?
            public var power : Power?
            public var productInfo : String?
            public var protectionExclusiveControl : Int?
            //        //public var protectionExclusiveControlSupport : Number?
            public var protectionState : Int?
            public var protectionTimeout : Double?
            public var protectionTimeoutSupport : Bool?
            public var pushNotificationID : Int?
            public var pushNotificationType : Double?
            public var rateType : String?
            public var refreshTime : Int?
            public var remoteId : Int?
            public var remoteGatewayId : Int?
            public var RFProtectionState : Int?
            public var RFProtectionSupport : Int?
            public var rtspPath : String?
            public var rtspPort : Int?
            public var saveLogs : Bool?
            public var slatsRange : Int?
            public var slatsRangeMin : Int?
            public var slatsRangeMax : Int?
            public var storeEnergyData : Bool?
            public var saveToEnergyPanel : Bool?
            // public var schedules [...]
            public var securityLevel : String?
            public var securitySchemes : [String]?
            public var sendStopAfterMove : Bool?
            public var serialNumber : String?
            public var showEnergy : Bool?
            public var state : Value?
            // anyOf -> Bool, Int, String
            public var energy : Double?
            public var sipUserPassword : String?
            public var sipDisplayName : String?
            public var sipUserID : String?
            public var sipUserEnabled : Bool?
            public var smsNotificationID : Int?
            public var smsNotificationType : Double?
            public var softwareVersion : String?
            public var stepInterval : Double?
            public var supportedThermostatFanModes : [String]?
            public var supportedThermostatModes : [String]?
            // public var supportedTones [{...}]
            public var tamperMode : String?
            public var targetLevel : Double?
            public var targetLevelDry : Double?
            public var targetLevelHumidify : Double?
            public var targetLevelMax : Double?
            public var targetLevelMin : Double?
            public var targetLevelStep : Double?
            public var targetLevelTimestamp : Double?
            public var thermostatFanMode : String?
            public var thermostatFanOff : Bool?
            public var thermostatFanState : String?
            public var thermostatMode : String?
            public var thermostatModeFuture : String?
            public var thermostatOperatingState : String?
            public var thermostatModeManufacturerData : [Int]?
            public var thermostatState : String?
            public var powerConsumption : Double?
            public var timestamp : Int?
            public var tone : Int?
            public var unit : String?
            public var updateVersion : String?
            public var useTemplate : Bool?
            //public var userCodes [UserCodeDto{...}
            // example: OrderedMap { "id": 0, "name": "User 1", "status": "Occupied", "update": "Ok" }]
            public var userDescription : String?
            public var username : String?
            public var wakeUpTime : Double?
            public var zwaveCompany : String?
            public var zwaveInfo : String?
            // public var zwaveScheduleClimatePanelCompatibileBlocks [{...}]
            public var zwaveVersion : String?
            public var value : Value?
            // anyOf -> Int, Bool, String
            public var viewLayout : JSONAny?
            public var volume : Int?
            public var mainFunction : String?
            public var uiCallbacks : [UICallbacks]?
            public var quickAppVariables : [QuickAppVariable]?
            // public var colorComponents {
            public var walliOperatingMode : String?
            public var ringUpperColor : String?
            public var ringBottomColor : String?
            public var ringBrightness : Double?
            public var ringLightMode : String?
            public var ringConfirmingTime : Double?
            public var encrypted : Bool?
        }
        
        public struct Device : Codable, Equatable {
            public var id: Int
            public var name: String
            public var roomID: Int
            public var view: [JSONAny]
            public var type, baseType: String
            public var interfaces: [String]
            public var enabled, visible, isPlugin: Bool
            public var parentId: Int
            public var viewXml, hasUIView, configXml: Bool
            public var properties: Properties
            public var actions: [String: Int]
            public var remoteGatewayId: Int?
            public var created, modified, sortOrder: Int
            
            public static func == (lhs: Device, rhs: Device) -> Bool {
                return (lhs.id == rhs.id)
            }
        }
        
        // MARK: - PropertiesSimple
        public struct PropertiesSimple: Codable {
            public var armed : Bool?
            public var batteryLevel : Int?
            public var categories : [String]?
            //var centralSceneSupport : [CentralSceneSupport]?
            public var dead : Bool?
            public var position : String?
            public var deadReason : String?
            public var deviceControlType : Int?
            public var deviceRole : String?
            public var icon : Icon?
            public var includeInEnergyPanel : Bool?
            public var isLight : Bool?
            public var jpgPath : String?
            public var lastBreached : Double?
            public var lastHealthy : Double?
            public var lastLoggedUser : Double?
            public var log : String?
            public var logTemp : String?
            public var manufacturer : String?
            public var markAsDead : Bool?
            public var model : String?
            public var power : Power?
            public var productInfo : String?
            public var rateType : String?
            public var storeEnergyData : Bool?
            public var saveToEnergyPanel : Bool?
            public var serialNumber : String?
            public var showEnergy : Bool?
            public var state : Value?
            public var energy : Double?
            public var softwareVersion : String?
            public var thermostatFanMode : String?
            public var thermostatFanOff : Bool?
            public var thermostatFanState : String?
            public var thermostatMode : String?
            public var thermostatModeFuture : String?
            public var thermostatOperatingState : String?
            public var thermostatModeManufacturerData : [Int]?
            public var thermostatState : String?
            public var powerConsumption : Double?
            public var timestamp : Int?
            public var unit : String?
            public var updateVersion : String?
            public var useTemplate : Bool?
            public var userDescription : String?
            public var wakeUpTime : Double?
            public var zwaveCompany : String?
            public var zwaveInfo : String?
            public var zwaveVersion : String?
            public var value : Value?
            public var volume : Int?
            public var uiCallbacks : [UICallbacks]?
            public var quickAppVariables : [QuickAppVariable]?
        }
        
        public struct DeviceSimple : Codable, Equatable {
            public var id: Int
            public var name: String
            public var roomID: Int
            public var view: [JSONAny]
            public var type, baseType: String
            public var interfaces: [String]
            public var enabled, visible, isPlugin: Bool
            public var parentId: Int
            public var viewXml, hasUIView, configXml: Bool
            public var properties: PropertiesSimple
            public var actions: [String: Int]
            public var remoteGatewayId: Int?
            public var created, modified, sortOrder: Int
            
            public static func == (lhs: DeviceSimple, rhs: DeviceSimple) -> Bool {
                return (lhs.id == rhs.id)
            }
        }
        
        
        // MARK: - GlobalVariable
        public struct GlobalVariable: Codable, Hashable {
            public var name, value: String
            public var readOnly, isEnum: Bool
            public var enumValues: [String]
            public var created, modified: Int
        }
    }
}
