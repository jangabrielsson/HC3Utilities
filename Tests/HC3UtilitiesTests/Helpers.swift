import Foundation
import SwiftUI


func testURLForResource(_ resourceName: String) -> URL {
    return Bundle.module.url(forResource: resourceName, withExtension: nil)!
//    return Bundle(for: Helpers.self)
//        .url(forResource: resourceName, withExtension: nil)!
}

func dataFrom(resource: String) -> Data {
    let url = testURLForResource(resource)
    do {
        let data1 = try Data(contentsOf: url)
        return data1
    } catch { }

    return Data()   // should never happen
}

func stringFrom(resource: String) -> String? {
    let url = testURLForResource(resource)
    do {
        let value = try String(contentsOfFile: url.path, encoding: String.Encoding.utf8)
        return value
    } catch { }

    return nil
}

class Helpers {
}
