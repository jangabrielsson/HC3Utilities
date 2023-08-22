//
//  HC3.swift
//  Test
//
//  Created by Jan Gabrielsson on 2023-08-20.
//

import Foundation


extension URLSession {
    func synchronousDataTask(urlrequest: URLRequest) -> (data: Data?, response: URLResponse?, error: Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?

        let semaphore = DispatchSemaphore(value: 0)

        let dataTask = self.dataTask(with: urlrequest) {
            data = $0
            response = $1
            error = $2

            semaphore.signal()
        }
        dataTask.resume()

        _ = semaphore.wait(timeout: .distantFuture)

        return (data, response, error)
    }
}

typealias HC3RawResponse = (code:Int,message:String,data:String)

func decode<T: Decodable>(str: String) throws -> T {
    let data = Data(str.utf8)
    let decodedData = try JSONDecoder().decode(T.self.self, from: data)
    return decodedData
}

enum HC3Error: Error {
    case http(Int,String)
    case decode(String)
}

func decode<T: Decodable, D>(code: Int, data: String, cc: (T) -> D) throws -> D {
    if code > 201 { throw HC3Error.http(code,"") }
    do {
        let dd = try decode(str: data) as T
        return cc(dd)
    } catch {
        throw HC3Error.decode("\(error)")
    }
}

class FibaroAPI {
    var hc3: HC3Utilities

    func getGlobalVariable(name: String) throws -> (String, Int) {
        let (code,_,data) = hc3.httpGet(path: "/globalVariables/\(name)")
        return try decode(code:code,data:data) { (d: HC3Utilities.types.GlobalVariable) -> (String, Int) in
            return (d.value,d.modified)
        }
    }

    func getGlobalVariables() throws -> [HC3Utilities.types.GlobalVariable] {
        let (code,_,data) = hc3.httpGet(path: "/globalVariables/")
        return try decode(code:code,data:data) { (d: [HC3Utilities.types.GlobalVariable]) -> [HC3Utilities.types.GlobalVariable] in
            return d
        }
    }
    
    func getDevice(deviceId: Int) throws -> HC3Utilities.types.Device {
        let (code,_,data) = hc3.httpGet(path: "/devices/\(deviceId)")
        return try decode(code:code,data:data) { (d: HC3Utilities.types.Device) -> HC3Utilities.types.Device in
            return d
        }
    }
    
    func getDevices(query: String = "") throws -> [HC3Utilities.types.Device] {
        let (code,_,data) = hc3.httpGet(path: "/devices" + (query == "" ? "" : "?"+query))
        return try decode(code:code,data:data) { (d: [HC3Utilities.types.Device]) -> [HC3Utilities.types.Device] in
            return d
        }
    }
    
    init(hc3: HC3Utilities) { self.hc3 = hc3 }
}

struct HC3Utilities {
    var baseURL: String
    var creds: String
    lazy var fibaro: FibaroAPI = FibaroAPI(hc3: self)
    
    init(ip: String, user: String, password: String) {
        let loginData = "\(user):\(password)"
        creds = (loginData.data(using: .utf8)?.base64EncodedString())!
        creds = "Basic " + creds
        baseURL = "http://\(ip)/api"
    }
    
    func HC3Request(path: String) -> URLRequest {
        let url = URL(string:baseURL + path)!
        var urlReq = URLRequest(url:url)
        urlReq.setValue(creds, forHTTPHeaderField: "Authorization")
        urlReq.setValue("2", forHTTPHeaderField: "X-Fibaro-Version")
        urlReq.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        urlReq.setValue("*/*", forHTTPHeaderField: "Accept")
        return urlReq
    }
    
    func _httpRequest(request: URLRequest) -> HC3RawResponse {
        let (data, response, error) = URLSession.shared.synchronousDataTask(urlrequest: request)
        
        guard error == nil else {
            return (code:5001,message:error!.localizedDescription,data:"")
        }
    
        guard let httpResponse = response as? HTTPURLResponse else {
            return (code:5001,message:"No http response",data:"")
        }
        
        let code = httpResponse.statusCode
        
        guard let responseData = data else {
            return (code:code,message:"No data",data:"")
        }
        
        let raw = String(decoding: responseData, as: UTF8.self)
        return (code:code,message:"OK",data:raw)
    }
    
    func httpGet(path: String) -> HC3RawResponse {
        return _httpRequest(request: HC3Request(path:path))
    }
    
    func decode<T: Decodable>(str: String) throws -> T {
        let data = Data(str.utf8)
        let decodedData = try JSONDecoder().decode(T.self.self, from: data)
        return decodedData
    }

    func decode<T: Decodable, D>(code: Int, data: String, cc: (T) -> D) throws -> D {
        if code > 201 { throw HC3Error.http(code,"") }
        do {
            let dd = try decode(str: data) as T
            return cc(dd)
        } catch {
            throw HC3Error.decode("\(error)")
        }
    }
    
}
