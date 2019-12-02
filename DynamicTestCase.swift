//
//  ---------------------------------------
// < Copyright © 2019 Showmax. MIT License >
//  ---------------------------------------
//                        \
//                         \
//                          \ >()_
//                             (__)__ _

import Foundation

/// Test case with ability to specify runtime test and change behaviour based on method prefix.
///
/// Adds 2 dynamic feature:
/// 1. Specify runtime tests by overriding `runtimeTests()` method.
///     Handy when you have bunch of test doing same staff with just different parameters.
///
/// 2. Add common behaviour to all tests with same prefix by overriding `methodImplementation(for:currentImp:)` method.
///     Side effect is ability to declare tests with any prefix not only `test_`, so go on, show your imagination.
///     Prefix is first subsctring till `_` symbol.
///
/// Second feature do not affect tests from first feature.
class DynamicTestCase: _DPTestCase {
    struct RuntimeTest {
        let name: String
        let implementation: (DynamicTestCase) -> Void
    }

    /// Change method implementation for all functions with provided prefix.
    ///
    /// Return `nil` to ignore method or `currentImp` no need of change.
    /// In most cases you want to call `currentImp` inside your implementation, but don't need to.
    ///
    ///     func methodImplementation(....) {
    ///         if prefix == "duck" {
    ///             return { test in
    ///                 currentImp(test)
    ///                 print("quack!")
    ///             }
    ///         }
    ///         ...
    ///     }
    ///
    /// Will print out `quack!` after each test starting with `duck_` e.g. `func duck_needs_to_fly() {...}`
    class func methodImplementation(for prefix: String, currentImp: @escaping (XCTestCase) -> Void) -> ((XCTestCase) -> Void)? {
        return nil
    }

    /// List of tests, that will be generated in runtime.
    class func runtimeTests() -> [RuntimeTest] {
        return []
    }

    // MARK: - Private
    override class func _dp_testMethodSelectors() -> [_DPSelectorWrapper] {
        return runtimeTests().map { test in
            /// first we wrap our test method in block that takes TestCase instance
            let block: @convention(block) (DynamicTestCase) -> Void = { testCase in test.implementation(testCase) }
            /// with help of ObjC runtime we add new test method to class
            let implementation = imp_implementationWithBlock(block)
            let selectorName = test.name
            let selector = NSSelectorFromString(selectorName)
            class_addMethod(self, selector, implementation, "v@:")
            /// and return wrapped selector on new created method
            return _DPSelectorWrapper(selector: selector)
        }
    }

    override class func _impForMethod(withPrefix prefix: String, currentImpl imp: @escaping (XCTestCase) -> Void) -> ((XCTestCase) -> Void)? {
        return self.methodImplementation(for: prefix, currentImp: imp)
            ?? super._impForMethod(withPrefix: prefix, currentImpl: imp)
    }
}
