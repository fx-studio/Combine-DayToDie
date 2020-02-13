//
//  ViewController.swift
//  FetchingData
//
//  Created by Lam Le V. on 2/12/20.
//  Copyright © 2020 Lam Le V. All rights reserved.
//

import UIKit
import OHHTTPStubs
import Combine

final class ViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    let viewModel = ViewModel()
    var cancellable: [AnyCancellable] = []
    private var developers: [Developer] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        configTableView()
        fetchData()
    }

    private func configTableView() {
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    private func fetchData() {
        // Mock server by OHHTTPStubs
        stub(condition: isHost("developer.com")) { _ in
          // Stub it with our "wsresponse.json" stub file (which is in same bundle as self)
          let stubPath = OHPathForFile("Developer.json", type(of: self))
          return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
        }
        // Fetch data
        viewModel.fetchDevelopers.receive(on: RunLoop.main).sink(receiveCompletion: { (error) in
            print(error)
        }, receiveValue: { [weak self] developers in
            self?.developers = developers
            self?.tableView.reloadData()
        })
        .store(in: &cancellable)
    }
}

extension ViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return developers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = developers[indexPath.row].name
        return cell
    }
}

