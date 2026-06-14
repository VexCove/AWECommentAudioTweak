#line 1 "Tweak/Tweak.x"



#import "AWECAHeaders.h"
#import "AWECAUtils.h"
#import "AWECADownloadManager.h"
#import "AWECAAudioReplacer.h"
#import "AWECAAudioPickerController.h"
#import "AWECATTSController.h"
#import <objc/runtime.h>
#import <objc/message.h>


static void setupAudioIconElementHook(void);
static void setupAudioInputElementHook(void);
static void setupTrailingIconElementHooks(void);
static void setupStackViewLayoutHook(void);
static char kAWECAAIContainerKey;
static char kAWECAPoiElementViewKey;
static char kAWECAPlusElementViewKey;




#include <substrate.h>
#if defined(__clang__)
#if __has_feature(objc_arc)
#define _LOGOS_SELF_TYPE_NORMAL __unsafe_unretained
#define _LOGOS_SELF_TYPE_INIT __attribute__((ns_consumed))
#define _LOGOS_SELF_CONST const
#define _LOGOS_RETURN_RETAINED __attribute__((ns_returns_retained))
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif

__asm__(".linker_option \"-framework\", \"CydiaSubstrate\"");

@class AWECommentAudioRecorderController; @class AWECommentLongPressPanelAdaptar; @class AWECommentAudioPlayerManager; @class AWECommentAudioUploadManager;
static void (*_logos_orig$_ungrouped$AWECommentAudioRecorderController$audioRecorderDidFinishRecording$success$error$)(_LOGOS_SELF_TYPE_NORMAL AWECommentAudioRecorderController* _LOGOS_SELF_CONST, SEL, id, BOOL, id); static void _logos_method$_ungrouped$AWECommentAudioRecorderController$audioRecorderDidFinishRecording$success$error$(_LOGOS_SELF_TYPE_NORMAL AWECommentAudioRecorderController* _LOGOS_SELF_CONST, SEL, id, BOOL, id); static void (*_logos_orig$_ungrouped$AWECommentAudioRecorderController$setAudioFilePath$)(_LOGOS_SELF_TYPE_NORMAL AWECommentAudioRecorderController* _LOGOS_SELF_CONST, SEL, NSString *); static void _logos_method$_ungrouped$AWECommentAudioRecorderController$setAudioFilePath$(_LOGOS_SELF_TYPE_NORMAL AWECommentAudioRecorderController* _LOGOS_SELF_CONST, SEL, NSString *); static void (*_logos_orig$_ungrouped$AWECommentAudioPlayerManager$playAudioWithVideoModel$startTime$audioEffectExternInfo$)(_LOGOS_SELF_TYPE_NORMAL AWECommentAudioPlayerManager* _LOGOS_SELF_CONST, SEL, id, double, id); static void _logos_method$_ungrouped$AWECommentAudioPlayerManager$playAudioWithVideoModel$startTime$audioEffectExternInfo$(_LOGOS_SELF_TYPE_NORMAL AWECommentAudioPlayerManager* _LOGOS_SELF_CONST, SEL, id, double, id); static void (*_logos_orig$_ungrouped$AWECommentAudioPlayerManager$playAudioWithVideoModel$startTime$)(_LOGOS_SELF_TYPE_NORMAL AWECommentAudioPlayerManager* _LOGOS_SELF_CONST, SEL, id, double); static void _logos_method$_ungrouped$AWECommentAudioPlayerManager$playAudioWithVideoModel$startTime$(_LOGOS_SELF_TYPE_NORMAL AWECommentAudioPlayerManager* _LOGOS_SELF_CONST, SEL, id, double); static void (*_logos_orig$_ungrouped$AWECommentLongPressPanelAdaptar$showLongPressPanelWithParam$config$showSheetCompletion$dismissSheetCompletion$)(_LOGOS_SELF_TYPE_NORMAL AWECommentLongPressPanelAdaptar* _LOGOS_SELF_CONST, SEL, id, id, id, id); static void _logos_method$_ungrouped$AWECommentLongPressPanelAdaptar$showLongPressPanelWithParam$config$showSheetCompletion$dismissSheetCompletion$(_LOGOS_SELF_TYPE_NORMAL AWECommentLongPressPanelAdaptar* _LOGOS_SELF_CONST, SEL, id, id, id, id); static void (*_logos_orig$_ungrouped$AWECommentAudioUploadManager$startUploadAudioWithFilePath$)(_LOGOS_SELF_TYPE_NORMAL AWECommentAudioUploadManager* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$_ungrouped$AWECommentAudioUploadManager$startUploadAudioWithFilePath$(_LOGOS_SELF_TYPE_NORMAL AWECommentAudioUploadManager* _LOGOS_SELF_CONST, SEL, id); static void (*_logos_orig$_ungrouped$AWECommentAudioUploadManager$uploadAudioWithFilePath$completion$)(_LOGOS_SELF_TYPE_NORMAL AWECommentAudioUploadManager* _LOGOS_SELF_CONST, SEL, id, id); static void _logos_method$_ungrouped$AWECommentAudioUploadManager$uploadAudioWithFilePath$completion$(_LOGOS_SELF_TYPE_NORMAL AWECommentAudioUploadManager* _LOGOS_SELF_CONST, SEL, id, id); static void (*_logos_orig$_ungrouped$AWECommentAudioUploadManager$uploadAudioWithFilePath$authCompletion$completion$)(_LOGOS_SELF_TYPE_NORMAL AWECommentAudioUploadManager* _LOGOS_SELF_CONST, SEL, id, id, id); static void _logos_method$_ungrouped$AWECommentAudioUploadManager$uploadAudioWithFilePath$authCompletion$completion$(_LOGOS_SELF_TYPE_NORMAL AWECommentAudioUploadManager* _LOGOS_SELF_CONST, SEL, id, id, id);

#line 24 "Tweak/Tweak.x"


static void _logos_method$_ungrouped$AWECommentAudioRecorderController$audioRecorderDidFinishRecording$success$error$(_LOGOS_SELF_TYPE_NORMAL AWECommentAudioRecorderController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id recorder, BOOL success, id error) {
    if (success && [AWECAAudioReplacer shared].enabled) {
        NSString *recorderURL = self.recorder.url.path;
        _logos_orig$_ungrouped$AWECommentAudioRecorderController$audioRecorderDidFinishRecording$success$error$(self, _cmd, recorder, success, error);
        NSString *pathAfter = self.audioFilePath;

        if (pathAfter.length > 0) {
            [[AWECAAudioReplacer shared] replaceAudioAtPath:pathAfter];
        } else if (recorderURL.length > 0) {
            [[AWECAAudioReplacer shared] replaceAudioAtPath:recorderURL];
        }
        [AWECAUtils showToast:@"语音已替换"];
    } else {
        _logos_orig$_ungrouped$AWECommentAudioRecorderController$audioRecorderDidFinishRecording$success$error$(self, _cmd, recorder, success, error);
    }
}

static void _logos_method$_ungrouped$AWECommentAudioRecorderController$setAudioFilePath$(_LOGOS_SELF_TYPE_NORMAL AWECommentAudioRecorderController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NSString * audioFilePath) {
    _logos_orig$_ungrouped$AWECommentAudioRecorderController$setAudioFilePath$(self, _cmd, audioFilePath);
    if (!audioFilePath.length) return;
    if (![AWECAAudioReplacer shared].enabled) return;
    if ([[NSFileManager defaultManager] fileExistsAtPath:audioFilePath]) {
        [[AWECAAudioReplacer shared] replaceAudioAtPath:audioFilePath];
    }
}







static void _logos_method$_ungrouped$AWECommentAudioPlayerManager$playAudioWithVideoModel$startTime$audioEffectExternInfo$(_LOGOS_SELF_TYPE_NORMAL AWECommentAudioPlayerManager* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id videoModel, double startTime, id info) {
    if (videoModel && [videoModel isKindOfClass:[NSString class]]) {
        NSString *jsonStr = (NSString *)videoModel;
        [[AWECADownloadManager shared] parseAndCacheVideoModelJSON:jsonStr];
    }
    _logos_orig$_ungrouped$AWECommentAudioPlayerManager$playAudioWithVideoModel$startTime$audioEffectExternInfo$(self, _cmd, videoModel, startTime, info);
}

static void _logos_method$_ungrouped$AWECommentAudioPlayerManager$playAudioWithVideoModel$startTime$(_LOGOS_SELF_TYPE_NORMAL AWECommentAudioPlayerManager* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id videoModel, double startTime) {
    if (videoModel && [videoModel isKindOfClass:[NSString class]]) {
        [[AWECADownloadManager shared] parseAndCacheVideoModelJSON:(NSString *)videoModel];
    }
    _logos_orig$_ungrouped$AWECommentAudioPlayerManager$playAudioWithVideoModel$startTime$(self, _cmd, videoModel, startTime);
}







static void _logos_method$_ungrouped$AWECommentLongPressPanelAdaptar$showLongPressPanelWithParam$config$showSheetCompletion$dismissSheetCompletion$(_LOGOS_SELF_TYPE_NORMAL AWECommentLongPressPanelAdaptar* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id param, id config, id showCompletion, id dismissCompletion) {

    _logos_orig$_ungrouped$AWECommentLongPressPanelAdaptar$showLongPressPanelWithParam$config$showSheetCompletion$dismissSheetCompletion$(self, _cmd, param, config, showCompletion, dismissCompletion);


    AWECommentModel *comment = nil;
    if ([param respondsToSelector:@selector(selectdComment)]) {
        comment = [(AWECommentLongPressPanelParam *)param selectdComment];
    }

    if (!comment || !comment.audioModel) {
        return;
    }


    AWECommentModel *savedComment = comment;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[AWECADownloadManager shared] showSaveDialogAndDownload:savedComment];
    });
}







