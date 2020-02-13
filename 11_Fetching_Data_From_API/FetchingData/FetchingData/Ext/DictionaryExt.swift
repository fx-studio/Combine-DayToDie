//
//  DictionaryExt.swift
//  FetchingData
//
//  Created by Lam Le V. on 2/13/20.
//  Copyright © 2020 Lam Le V. All rights reserved.
//

import Foundation

extension Dictionary {

    func data() -> Data? {
        return (try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted))
    }
}
