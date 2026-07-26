#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HunspellWrapper : NSObject

- (nullable instancetype)initWithDicPath:(NSString *)dicPath affPath:(NSString *)affPath;
- (BOOL)isCorrect:(NSString *)word;
- (NSArray<NSString *> *)suggest:(NSString *)word;

@end

NS_ASSUME_NONNULL_END