static void _logos_method$_ungrouped$AWECommentAudioUploadManager$startUploadAudioWithFilePath$(_LOGOS_SELF_TYPE_NORMAL AWECommentAudioUploadManager* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id filePath) {
    if ([AWECAAudioReplacer shared].enabled && filePath) {
        NSString *path = (NSString *)filePath;
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [[AWECAAudioReplacer shared] replaceAudioAtPath:path];
        }
    }
    _logos_orig$_ungrouped$AWECommentAudioUploadManager$startUploadAudioWithFilePath$(self, _cmd, filePath);
}

static void _logos_method$_ungrouped$AWECommentAudioUploadManager$uploadAudioWithFilePath$completion$(_LOGOS_SELF_TYPE_NORMAL AWECommentAudioUploadManager* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id filePath, id completion) {
    if ([AWECAAudioReplacer shared].enabled && filePath) {
        NSString *path = (NSString *)filePath;
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [[AWECAAudioReplacer shared] replaceAudioAtPath:path];
        }
    }
    _logos_orig$_ungrouped$AWECommentAudioUploadManager$uploadAudioWithFilePath$completion$(self, _cmd, filePath, completion);
}

static void _logos_method$_ungrouped$AWECommentAudioUploadManager$uploadAudioWithFilePath$authCompletion$completion$(_LOGOS_SELF_TYPE_NORMAL AWECommentAudioUploadManager* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id filePath, id authCompletion, id completion) {
    if ([AWECAAudioReplacer shared].enabled && filePath) {
        NSString *path = (NSString *)filePath;
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [[AWECAAudioReplacer shared] replaceAudioAtPath:path];
        }
    }
    _logos_orig$_ungrouped$AWECommentAudioUploadManager$uploadAudioWithFilePath$authCompletion$completion$(self, _cmd, filePath, authCompletion, completion);
}






