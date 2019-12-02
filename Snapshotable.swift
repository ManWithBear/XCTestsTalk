//
//  ---------------------------------------
// < Copyright © 2019 Showmax. MIT License >
//  ---------------------------------------
//                        \
//                         \
//                          \ >()_
//                             (__)__ _

import UIKit

protocol Snapshotable {
    func prepareForSnapshot()
    func makeSnapshot(by snapshoter: Snapshoter)
}

extension UIView: Snapshotable {
    func prepareForSnapshot() {
        UIView.setAnimationsEnabled(false)
    }
    func makeSnapshot(by snapshoter: Snapshoter) {
        snapshoter.checkSnapshot(of: self)
    }
}

extension UIViewController: Snapshotable {
    func prepareForSnapshot() {
        UIView.setAnimationsEnabled(false)
        UIApplication.shared.keyWindow?.rootViewController = self
    }
    func makeSnapshot(by snapshoter: Snapshoter) {
        snapshoter.checkSnapshot(of: UIApplication.shared.keyWindow!) // swiftlint:disable:this force_unwrapping
    }
}
