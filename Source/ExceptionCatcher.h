//
//  ExceptionCatcher.h
//  PodToBUILD
//
//  Created by Jerry Marino on 10/27/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

//
//  ExceptionCatcher.h
//

#import <Foundation/Foundation.h>    

NS_INLINE NSException * _Nullable tryBlock(void(^_Nonnull tryBlock)(void)) {
    @try {
        tryBlock();
    }
    @catch (NSException *e) {
        return e;
    }
    return nil;
}
