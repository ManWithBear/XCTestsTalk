//
//  ---------------------------------------
// < Copyright © 2019 Showmax. MIT License >
//  ---------------------------------------
//                        \
//                         \
//                          \ >()_
//                             (__)__ _

#import "DPTestCase.h"
#import <objc/runtime.h>

@interface _DPSelectorWrapper ()
@property(nonatomic, assign) SEL selector;
@end

@implementation _DPSelectorWrapper
- (instancetype)initWithSelector:(SEL)selector {
    self = [super init];
    _selector = selector;
    return self;
}
@end

@implementation _DPTestCase
+ (NSArray<NSInvocation *> *)testInvocations {
    NSMutableArray<NSInvocation *> *invocations = [self prefixInvocations];
    NSArray<_DPSelectorWrapper *> *wrappers = [self _dp_testMethodSelectors];

    for (_DPSelectorWrapper *wrapper in wrappers) {
        SEL selector = wrapper.selector;
        NSMethodSignature *signature = [self instanceMethodSignatureForSelector: selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature: signature];
        invocation.selector = selector;
        [invocations addObject: invocation];
    }

    return invocations;
}

+ (NSMutableArray<NSInvocation *> *)prefixInvocations {
    uint count;
    Method * methods = class_copyMethodList(self, &count);
    NSMutableArray<NSInvocation *> *invocations = [NSMutableArray array];
    for (uint i = 0; i < count; i++) {
        Method method = methods[i];
        SEL selector = method_getName(method);
        NSArray *nameParts = [[NSString stringWithCString: sel_getName(selector)
                                                 encoding: NSUTF8StringEncoding] componentsSeparatedByString: @"_"];
        if (nameParts.count < 2) { continue; }

        IMP imp = method_getImplementation(method);
        void (*callableImp)(id) = (void (*)(id))imp;
        id newImpBlock = [self _impForMethodWithPrefix: nameParts[0]
                                           currentImpl: ^(XCTestCase *test){ callableImp(test); }];
        if (!newImpBlock) { continue; }
        IMP newImp = imp_implementationWithBlock(newImpBlock);
        method_setImplementation(method, newImp);

        NSMethodSignature *signature = [self instanceMethodSignatureForSelector: selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature: signature];
        invocation.selector = selector;
        [invocations addObject: invocation];
    }
    free(methods);
    return invocations;
}

+ (void (^)(XCTestCase *))_impForMethodWithPrefix:(NSString *)prefix currentImpl:(void (^)(XCTestCase *))imp {
    if ([prefix isEqualToString: @"test"]) {
        return imp;
    }
    return NULL;
}

+ (NSArray<_DPSelectorWrapper *> *)_dp_testMethodSelectors {
    return @[];
}
@end