static void (*orig_generateAudioPreviewBubble)(id self, SEL _cmd, id recordedModel);
static void hook_generateAudioPreviewBubble(id self, SEL _cmd, id recordedModel) {
    if (recordedModel && [AWECAAudioReplacer shared].enabled) {
        NSString *audioPath = [recordedModel valueForKey:@"audioFilePath"];

        if (audioPath.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:audioPath]) {
            BOOL ok = [[AWECAAudioReplacer shared] replaceAudioAtPath:audioPath];

            if (ok) {
                double realDur = [AWECAUtils audioDurationAtPath:audioPath];
                long long realMs = (long long)(realDur * 1000);
                [recordedModel setValue:@(realMs) forKey:@"duration"];
            }
        }
    }
    orig_generateAudioPreviewBubble(self, _cmd, recordedModel);
}

static void setupAudioInputElementHook(void) {
    Class cls = NSClassFromString(@"AWECommentInputViewSwiftImpl.CommentInputAudioInputElement");
    if (!cls) {
        return;
    }
    SEL sel = @selector(generateAudioPreviewBubbleWithRecordedModel:);
    Method method = class_getInstanceMethod(cls, sel);
    if (method) {
        orig_generateAudioPreviewBubble = (void (*)(id, SEL, id))method_getImplementation(method);
        method_setImplementation(method, (IMP)hook_generateAudioPreviewBubble);
    }
}




