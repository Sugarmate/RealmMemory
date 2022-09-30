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

        let loadDataButton = UIButton(frame: CGRect(x: 100, y: 100, width: 150, height: 50))
        loadDataButton.backgroundColor = .green
        loadDataButton.setTitle("Load Data", for: [])
        loadDataButton.addTarget(self, action: #selector(loadData), for: .touchUpInside)
        self.view.addSubview(loadDataButton)

        let toggleObservingButton = UIButton(frame: CGRect(x: 100, y: 200, width: 150, height: 50))
        toggleObservingButton.backgroundColor = .green
        toggleObservingButton.setTitle("Start observing", for: [])
        toggleObservingButton.addTarget(self, action: #selector(toggleObserving), for: .touchUpInside)
        self.view.addSubview(toggleObservingButton)

        let queryButton = UIButton(frame: CGRect(x: 100, y: 300, width: 150, height: 50))
        queryButton.backgroundColor = .green
        queryButton.setTitle("Run Query", for: [])
        queryButton.addTarget(self, action: #selector(runQuery), for: .touchUpInside)
        self.view.addSubview(queryButton)

        let deleteAllButton = UIButton(frame: CGRect(x: 100, y: 400, width: 150, height: 50))
        deleteAllButton.backgroundColor = .green
        deleteAllButton.setTitle("Delete All Data", for: [])
        deleteAllButton.addTarget(self, action: #selector(deleteAll), for: .touchUpInside)
         self.view.addSubview(deleteAllButton)
    }

    @objc fileprivate func loadData(sender: UIButton!) {
        sender.isEnabled = false
        loadRealmData()
        sender.isEnabled = true
    }

    @objc fileprivate func runQuery(sender: UIButton!) {
        sender.isEnabled = false

        for i in (1...3000) {
            let startedAt = Date().addingTimeInterval((Double(i) * 1000))
            runRealmQuery(startedAt: startedAt, endedAt: startedAt.addingTimeInterval(1000))
        }
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

    fileprivate func runRealmQuery(startedAt: Date, endedAt: Date) {
        let realm = try! Realm()

        let objects = realm.objects(RealmObj.self).where {($0.started_at >= startedAt && $0.ended_at <= endedAt)}
        if let first = objects.first {
            print("first: started_at=\(first.started_at), id=\(first.id)")
        } else {
            print("query returned no objects")
        }
    }

    fileprivate func loadRealmData() {
        let realm = try! Realm()

        for i in (0...2000) {
            let embedded = Embedded()
            let obj = RealmObj(started_at: Date().addingTimeInterval(Double(i * 2000)), ended_at: Date().addingTimeInterval(Double(i * 2000)), embedded: embedded)
            try! realm.write {
                realm.add(obj)
            }
        }

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
        token = objects.observe({ changes in
            switch changes {
            case .initial(_):
                print("Observe: initial")
            case .update(let currentObjects, let deleted, let inserted, let modified):
                print("Observe: update:  object count=\(currentObjects.count), \(deleted.count) deleted, \(inserted.count) inserted, \(modified.count) modified")
            case .error(let error):
                print("Observe: error: \(error)")
            }
        })
    }

    fileprivate func stopObserving() {
        token?.invalidate()
        token = nil
    }
}

class RealmObj: Object {
    @Persisted(indexed: true) var id: String = ""
    @Persisted(indexed: true) var started_at: Date = Date()
    @Persisted(indexed: true) var ended_at: Date = Date()
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

    init(started_at: Date, ended_at: Date, title: String = "", embedded: Embedded?) {
        super.init()
        id = UUID().uuidString
        self.started_at = started_at
        self.ended_at = ended_at
        self.title = title
        self.embedded = embedded
    }
}

class Embedded: EmbeddedObject {
    @Persisted var notes: String

    override init() {
        super.init()
        notes = ""
    }
}

/*
class RealmObj1: Object {
    @Persisted(indexed: true) var id: String = ""
    @Persisted var clientStgId: String = ""
    @Persisted(indexed: true) var event_type: String = ""
    @Persisted var account_id: Int = 0
    @Persisted var source: String?
    @Persisted var source_id: String?
    @Persisted var db_source_child_ids: String = ""      // Don't mess with this directly
    @Persisted var source_subtype: String?
    @Persisted(indexed: true) var started_at: Date = Date()
    @Persisted(indexed: true) var ended_at: Date = Date()
    @Persisted var duration_in_seconds: Int = 0
    @Persisted var title: String?
    @Persisted var notes: String?
    @Persisted var pg_id: String = ""
    @Persisted var deleted: Bool = false
    @Persisted var created_at: Date = Date()
    @Persisted var updated_at: Date = Date()
    @Persisted var needsSaveToServer: Bool = false
    @Persisted var needsSaveToHealthKit: Bool = false
    @Persisted var embedded: Embedded?
//    @Persisted var basal_rate: SMSubEventEntryBasalRate?
//    @Persisted var device_change: SMSubEventEntryDeviceChange?
//    @Persisted var exercise: SMSubEventEntryExercise?
//    @Persisted var food: SMSubEventEntryFood?
//    @Persisted var insulin: SMSubEventEntryInsulin?
//    @Persisted var liquid: SMSubEventEntryLiquid?
//    @Persisted var med: SMSubEventEntryMed?
//    @Persisted var glucose: SMSubEventEntryGlucose?
//    @Persisted var schedule_change: SMSubEventEntryScheduleChange?

    var source_child_ids: [String] {
        get {
            return db_source_child_ids.components(separatedBy: ",")
        }
        set {
            db_source_child_ids = newValue.joined(separator: ",")
        }
    }

    required init(id: String = "", event_type: String, account_id: Int = 0, source: String? = nil, source_id: String? = nil, source_child_ids: [String] = [], source_subtype: String? = nil, started_at: Date = Date(), ended_at: Date = Date(), duration_in_seconds: Int = 0, title: String? = nil, notes: String? = nil, pg_id: String = "", deleted: Bool = false, created_at: Date = Date(), updated_at: Date? = nil, embedded: Embedded? = nil) {

        super.init()
        self.id = id
        self.event_type = event_type
        self.account_id = account_id
        self.source = source
        self.source_id = source_id
        self.source_child_ids = source_child_ids
        self.source_subtype = source_subtype
        self.started_at = started_at
        self.ended_at = ended_at
        self.duration_in_seconds = duration_in_seconds
        self.title = title
        self.notes = notes
        self.pg_id = pg_id
        self.deleted = deleted
        self.created_at = created_at
        self.updated_at = updated_at ?? created_at
//        self.basal_rate = basal_rate
//        self.device_change = device_change
//        self.exercise = exercise
//        self.food = food
//        self.insulin = insulin
//        self.liquid = liquid
//        self.med = med
//        self.glucose = glucose
//        self.schedule_change = schedule_change
        self.embedded = embedded
        self.needsSaveToServer = false
        self.needsSaveToHealthKit = false
    }

    override init() {
        super.init()
    }

}
*/
