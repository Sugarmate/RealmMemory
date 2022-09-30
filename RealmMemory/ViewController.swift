//
//  ViewController.swift
//  RealmMemory
//
//  Created by Dave Morgereth on 9/29/22.
//

import UIKit
import RealmSwift

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        configureRealm()
        let button = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 50))
        button.backgroundColor = .green
        button.setTitle("Run Query", for: [])
        button.addTarget(self, action: #selector(runQuery), for: .touchUpInside)
        self.view.addSubview(button)
    }

    @objc fileprivate func runQuery(sender: UIButton!) {
        for i in (1...50) {
            let startedAt = Date().addingTimeInterval(-(Double(i) * 1000))
            runRealmQuery(startedAt: startedAt, endedAt: startedAt.addingTimeInterval(1000))
        }
    }

    fileprivate func runRealmQuery(startedAt: Date, endedAt: Date) {

        let realm = try! Realm()
        let objects = realm.objects(RealmObj.self).where {($0.started_at >= startedAt && $0.ended_at <= endedAt)}
        if let first = objects.first {
            print("first: \(first)")
        } else {
            print("No objects in collection")
        }
    }

    fileprivate func configureRealm() {
        var config = Realm.Configuration(deleteRealmIfMigrationNeeded: true)
        let realmURL = FileManager.default.temporaryDirectory.appendingPathComponent("RealmMemory")
        config.fileURL = realmURL
        Realm.Configuration.defaultConfiguration = config
        do {
            _ = try Realm()
            print("Realm configured")
        } catch let error {
            print("Realm config failed: " + error.localizedDescription)
            fatalError()
        }
    }
}

class RealmObj: Object {
    @Persisted(indexed: true) var started_at: Date
    @Persisted(indexed: true) var ended_at: Date
    @Persisted var title: String
    @Persisted var embedded: Embedded?

    override init() {
        super.init()
        started_at = Date()
        ended_at = Date()
        title = ""
    }
}

class Embedded: EmbeddedObject {
    @Persisted var notes: String

    override init() {
        super.init()
        notes = ""
    }
}
