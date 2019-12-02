//
//  ---------------------------------------
// < Copyright © 2019 Showmax. MIT License >
//  ---------------------------------------
//                        \
//                         \
//                          \ >()_
//                             (__)__ _

import UIKit

/// Test case that generate snapshot test of `StatefulComponent` provided by
/// `AnyStatefulComponentTests`.
///
/// Subclass need to override `class var componentTests` property and return
/// component states for snapshots.
class StatefulComponentSnapshotTestCase: DynamicTestCase {
    class var componentTests: AnyStatefulComponentTests {
        return EmptyStatefulComponentTests()
    }

    override class func runtimeTests() -> [RuntimeTest] {
        return componentTests.tests.map { test in
            RuntimeTest(name: test.0) { testCase in
                let component = test.1()
                snapshot(component)
            }
        }
    }
}

/// Type-erased `ConcreteStatefulComponentTests`
protocol AnyStatefulComponentTests {
    var tests: [(String, () -> Snapshotable)] { get }
}

class EmptyStatefulComponentTests: AnyStatefulComponentTests {
    var tests: [(String, () -> Snapshotable)] { [] }
}

/// Wrapper around list of states of generic `StatefulComponent` with names.
///
/// Usage example:
///
///     ConcreteStatefulComponentTests<StatefulView>(
///         factory: { StatefulView() },
///         states: {
///             "Initial state"
///             StatefulView.State.initial
///
///             "After user enter wrong data"
///             StatefulView.State.error("WTF Mate?")
///         }
///     )
///
/// - Important: If you getting compile error like "cannot convert () -> StatefulView to expected () -> _", make sure
/// that `StatefulView` defines `init()` and not use "default" objc one.
class ConcreteStatefulComponentTests<Component: StatefulComponent & Snapshotable>: AnyStatefulComponentTests {
    let make: () -> Component
    let states: [(String, Component.ComponentState)]

    init(factory: @escaping () -> Component, @StatefulComponentStatesBuilder states: () -> [(String, Component.ComponentState)]) {
        self.states = states()
        self.make = factory
    }

    var tests: [(String, () -> Snapshotable)] {
        return states.map { state in
            (state.0, { [make = self.make] in
                let component = make()
                component.prepareForSnapshot()
                component.transit(to: state.1)
                return component
            })
        }
    }
}

@_functionBuilder
struct StatefulComponentStatesBuilder {
    static func buildBlock<T>() -> [(String, T)] {
        return []
    }

    static func buildBlock<T>(_ name: String, _ state: T) -> [(String, T)] {
        return [(name, state)]
    }

    static func buildBlock<T>(_ name: String, _ state: T, _ rest: Any...) -> [(String, T)] {
        var res: [(String, T)] = [(name, state)]
        for i in stride(from: 0, to: rest.endIndex, by: 2) {
            guard let name = rest[i] as? String else {
                fatalError("Unexpected type of \(i + 3)th argument: \(type(of: rest[i])) expect String")
            }
            guard let state = rest[i + 1] as? T else {
                fatalError("Unexpected type of \(i + 4)th argument: \(type(of: rest[i + 1])) expect \(T.self)")
            }
            res.append((name, state))
        }
        return res
    }
}