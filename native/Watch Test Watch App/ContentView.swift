//
//  ContentView.swift
//  Watch Test Watch App
//
//  Created by Rexios on 1/31/23.
//

import HealthKit
import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @ObservedObject var controller = Controller()

    var body: some View {
        Button(action: controller.toggle) {
            Text(controller.started ? "Stop" : "Start")
        }
        TimelineView(PeriodicTimelineSchedule(from: Date(), by: 1)) { _ in
            Text("\(controller.count)")
        }
    }
}

class Controller: NSObject, ObservableObject, WCSessionDelegate {
    @Published var started = false
    @Published var count = 0
    var session: HKWorkoutSession?

    override init() {
        super.init()
        WCSession.default.delegate = self
        WCSession.default.activate()
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: send)
    }

    func send(timer _: Timer) {
        count += 1
        print("sending \(count)")
        WCSession.default.sendMessage(["count": count], replyHandler: nil)
    }

    func toggle() {
        Task { await toggleAsync() }
    }

    private func toggleAsync() async {
        if started {
            session?.end()
            DispatchQueue.main.async { self.started = false }
        } else {
            let healthStore = HKHealthStore()
            try? await healthStore.requestAuthorization(
                toShare: [],
                read: [HKQuantityType.quantityType(forIdentifier: .heartRate)!]
            )
            session = try? HKWorkoutSession(healthStore: healthStore, configuration: HKWorkoutConfiguration())
            session?.startActivity(with: Date())
            session?.pause()
            DispatchQueue.main.async { self.started = true }
        }
    }

    func session(_: WCSession, activationDidCompleteWith _: WCSessionActivationState, error _: Error?) {}
}