static void aweca_aiButtonTappedIMP(id self, SEL _cmd) {
    UIViewController *vc = [AWECAUtils topViewController];
    AWECATTSController *tts = [[AWECATTSController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:tts];
    nav.modalPresentationStyle = UIModalPresentationPageSheet;
    if (@available(iOS 16.0, *)) {
        UISheetPresentationController *sheet = nav.sheetPresentationController;
        if (sheet) {

            UISheetPresentationControllerDetent *fit = [UISheetPresentationControllerDetent
                customDetentWithIdentifier:@"ttsCompact"
                resolver:^CGFloat(id<UISheetPresentationControllerDetentResolutionContext> ctx) {
                    return 256;
                }];
            sheet.detents = @[fit, UISheetPresentationControllerDetent.largeDetent];
            sheet.selectedDetentIdentifier = @"ttsCompact";
            sheet.prefersGrabberVisible = YES;
        }
    } else if (@available(iOS 15.0, *)) {
        UISheetPresentationController *sheet = nav.sheetPresentationController;
        if (sheet) {
            sheet.detents = @[UISheetPresentationControllerDetent.mediumDetent,
                              UISheetPresentationControllerDetent.largeDetent];
            sheet.prefersGrabberVisible = YES;
        }
    }
    [vc presentViewController:nav animated:YES completion:nil];
}


static void aweca_updateAIButtonPosition(UIView *stackView) {
    UIView *aiContainer = objc_getAssociatedObject(stackView, &kAWECAAIContainerKey);
    if (!aiContainer) return;

    Class evClass = NSClassFromString(@"AWEBaseElementView");
    if (!evClass) return;

    UIView *overlayHost = stackView.superview;
    if (!overlayHost) {
        aiContainer.hidden = YES;
        return;
    }
    if (aiContainer.superview != overlayHost) {
        [aiContainer removeFromSuperview];
        [overlayHost addSubview:aiContainer];
    }

    NSMutableArray<UIView *> *elements = [NSMutableArray array];
    for (UIView *sub in stackView.subviews) {
        if (![sub isKindOfClass:evClass]) continue;
        if (sub.hidden || sub.alpha < 0.01 || CGRectIsEmpty(sub.frame)) continue;
        [elements addObject:sub];
    }
    [elements sortUsingComparator:^NSComparisonResult(UIView *left, UIView *right) {
        if (CGRectGetMinX(left.frame) < CGRectGetMinX(right.frame)) return NSOrderedAscending;
        if (CGRectGetMinX(left.frame) > CGRectGetMinX(right.frame)) return NSOrderedDescending;
        return NSOrderedSame;
    }];

    NSUInteger audioIndex = [elements indexOfObjectPassingTest:^BOOL(UIView *element, NSUInteger idx, BOOL *stop) {
        return [element viewWithTag:19527] != nil;
    }];
    if (audioIndex == NSNotFound) {
        aiContainer.hidden = YES;
        aiContainer.alpha = 0.0;
        return;
    }
    UIView *audioElement = elements[audioIndex];

    UIView *poiElement = nil;
    UIView *plusElement = nil;
    for (UIView *element in elements) {
        if (objc_getAssociatedObject(element, &kAWECAPoiElementViewKey)) {
            poiElement = element;
        } else if (objc_getAssociatedObject(element, &kAWECAPlusElementViewKey)) {
            plusElement = element;
        }
    }


    NSMutableArray<UIView *> *orderedElements = [NSMutableArray array];
    for (UIView *element in elements) {
        if (element == poiElement || element == plusElement) continue;
        [orderedElements addObject:element];
    }
    NSUInteger orderedAudioIndex = [orderedElements indexOfObject:audioElement];
    if (orderedAudioIndex == NSNotFound) {
        aiContainer.hidden = YES;
        return;
    }
    NSUInteger trailingInsertIndex = orderedAudioIndex + 1;
    if (plusElement) {
        [orderedElements insertObject:plusElement atIndex:trailingInsertIndex++];
    }
    if (poiElement) {
        [orderedElements insertObject:poiElement atIndex:trailingInsertIndex];
    }

    CGFloat firstCenterX = CGRectGetMidX(elements.firstObject.frame);
    CGFloat lastCenterX = CGRectGetMidX(elements.lastObject.frame);
    NSUInteger totalSlotCount = orderedElements.count + 1;
    if (totalSlotCount < 2 || lastCenterX <= firstCenterX) {
        aiContainer.hidden = YES;
        return;
    }
    CGFloat slotWidth = (lastCenterX - firstCenterX) / (CGFloat)(totalSlotCount - 1);
    NSUInteger aiSlotIndex = orderedAudioIndex + 1;


    for (NSUInteger index = 0; index < orderedElements.count; index++) {
        UIView *element = orderedElements[index];
        NSUInteger slotIndex = index < aiSlotIndex ? index : index + 1;
        CGRect frame = element.frame;
        frame.origin.x = firstCenterX + slotWidth * slotIndex - CGRectGetWidth(frame) * 0.5;
        element.frame = frame;
    }

    CGFloat buttonSize = 24.0;
    CGRect aiFrameInStack = CGRectMake(
        firstCenterX + slotWidth * aiSlotIndex - buttonSize * 0.5,
        CGRectGetMidY(audioElement.frame) - buttonSize * 0.5,
        buttonSize,
        buttonSize
    );
    aiContainer.frame = [stackView convertRect:aiFrameInStack toView:overlayHost];
    aiContainer.hidden = NO;
    aiContainer.alpha = 1.0;
    [overlayHost bringSubviewToFront:aiContainer];


    UIButton *aiBtn = nil;
    for (UIView *sub in aiContainer.subviews) {
        if ([sub isKindOfClass:[UIButton class]]) {
            aiBtn = (UIButton *)sub;
            break;
        }
    }
    if (aiBtn) {
        Class themeMgr = NSClassFromString(@"AWEUIThemeManager");
        BOOL isLight = themeMgr ? [themeMgr isLightTheme] : NO;
        aiBtn.tintColor = isLight ? [UIColor blackColor] : [UIColor whiteColor];
    }
}

static void (*orig_audioIconViewDidLoad)(id self, SEL _cmd);
static void hook_audioIconViewDidLoad(id self, SEL _cmd) {
    orig_audioIconViewDidLoad(self, _cmd);

    UIView *elementView = nil;
    if ([self respondsToSelector:@selector(view)]) {
        elementView = [self performSelector:@selector(view)];
    }
    if (!elementView) return;

    elementView.userInteractionEnabled = YES;
    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc]
                                         initWithTarget:elementView
                                         action:@selector(aweca_longPressAudioIcon:)];
    lp.minimumPressDuration = 0.5;
    [elementView addGestureRecognizer:lp];

    UIView *redDot = [[UIView alloc] initWithFrame:CGRectMake(elementView.bounds.size.width - 8, 2, 6, 6)];
    redDot.backgroundColor = [UIColor redColor];
    redDot.layer.cornerRadius = 3;
    redDot.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    redDot.hidden = ![AWECAAudioReplacer shared].enabled;
    redDot.tag = 19527;
    [elementView addSubview:redDot];


    UIView *stackView = elementView.superview;
    if (!stackView) return;
    if (objc_getAssociatedObject(stackView, &kAWECAAIContainerKey)) return;

    UIView *aiContainer = [[UIView alloc] initWithFrame:CGRectZero];
    aiContainer.tag = 19528;
    aiContainer.userInteractionEnabled = YES;
    objc_setAssociatedObject(stackView, &kAWECAAIContainerKey, aiContainer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    UIButton *aiBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightRegular];
    UIImage *aiIcon = [UIImage systemImageNamed:@"icloud.circle" withConfiguration:cfg];
    [aiBtn setImage:aiIcon forState:UIControlStateNormal];


    Class themeMgr = NSClassFromString(@"AWEUIThemeManager");
    BOOL isLight = themeMgr ? [themeMgr isLightTheme] : NO;
    aiBtn.tintColor = isLight ? [UIColor blackColor] : [UIColor whiteColor];
    aiBtn.frame = CGRectMake(0, 0, 24, 24);
    [aiBtn addTarget:stackView action:@selector(aweca_aiButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [aiContainer addSubview:aiBtn];

    [stackView setNeedsLayout];
}

static void aweca_longPressAudioIconIMP(id self, SEL _cmd, UILongPressGestureRecognizer *gesture) {
    if (gesture.state != UIGestureRecognizerStateBegan) return;
    UIViewController *vc = [AWECAUtils topViewController];
    [[AWECAAudioPickerController shared] showPickerFromViewController:vc];
}

static void setupAudioIconElementHook(void) {
    Class cls = NSClassFromString(@"AWECommentInputViewSwiftImpl.CommentAudioIconElement");
    if (!cls) return;
    SEL sel = @selector(viewDidLoad);
    Method method = class_getInstanceMethod(cls, sel);
    if (method) {
        orig_audioIconViewDidLoad = (void (*)(id, SEL))method_getImplementation(method);
        method_setImplementation(method, (IMP)hook_audioIconViewDidLoad);
    }

    Class viewClass = NSClassFromString(@"AWEBaseElementView");
    if (!viewClass) viewClass = [UIView class];
    SEL lpSel = @selector(aweca_longPressAudioIcon:);
    if (!class_respondsToSelector(viewClass, lpSel)) {
        class_addMethod(viewClass, lpSel, (IMP)aweca_longPressAudioIconIMP, "v@:@");
    }

    Class stackClass = NSClassFromString(@"AWEElementStackView");
    if (!stackClass) stackClass = [UIView class];
    SEL aiSel = @selector(aweca_aiButtonTapped);
    if (!class_respondsToSelector(stackClass, aiSel)) {
        class_addMethod(stackClass, aiSel, (IMP)aweca_aiButtonTappedIMP, "v@:");
    }
}

static void (*orig_poiIconViewDidLoad)(id self, SEL _cmd);
static void hook_poiIconViewDidLoad(id self, SEL _cmd) {
    orig_poiIconViewDidLoad(self, _cmd);
    UIView *elementView = [self respondsToSelector:@selector(view)] ? [self performSelector:@selector(view)] : nil;
    if (elementView) {
        objc_setAssociatedObject(elementView, &kAWECAPoiElementViewKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

static void (*orig_plusIconViewDidLoad)(id self, SEL _cmd);
static void hook_plusIconViewDidLoad(id self, SEL _cmd) {
    orig_plusIconViewDidLoad(self, _cmd);
    UIView *elementView = [self respondsToSelector:@selector(view)] ? [self performSelector:@selector(view)] : nil;
    if (elementView) {
        objc_setAssociatedObject(elementView, &kAWECAPlusElementViewKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

static void setupTrailingIconElementHooks(void) {
    Class poiClass = NSClassFromString(@"AWECommentInputViewSwiftImpl.CommentPoiIconElement");
    Method poiMethod = class_getInstanceMethod(poiClass, @selector(viewDidLoad));
    if (poiMethod) {
        orig_poiIconViewDidLoad = (void (*)(id, SEL))method_getImplementation(poiMethod);
        const char *types = method_getTypeEncoding(poiMethod);
        if (!class_addMethod(poiClass, @selector(viewDidLoad), (IMP)hook_poiIconViewDidLoad, types)) {
            class_replaceMethod(poiClass, @selector(viewDidLoad), (IMP)hook_poiIconViewDidLoad, types);
        }
    }

    Class plusClass = NSClassFromString(@"AWECommentInputViewSwiftImpl.CommentPlusIconElement");
    Method plusMethod = class_getInstanceMethod(plusClass, @selector(viewDidLoad));
    if (plusMethod) {
        orig_plusIconViewDidLoad = (void (*)(id, SEL))method_getImplementation(plusMethod);
        const char *types = method_getTypeEncoding(plusMethod);
        if (!class_addMethod(plusClass, @selector(viewDidLoad), (IMP)hook_plusIconViewDidLoad, types)) {
            class_replaceMethod(plusClass, @selector(viewDidLoad), (IMP)hook_plusIconViewDidLoad, types);
        }
    }
}



static void (*orig_stackViewLayoutSubviews)(id self, SEL _cmd);
static void hook_stackViewLayoutSubviews(id self, SEL _cmd) {
    orig_stackViewLayoutSubviews(self, _cmd);

    UIView *sv = (UIView *)self;
    if (objc_getAssociatedObject(sv, &kAWECAAIContainerKey)) {
        aweca_updateAIButtonPosition(sv);
    }
}

static void setupStackViewLayoutHook(void) {
    Class cls = NSClassFromString(@"AWEElementStackView");
    if (!cls) return;
    SEL sel = @selector(layoutSubviews);
    Method method = class_getInstanceMethod(cls, sel);
    if (method) {
        orig_stackViewLayoutSubviews = (void (*)(id, SEL))method_getImplementation(method);
        method_setImplementation(method, (IMP)hook_stackViewLayoutSubviews);
    }
}



static __attribute__((constructor)) void _logosLocalCtor_30ebfd71(int __unused argc, char __unused **argv, char __unused **envp) {
    @autoreleasepool {
        [AWECAUtils ensureDirectoriesExist];

        [AWECAAudioReplacer shared];


        setupAudioInputElementHook();
        setupAudioIconElementHook();
        setupTrailingIconElementHooks();
        setupStackViewLayoutHook();
    }
}
static __attribute__((constructor)) void _logosLocalInit() {
{Class _logos_class$_ungrouped$AWECommentAudioRecorderController = objc_getClass("AWECommentAudioRecorderController"); { MSHookMessageEx(_logos_class$_ungrouped$AWECommentAudioRecorderController, @selector(audioRecorderDidFinishRecording:success:error:), (IMP)&_logos_method$_ungrouped$AWECommentAudioRecorderController$audioRecorderDidFinishRecording$success$error$, (IMP*)&_logos_orig$_ungrouped$AWECommentAudioRecorderController$audioRecorderDidFinishRecording$success$error$);}{ MSHookMessageEx(_logos_class$_ungrouped$AWECommentAudioRecorderController, @selector(setAudioFilePath:), (IMP)&_logos_method$_ungrouped$AWECommentAudioRecorderController$setAudioFilePath$, (IMP*)&_logos_orig$_ungrouped$AWECommentAudioRecorderController$setAudioFilePath$);}Class _logos_class$_ungrouped$AWECommentAudioPlayerManager = objc_getClass("AWECommentAudioPlayerManager"); { MSHookMessageEx(_logos_class$_ungrouped$AWECommentAudioPlayerManager, @selector(playAudioWithVideoModel:startTime:audioEffectExternInfo:), (IMP)&_logos_method$_ungrouped$AWECommentAudioPlayerManager$playAudioWithVideoModel$startTime$audioEffectExternInfo$, (IMP*)&_logos_orig$_ungrouped$AWECommentAudioPlayerManager$playAudioWithVideoModel$startTime$audioEffectExternInfo$);}{ MSHookMessageEx(_logos_class$_ungrouped$AWECommentAudioPlayerManager, @selector(playAudioWithVideoModel:startTime:), (IMP)&_logos_method$_ungrouped$AWECommentAudioPlayerManager$playAudioWithVideoModel$startTime$, (IMP*)&_logos_orig$_ungrouped$AWECommentAudioPlayerManager$playAudioWithVideoModel$startTime$);}Class _logos_class$_ungrouped$AWECommentLongPressPanelAdaptar = objc_getClass("AWECommentLongPressPanelAdaptar"); { MSHookMessageEx(_logos_class$_ungrouped$AWECommentLongPressPanelAdaptar, @selector(showLongPressPanelWithParam:config:showSheetCompletion:dismissSheetCompletion:), (IMP)&_logos_method$_ungrouped$AWECommentLongPressPanelAdaptar$showLongPressPanelWithParam$config$showSheetCompletion$dismissSheetCompletion$, (IMP*)&_logos_orig$_ungrouped$AWECommentLongPressPanelAdaptar$showLongPressPanelWithParam$config$showSheetCompletion$dismissSheetCompletion$);}Class _logos_class$_ungrouped$AWECommentAudioUploadManager = objc_getClass("AWECommentAudioUploadManager"); { MSHookMessageEx(_logos_class$_ungrouped$AWECommentAudioUploadManager, @selector(startUploadAudioWithFilePath:), (IMP)&_logos_method$_ungrouped$AWECommentAudioUploadManager$startUploadAudioWithFilePath$, (IMP*)&_logos_orig$_ungrouped$AWECommentAudioUploadManager$startUploadAudioWithFilePath$);}{ MSHookMessageEx(_logos_class$_ungrouped$AWECommentAudioUploadManager, @selector(uploadAudioWithFilePath:completion:), (IMP)&_logos_method$_ungrouped$AWECommentAudioUploadManager$uploadAudioWithFilePath$completion$, (IMP*)&_logos_orig$_ungrouped$AWECommentAudioUploadManager$uploadAudioWithFilePath$completion$);}{ MSHookMessageEx(_logos_class$_ungrouped$AWECommentAudioUploadManager, @selector(uploadAudioWithFilePath:authCompletion:completion:), (IMP)&_logos_method$_ungrouped$AWECommentAudioUploadManager$uploadAudioWithFilePath$authCompletion$completion$, (IMP*)&_logos_orig$_ungrouped$AWECommentAudioUploadManager$uploadAudioWithFilePath$authCompletion$completion$);}} }
#line 479 "Tweak/Tweak.x"
