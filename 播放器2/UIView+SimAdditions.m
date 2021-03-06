#import "UIView+SimAdditions.h"
#import <objc/runtime.h>

static char SimViewTypeKey;

typedef NS_ENUM(NSInteger, SimViewType){
    SVT_Normal,
    SVT_TapResignFirstResponder,
    SVT_TapToAction
};


@implementation UIView (SimCategory)

- (BOOL)visible{
    return !self.hidden;
}

- (void)setVisible:(BOOL)visible{
    self.hidden = !visible;
}

- (CGFloat)left {
    return self.frame.origin.x;
}

- (void)setLeft:(CGFloat)x {
    CGRect frame = self.frame;
    if (frame.origin.x != x) {
        frame.origin.x = x;
        self.frame = frame;
    }
}

- (CGFloat)top {
    return self.frame.origin.y;
}

- (void)setTop:(CGFloat)y {
    CGRect frame = self.frame;
    if (frame.origin.y != y) {
        frame.origin.y = y;
        self.frame = frame;
    }
}

- (CGFloat)right {
    return self.frame.origin.x + self.frame.size.width;
}

- (void)setRight:(CGFloat)right {
    CGRect frame = self.frame;
    if (frame.origin.x != right - frame.size.width) {
        frame.origin.x = right - frame.size.width;
        self.frame = frame;
        
    }
}

- (CGFloat)bottom {
    return self.frame.origin.y + self.frame.size.height;
}

- (void)setBottom:(CGFloat)bottom {
    CGRect frame = self.frame;
    if (frame.origin.y != bottom - frame.size.height) {
        frame.origin.y = bottom - frame.size.height;
        self.frame = frame;
        
    }
}

- (CGFloat)centerX {
    return self.center.x;
}

- (void)setCenterX:(CGFloat)centerX {
    self.center = CGPointMake(centerX, self.center.y);
}

- (CGFloat)centerY {
    return self.center.y;
}

- (void)setCenterY:(CGFloat)centerY {
    self.center = CGPointMake(self.center.x, centerY);
}

- (CGFloat)width {
    return self.frame.size.width;
}

- (void)setWidth:(CGFloat)width {
    CGRect frame = self.frame;
    if (frame.size.width != width) {
        frame.size.width = width;
    }
    self.frame = frame;
}

- (CGFloat)height {
    return self.frame.size.height;
}

- (void)setHeight:(CGFloat)height {
    CGRect frame = self.frame;
    if (frame.size.height != height) {
        frame.size.height = height;
        self.frame = frame;
    }
}

- (CGFloat)screenX {
    CGFloat x = 0;
    for (UIView* view = self; view; view = view.superview) {
        x += view.left;
    }
    return x;
}

- (CGFloat)screenY {
    CGFloat y = 0;
    for (UIView* view = self; view; view = view.superview) {
        y += view.top;
    }
    return y;
}

- (CGFloat)screenViewX {
    CGFloat x = 0;
    for (UIView* view = self; view; view = view.superview) {
        x += view.left;
        
        if ([view isKindOfClass:[UIScrollView class]]) {
            UIScrollView* scrollView = (UIScrollView*)view;
            x -= scrollView.contentOffset.x;
        }
    }
    
    return x;
}

- (CGFloat)screenViewY {
    CGFloat y = 0;
    for (UIView* view = self; view; view = view.superview) {
        y += view.top;
        
        if ([view isKindOfClass:[UIScrollView class]]) {
            UIScrollView* scrollView = (UIScrollView*)view;
            y -= scrollView.contentOffset.y;
        }
    }
    return y;
}

- (CGRect)screenFrame {
    return CGRectMake(self.screenViewX, self.screenViewY, self.width, self.height);
}

- (CGPoint)origin {
    return self.frame.origin;
}

- (void)setOrigin:(CGPoint)origin {
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}

- (CGSize)size {
    return self.frame.size;
}

