//
//  ---------------------------------------
// < Copyright © 2019 Showmax. MIT License >
//  ---------------------------------------
//                        \
//                         \
//                          \ >()_
//                             (__)__ _

import Foundation
import FBSnapshotTestCase

/// Class responsible for making snapshots of views
class Snapshoter {

    static var isRecording: Bool {
        // TODO: Read launch arguments for some `recording` flag
        return false
    }

    static var referenceImageDirectory: String? {
        return ProcessInfo.processInfo.environment["FB_REFERENCE_IMAGE_DIR"]
    }

    static var imageDiffDirectory: String? {
        return ProcessInfo.processInfo.environment["IMAGE_DIFF_DIR"]
    }

    let test: XCTestCase
    private let readBundle: Bundle?
    private let envReferenceImageDirectory: String?
    private let snapshotController: FBSnapshotTestController
    private var snapshotCounter: Int = 0

    init(_ test: XCTestCase) {
        self.test = test

        snapshotController = FBSnapshotTestController(test: type(of: test))
        snapshotController.recordMode = Snapshoter.isRecording
        snapshotController.agnosticOptions = [.screenSize]

        readBundle = Bundle(for: type(of: self))
            .path(forResource: "Snapshots", ofType: "bundle")
            .flatMap { Bundle(path: $0) }

        if Snapshoter.isRecording {
            envReferenceImageDirectory = Snapshoter.referenceImageDirectory
        } else {
            envReferenceImageDirectory = readBundle?.resourcePath
        }
    }

    /// If called in `record` mode, make snapshot of view and store it on disk
    /// If called in `test` mode, make snapshot and compare it to reference image from disk
    func checkSnapshot(of view: UIView, file: StaticString = #file, line: UInt = #line) {
        snapshotCounter += 1
        FBSnapshotVerifyViewOrLayer(view, identifier: "Step\(snapshotCounter)", file: file, line: line)
    }

    // MARK: - iOSSnapshot code
    private func FBSnapshotVerifyViewOrLayer(
        _ view: UIView,
        identifier: String = "",
        tolerance: CGFloat = 0,
        file: StaticString,
        line: UInt
    ) {
        guard let selector = test.invocation?.selector else {
            XCTFail("Can't find current test selector, are you sure you calling this method from test?")
            return
        }
        guard let envReferenceImageDirectory = self.envReferenceImageDirectory else {
            let msg = "Missing value for referenceImagesDirectory" +
                " - " +
                "Set FB_REFERENCE_IMAGE_DIR as Environment variable in your scheme if you running in simulator" +
                "or make sure that Snapshots.bundle added to target if you running on real device."
            XCTFail(msg)
            return
        }
        snapshotController.referenceImagesDirectory = envReferenceImageDirectory

        guard let imageDiffDirectory = Snapshoter.imageDiffDirectory else {
            let msg = "Missing value for imageDiffDirectory" +
                " - " +
                "Set IMAGE_DIFF_DIR as Environment variable in your scheme if you running in simulator"
            XCTFail(msg)
            return
        }
        snapshotController.imageDiffDirectory = imageDiffDirectory

        /// When set to true, it causes unreliable recording of images. Images probably
        /// contain some small differencies that will cause failing test when comparing against reference image.
        /// So better turned off, despite it helps to record blurred UIVisualEffect backgrounds
        snapshotController.usesDrawViewHierarchyInRect = false

        do {
            try snapshotController.compareSnapshot(ofViewOrLayer: view, selector: selector, identifier: identifier, overallTolerance: tolerance)
        } catch let error as NSError {
            if Snapshoter.isRecording {
                print("Save in: \(snapshotController.referenceImagesDirectory)")
                print("Test ran in record mode. Reference image is now saved. Disable record mode to perform an actual snapshot comparison!")
            }
            XCTFail("Snapshot comparison failed: \(String(describing: error))", file: file, line: line)
        }
    }
}
