//
//  UIView+UIAutomationBridge.m
//  Frank
//
//  Created by Pete Hodgson on 6/27/12.
//  Copyright (c) 2012 ThoughtWorks. All rights reserved.
//

#import "UIAutomation.h"

#import "LoadableCategory.h"
MAKE_CATEGORIES_LOADABLE(UIView_UIAutomationBridge)

CGPoint centerOfViewInWindowCoords(UIView *view){
    CGPoint centerPoint = CGPointMake(view.frame.size.width * 0.5f, view.frame.size.height * 0.5f);
    return [view.window convertPoint:centerPoint fromView:view];
}

UIASyntheticEvents *events(){
    return [NSClassFromString(@"UIASyntheticEvents") sharedEventGenerator];
}

@implementation UIView (UIAutomationBridge)

- (id) FUI_tap{
    CGPoint tapPoint = centerOfViewInWindowCoords(self);
    [events() sendTap:tapPoint];

    return [NSValue valueWithCGPoint:tapPoint];
}

// THESE MAGIC NUMBERS ARE IMPORTANT. From experimentation it appears that too big or too small a ration leads to 
// gestures not being recognized as such by the system. For example setting the big ratio to 0.4 leads to 
// swipe-to-delete not working on UITableViewCells.
// Also note that we always include at least a small component in each axes because in the past totally 'right-angled'
//swipes weren't detected properly. But we were using a different approach to touch simulation then,
//so this might now be unnecessary.
#define BIG_RATIO (0.3)
#define SMALL_RATIO (0.05)
#define SWIPE_DURATION (0.1)

//returns what portion of the view to swipe along in the x and y axes.
CGSize swipeRatiosForDirection(NSString *direction){
    NSString *dir = [direction lowercaseString];
    
    if([dir isEqualToString:@"left"]){
        return CGSizeMake(-BIG_RATIO, SMALL_RATIO);
    }else if([dir isEqualToString:@"right"]){
        return CGSizeMake(BIG_RATIO, SMALL_RATIO);
    }else if([dir isEqualToString:@"up"]){
        return CGSizeMake(SMALL_RATIO, -BIG_RATIO);
    }else if([dir isEqualToString:@"down"]){
        return CGSizeMake(SMALL_RATIO, BIG_RATIO);
    }else{
        [NSException raise:@"invalid swipe direction" format:@"swipe direction '%@' is invalid", direction];
        return CGSizeZero; // just here to stop the compiler whining.
    }
}

- (NSString *) FUI_swipe:(NSString *)dir{
    CGPoint swipeStart = centerOfViewInWindowCoords(self);
    CGSize ratios = swipeRatiosForDirection(dir);
    CGSize viewSize = self.bounds.size;
    CGPoint swipeEnd = CGPointMake(
                                   swipeStart.x+(ratios.width*viewSize.width),
                                   swipeStart.y+(ratios.height*viewSize.height)
                                   );
    
    NSString *swipeDescription = [NSString stringWithFormat:@"%@ => %@", NSStringFromCGPoint(swipeStart), NSStringFromCGPoint(swipeEnd)];
    
    [events() sendDragWithStartPoint:swipeStart endPoint:swipeEnd duration:SWIPE_DURATION];

    return swipeDescription;
}


- (id) automationElement{
    CGPoint centerPoint = CGPointMake(self.frame.size.width * 0.5f, self.frame.size.height * 0.5f);
    CGPoint centerPointInWindowCoords = [self.window convertPoint:centerPoint fromView:self];
    
    UIAXElement *axEl = [UIAXElement uiaxElementAtPosition:centerPointInWindowCoords];
    
    // both of the following lock up. According to Eloy's notes they might not work when run from the foreground app??
    UIAElement *element = [UIAElement elementForUIAXElement:axEl];
    //UIAElement *element = [NSClassFromString(@"UIAElement") elementAtPosition:centerPointInWindowCoords];
    
    return element;
}


@end
