//
//  ---------------------------------------
// < Copyright © 2019 Showmax. MIT License >
//  ---------------------------------------
//                        \
//                         \
//                          \ >()_
//                             (__)__ _

#import <XCTest/XCTest.h>

/// Based on https://stackoverflow.com/a/55204082/4280337
/// Thanks Quick team for inspiration
/// https://github.com/Quick/Quick/pull/687/files#diff-b3e6cf09655a7ef9fecc514ef310cdb8

NS_ASSUME_NONNULL_BEGIN
/// SEL is just pointer on C struct so we cannot put it inside of NSArray.
/// Instead we use this class as wrapper.
@interface _DPSelectorWrapper : NSObject
- (instancetype)initWithSelector:(SEL)selector;
@end

@interface _DPTestCase : XCTestCase
/// List of runtime test methods to call. By default return nothing
+ (NSArray<_DPSelectorWrapper *> *)_dp_testMethodSelectors;

/// Wrap method implementation in additional code. e.g. all methods with "snapshot" prefix need to make snapshot in the end.
/// Return `nil`/`NULL` if prefix should be ignored
/// @param prefix method prefix without '_'. e.g. "e2e_detail" has "e2e" prefix
/// @param imp actual implementation of method
+ (nullable void (^)(XCTestCase *))_impForMethodWithPrefix:(NSString *)prefix currentImpl:(void (^)(XCTestCase *))imp;
@end
NS_ASSUME_NONNULL_END
