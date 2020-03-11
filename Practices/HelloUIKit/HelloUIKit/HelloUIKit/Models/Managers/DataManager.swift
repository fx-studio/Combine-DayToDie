//
//  DataManager.swift
//  HelloUIKit
//
//  Created by Le Phuong Tien on 3/4/20.
//  Copyright © 2020 Fx Studio. All rights reserved.
//

import Foundation
import Combine

class DataManagement {
  // MARK: - Signleton
  public static var share: DataManagement = {
    let dataManagement = DataManagement()
    return dataManagement
  }()
  
  private init() {}
  
  private var plistURL : URL {
      let documentDirectoryURL =  try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
      return documentDirectoryURL.appendingPathComponent("data.plist")
  }
  
  // MARK: - public function
  func save(value: Int) {
    do {
      let dictionary = ["count" : value]
      try savePropertyList(dictionary)
    } catch {
      print(error)
    }
    
  }
  
  func save(value: Int, completion: (Error?) -> Void) {
    do {
      let dictionary = ["count" : value]
      try savePropertyList(dictionary)
      
      //call back
      completion(nil)
      
    } catch {
      //call back
      completion(error)
      
    }
    
  }
  
  func save(value: Int) -> Future<Void, Error> {
    return Future { resolve in
      do {
        let dictionary = ["count" : value]
        try self.savePropertyList(dictionary)
        
        //call back
        resolve(.success(()))
        
      } catch {
        //call back
        resolve(.failure(error))
        
      }
    }
  }
  
  func load() -> [String : Int] {
    do {
      let dictionary = try loadPropertyList()
      return dictionary
    } catch {
      print(error)
      return [:]
    }
  }
  
  
  // MARK: - private function
  private func savePropertyList(_ plist: Any) throws {
    let plistData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
    try plistData.write(to: plistURL)
  }
  
  func loadPropertyList() throws -> [String : Int] {
    let data = try Data(contentsOf: plistURL)
    guard let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String : Int] else {
      return [:]
    }
    return plist
  }
}
