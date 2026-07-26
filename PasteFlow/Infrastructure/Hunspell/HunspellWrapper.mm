#import "HunspellWrapper.h"
#include "src/hunspell.hxx"
#include <memory>
#include <string>

@implementation HunspellWrapper {
    std::unique_ptr<Hunspell> _hunspell;
}

- (nullable instancetype)initWithDicPath:(NSString *)dicPath affPath:(NSString *)affPath {
    self = [super init];
    if (self) {
        if (!dicPath || !affPath) {
            return nil;
        }
        _hunspell = std::make_unique<Hunspell>(affPath.UTF8String, dicPath.UTF8String);
        if (!_hunspell) {
            return nil;
        }
    }
    return self;
}

- (BOOL)isCorrect:(NSString *)word {
    if (!word || word.length == 0 || !_hunspell) {
        return YES;
    }
    std::string stdWord = [word UTF8String];
    return _hunspell->spell(stdWord);
}

- (NSArray<NSString *> *)suggest:(NSString *)word {
    if (!word || word.length == 0 || !_hunspell) {
        return @[];
    }
    std::string stdWord = [word UTF8String];
    std::vector<std::string> suggestions = _hunspell->suggest(stdWord);
    
    NSMutableArray<NSString *> *result = [NSMutableArray arrayWithCapacity:suggestions.size()];
    for (const auto &sugg : suggestions) {
        NSString *str = [NSString stringWithUTF8String:sugg.c_str()];
        if (str) {
            [result addObject:str];
        }
    }
    return result;
}

@end
