//
//  ViewController.swift
//  RealmMemory
//
//  Created by Dave Morgereth on 9/29/22.
//

import UIKit
import RealmSwift

class ViewController: UIViewController {

    var refDate = Date()
    var loadDataButton: UIButton!
    let mockAccountId: Int = 2
    let queryByAccountIdTag: Int = 99

    override func viewDidLoad() {
        super.viewDidLoad()
        configureRealm()

        loadDataButton = UIButton(frame: CGRect(x: 100, y: 100, width: 150, height: 50))
        loadDataButton.backgroundColor = .blue
        loadDataButton.setTitle("Load Data", for: [])
        loadDataButton.addTarget(self, action: #selector(loadData), for: .touchUpInside)
        self.view.addSubview(loadDataButton)

        let toggleObservingButton = UIButton(frame: CGRect(x: 100, y: 200, width: 150, height: 50))
        toggleObservingButton.backgroundColor = .blue
        toggleObservingButton.setTitle("Start observing", for: [])
        toggleObservingButton.addTarget(self, action: #selector(toggleObserving), for: .touchUpInside)
        self.view.addSubview(toggleObservingButton)

        let accountIdQueryButton = UIButton(frame: CGRect(x: 100, y: 300, width: 150, height: 50))
        accountIdQueryButton.backgroundColor = .blue
        accountIdQueryButton.titleLabel?.numberOfLines = 0
        accountIdQueryButton.titleLabel?.lineBreakMode = .byWordWrapping
        accountIdQueryButton.titleLabel?.textAlignment = .center
        accountIdQueryButton.setTitle("Query with AccountId", for: [])
        accountIdQueryButton.addTarget(self, action: #selector(runQuery), for: .touchUpInside)
        accountIdQueryButton.tag = queryByAccountIdTag      // a quick kludge
        self.view.addSubview(accountIdQueryButton)

        let regularQueryButton = UIButton(frame: CGRect(x: 100, y: 400, width: 150, height: 50))
        regularQueryButton.backgroundColor = .blue
        regularQueryButton.titleLabel?.numberOfLines = 0
        regularQueryButton.titleLabel?.lineBreakMode = .byWordWrapping
        regularQueryButton.titleLabel?.textAlignment = .center
        regularQueryButton.setTitle("Query without AccountId", for: [])
        regularQueryButton.addTarget(self, action: #selector(runQuery), for: .touchUpInside)
        regularQueryButton.tag = 0
        self.view.addSubview(regularQueryButton)

        let deleteAllButton = UIButton(frame: CGRect(x: 100, y: 500, width: 150, height: 50))
        deleteAllButton.backgroundColor = .blue
        deleteAllButton.setTitle("Delete All Data", for: [])
        deleteAllButton.addTarget(self, action: #selector(deleteAll), for: .touchUpInside)
        self.view.addSubview(deleteAllButton)

        let dateComp = DateComponents(year: 2021, month: 01, day: 01)
        refDate = Calendar.current.date(from: dateComp)!
    }

    @objc fileprivate func loadData(sender: UIButton!) {
        sender.isEnabled = false
        loadRealmData()
        sender.isEnabled = true
    }

    @objc fileprivate func runQuery(sender: UIButton!) {
        sender.isEnabled = false
        let start = Date().timeIntervalSince1970
        var totalCount: Int = 0
        let queryCount: Int = 200

        for i in (1...queryCount) {
            let startedAt = refDate.addingTimeInterval((Double(i) * 1000))
            let results = runRealmQuery(startedAt: startedAt, endedAt: startedAt.addingTimeInterval(10000), useAccountId: sender.tag == queryByAccountIdTag)
            totalCount += results.count
        }

        let end = Date().timeIntervalSince1970

        let avg = (end - start) / Double(queryCount)
        let roundedAvg = Double(Int64(avg * 100000)) / 100000
        let avgRowCount = Double(Int64((Double(totalCount) / Double(queryCount))) * 10) / 10
        print("Avg query time: \(roundedAvg), avg row count: \(avgRowCount) " + (sender.tag == queryByAccountIdTag ? " using accountId" : " not using accountId"))
        sender.isEnabled = true
    }

    fileprivate var isObserving: Bool = false
    fileprivate var token: NotificationToken?

    @objc fileprivate func toggleObserving(sender: UIButton!) {
        sender.isEnabled = false
        if isObserving {
            sender.setTitle("Start observing", for: [])
            stopObserving()
            print("Stop observing")

        } else {
            sender.setTitle("Stop observing", for: [])
            startObserving()
            print("Start observing")
        }
        isObserving = !isObserving
        sender.isEnabled = true
    }

    @objc fileprivate func deleteAll(sender: UIButton!) {
        sender.isEnabled = false
        deleteRealmData()
        sender.isEnabled = true
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

    fileprivate func runRealmQuery(startedAt: Date, endedAt: Date, useAccountId: Bool) -> [Date] {
        let realm = try! Realm()
        var theStuff: [Date] = []

        let objects = useAccountId ? realm.objects(RealmObj.self).where {($0.ended_at >= startedAt && $0.started_at <= endedAt) && ($0.account_id == mockAccountId)} : realm.objects(RealmObj.self).where {($0.ended_at >= startedAt && $0.started_at <= endedAt)}
        if let _ = objects.first {
            objects.forEach { obj in
                theStuff.append(obj.started_at)
            }
        }
        return theStuff
    }

    fileprivate func loadRealmData() {
        let realm = try! Realm()
        loadDataButton.setTitle("Loading...", for: [])
        for i in (0...20000) {
            if i % 500 == 0 {
                print("loading... \(i)")
            }
            let obj = RealmObj(started_at: refDate.addingTimeInterval(Double(i * 200)), ended_at: refDate.addingTimeInterval(Double(i * 200) + 10), account_id: mockAccountId)
            try! realm.write {
                realm.add(obj)
            }
        }

        loadDataButton.setTitle("Loaded", for: [])
        print("Data loaded")
    }

    fileprivate func deleteRealmData() {
        let realm = try! Realm()
        let objects = realm.objects(RealmObj.self)
        try! realm.write {
            realm.delete(objects)
        }

        print("Data deleted")
    }

    fileprivate func startObserving() {
        let realm = try! Realm()
        let objects = realm.objects(RealmObj.self)
        token = objects.observe(keyPaths: ["started_at", "title"], on: .main) { changes in
            switch changes {
            case .initial(_):
                print("Observe: initial")
            case .update(let currentObjects, let deleted, let inserted, let modified):
                print("Observe: update:  object count=\(currentObjects.count), \(deleted.count) deleted, \(inserted.count) inserted, \(modified.count) modified")
            case .error(let error):
                print("Observe: error: \(error)")
            }
        }
    }

    fileprivate func stopObserving() {
        token?.invalidate()
        token = nil
    }
}

class RealmObj: Object {
    @Persisted var id: String = ""
    @Persisted(indexed: true) var started_at: Date = Date()
    @Persisted(indexed: true) var ended_at: Date = Date()
    @Persisted(indexed: true) var account_id: Int = 0
    @Persisted var title: String = ""
    @Persisted var embedded: Embedded?

    override static func primaryKey() -> String? {
       return "id"
    }

    override init() {
        super.init()
        id = UUID().uuidString
        started_at = Date()
        ended_at = Date()
        title = ""
    }

    init(started_at: Date, ended_at: Date, account_id: Int, title: String = "") {
        super.init()
        id = UUID().uuidString
        self.started_at = started_at
        self.ended_at = ended_at
        self.account_id = account_id
        self.title = title
        self.embedded = Embedded()
    }
}

class Embedded: EmbeddedObject {
    @Persisted var field1: Int
    @Persisted var field2: String

    override init() {
        field1 = 5
        field2 = "the data"
        super.init()
    }
}