- (void)setSize:(CGSize)size {
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

- (CGPoint)offsetFromView:(UIView*)otherView {
    CGFloat x = 0, y = 0;
    for (UIView* view = self; view && view != otherView; view = view.superview) {
        x += view.left;
        y += view.top;
    }
    return CGPointMake(x, y);
}
/*
 - (CGFloat)orientationWidth {
 return UIInterfaceOrientationIsLandscape(TTInterfaceOrientation())
 ? self.height : self.width;
 }
 
 - (CGFloat)orientationHeight {
 return UIInterfaceOrientationIsLandscape(TTInterfaceOrientation())
 ? self.width : self.height;
 }
 */
- (UIView*)descendantOrSelfWithClass:(Class)cls {
    if ([self isKindOfClass:cls])
        return self;
    
    for (UIView* child in self.subviews) {
        UIView* it = [child descendantOrSelfWithClass:cls];
        if (it)
            return it;
    }
    
    return nil;
}

- (UIView*)ancestorOrSelfWithClass:(Class)cls {
    if ([self isKindOfClass:cls]) {
        return self;
    } else if (self.superview) {
        return [self.superview ancestorOrSelfWithClass:cls];
    } else {
        return nil;
    }
}

- (void)removeAllSubviews {
    while (self.subviews.count) {
        UIView* child = self.subviews.lastObject;
        [child removeFromSuperview];
    }
}



- (UIViewController*)sim_viewController {
    for (UIView* next = [self superview]; next; next = next.superview) {
        UIResponder* nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController*)nextResponder;
        }
    }
    return nil;
}

- (UIViewController*)viewController {
    for (UIView* next = [self superview]; next; next = next.superview) {
        UIResponder* nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController*)nextResponder;
        }
    }
    return nil;
}


#pragma mark -

- (void)tapResignFirstResponder
{
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapResignResponderViewRecognized:)];
    tapGesture.cancelsTouchesInView = NO;
    tapGesture.delegate = self;
    [self addGestureRecognizer:tapGesture];
    
    objc_setAssociatedObject(self, &SimViewTypeKey, @(SVT_TapResignFirstResponder), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
}

- (void)tapResignResponderViewRecognized:(UITapGestureRecognizer*)gesture  // (Enhancement ID: #14)
{
    if (gesture.state == UIGestureRecognizerStateEnded){
        SimViewType viewType = [objc_getAssociatedObject(self, &SimViewTypeKey) integerValue];
        if (SVT_TapResignFirstResponder == viewType) {
            [gesture.view endEditing:YES];
        }
        else if (SVT_TapToAction == viewType){
            SimViewTapBlock tapBlock = self.tapBlock;
            if (tapBlock) {
                tapBlock();
            }
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    SimViewType viewType = [objc_getAssociatedObject(self, &SimViewTypeKey) integerValue];
    if (SVT_TapResignFirstResponder == viewType) {
        if ([self.gestureRecognizers containsObject:gestureRecognizer] && [gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
            return touch.view == self;
        }
    }
    
    return YES;
}

#pragma mark - User Info
static char UIViewUserInfoPrivateKey;
- (void)setUserInfo:(id)userInfo
{
    objc_setAssociatedObject(self, &UIViewUserInfoPrivateKey, userInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)userInfo
{
    return objc_getAssociatedObject(self, &UIViewUserInfoPrivateKey);
}

#pragma mark - TapBlock
static char SimViewTapBlockKey;
- (void)setTapBlock:(SimViewTapBlock)tapBlock
{
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapResignResponderViewRecognized:)];
    tapGesture.delegate = self;
    [self addGestureRecognizer:tapGesture];
    objc_setAssociatedObject(self, &SimViewTypeKey, @(SVT_TapToAction), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    objc_setAssociatedObject(self, &SimViewTapBlockKey, tapBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (SimViewTapBlock)tapBlock
{
    return objc_getAssociatedObject(self, &SimViewTapBlockKey);
}


@end
