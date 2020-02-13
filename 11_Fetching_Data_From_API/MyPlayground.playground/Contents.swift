import UIKit

struct Car: Codable {
    var name: String
    var horsepower: Int
}

let dict = [
    "cars": [
        [
            "name": "Toyota Prius",
            "horsepower": 1
        ],
        [
            "name": "Tesla 3",
            "horsepower" : 3
        ],
        [
            "name": "Ferrari",
            "horsepower" : 999
        ]
    ]
]

if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) {
    let cars = try? JSONDecoder().decode([String: [Car]].self, from: jsonData)
    print(cars)

}

