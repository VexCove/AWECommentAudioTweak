// AWECommentAudioTweak - 抖音评论语音 hook
// @cookieodd | github.com/cookieodd | t.me/cookieodd

#import "AWECAHeaders.h"
#import "AWECAUtils.h"
#import "AWECADownloadManager.h"
#import "AWECAAudioReplacer.h"
#import "AWECAAudioPickerController.h"
#import "AWECATTSController.h"
#import <objc/runtime.h>
#import <objc/message.h>

// 前置声明，别急后面有实现
static void setupAudioIconElementHook(void);
static void setupAudioInputElementHook(void);
static void setupTrailingIconElementHooks(void);
static void setupStackViewLayoutHook(void);
static char kAWECAAIContainerKey;
static char kAWECAAudioElementViewKey;
static char kAWECAPoiElementViewKey;
static char kAWECAPlusElementViewKey;

// === Hook 1: 录完就偷梁换柱 ===

%hook AWECommentAudioRecorderController

- (void)audioRecorderDidFinishRecording:(id)recorder success:(BOOL)success error:(id)error {
    if (success && [AWECAAudioReplacer shared].enabled) {
        NSString *recorderURL = self.recorder.url.path;
        %orig;
        NSString *pathAfter = self.audioFilePath;

        if (pathAfter.length > 0) {
            [[AWECAAudioReplacer shared] replaceAudioAtPath:pathAfter];
        } else if (recorderURL.length > 0) {
            [[AWECAAudioReplacer shared] replaceAudioAtPath:recorderURL];
        }
        [AWECAUtils showToast:@"语音已替换"];
    } else {
        %orig;
    }
}

- (void)setAudioFilePath:(NSString *)audioFilePath {
    %orig;
    if (!audioFilePath.length) return;
    if (![AWECAAudioReplacer shared].enabled) return;
    if ([[NSFileManager defaultManager] fileExistsAtPath:audioFilePath]) {
        [[AWECAAudioReplacer shared] replaceAudioAtPath:audioFilePath];
    }
}

%end

// === Hook 2: 播放时顺手把 CDN 链接薅了 ===

%hook AWECommentAudioPlayerManager

- (void)playAudioWithVideoModel:(id)videoModel startTime:(double)startTime audioEffectExternInfo:(id)info {
    if (videoModel && [videoModel isKindOfClass:[NSString class]]) {
        NSString *jsonStr = (NSString *)videoModel;
        [[AWECADownloadManager shared] parseAndCacheVideoModelJSON:jsonStr];
    }
    %orig;
}

- (void)playAudioWithVideoModel:(id)videoModel startTime:(double)startTime {
    if (videoModel && [videoModel isKindOfClass:[NSString class]]) {
        [[AWECADownloadManager shared] parseAndCacheVideoModelJSON:(NSString *)videoModel];
    }
    %orig;
}

%end

// === Hook 3: 长按菜单加个保存语音的活 ===

%hook AWECommentLongPressPanelAdaptar

- (void)showLongPressPanelWithParam:(id)param config:(id)config showSheetCompletion:(id)showCompletion dismissSheetCompletion:(id)dismissCompletion {
    // 先让原生面板该弹弹
    %orig;

    // 看看有没有语音
    AWECommentModel *comment = nil;
    if ([param respondsToSelector:@selector(selectdComment)]) {
        comment = [(AWECommentLongPressPanelParam *)param selectdComment];
    }

    if (!comment || !comment.audioModel) {
        return;
    }

    // 等动画跑完再弹，不然打架
    AWECommentModel *savedComment = comment;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[AWECADownloadManager shared] showSaveDialogAndDownload:savedComment];
    });
}

%end

// === Hook 5: 上传前再换一波，双保险 ===

%hook AWECommentAudioUploadManager

- (void)startUploadAudioWithFilePath:(id)filePath {
    if ([AWECAAudioReplacer shared].enabled && filePath) {
        NSString *path = (NSString *)filePath;
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [[AWECAAudioReplacer shared] replaceAudioAtPath:path];
        }
    }
    %orig;
}

- (void)uploadAudioWithFilePath:(id)filePath completion:(id)completion {
    if ([AWECAAudioReplacer shared].enabled && filePath) {
        NSString *path = (NSString *)filePath;
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [[AWECAAudioReplacer shared] replaceAudioAtPath:path];
        }
    }
    %orig;
}

- (void)uploadAudioWithFilePath:(id)filePath authCompletion:(id)authCompletion completion:(id)completion {
    if ([AWECAAudioReplacer shared].enabled && filePath) {
        NSString *path = (NSString *)filePath;
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [[AWECAAudioReplacer shared] replaceAudioAtPath:path];
        }
    }
    %orig;
}

%end


// === Hook 6: 预览气泡也得换，顺便修时长 ===

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

// === Hook 7: 语音按钮长按弹选择器，红点提示，AI按钮 ===

// AI按钮点击回调，打开TTS主页面
static void aweca_aiButtonTappedIMP(id self, SEL _cmd) {
    UIViewController *vc = [AWECAUtils topViewController];
    AWECATTSController *tts = [[AWECATTSController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:tts];
    nav.modalPresentationStyle = UIModalPresentationPageSheet;
    if (@available(iOS 16.0, *)) {
        UISheetPresentationController *sheet = nav.sheetPresentationController;
        if (sheet) {
            // 紧凑 + 全屏两档，默认紧凑
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

static BOOL aweca_isAudioElementView(UIView *element) {
    return objc_getAssociatedObject(element, &kAWECAAudioElementViewKey) != nil || [element viewWithTag:19527] != nil;
}

// AI 按钮挂回 stackView 以跟随原生动画；layout 前会临时移除，避免被原生布局计入按钮数量。
static void aweca_updateAIButtonPosition(UIView *stackView) {
    UIView *aiContainer = objc_getAssociatedObject(stackView, &kAWECAAIContainerKey);
    if (!aiContainer) return;

    Class evClass = NSClassFromString(@"AWEBaseElementView");
    if (!evClass) return;

    if (aiContainer.superview != stackView) {
        [aiContainer removeFromSuperview];
        [stackView addSubview:aiContainer];
    }

    NSMutableArray<UIView *> *elements = [NSMutableArray array];
    for (UIView *sub in stackView.subviews) {
        if (![sub isKindOfClass:evClass]) continue;
        if (sub.hidden || CGRectIsEmpty(sub.bounds)) continue;
        [elements addObject:sub];
    }
    [elements sortUsingComparator:^NSComparisonResult(UIView *left, UIView *right) {
        if (left.center.x < right.center.x) return NSOrderedAscending;
        if (left.center.x > right.center.x) return NSOrderedDescending;
        return NSOrderedSame;
    }];

    NSUInteger audioIndex = [elements indexOfObjectPassingTest:^BOOL(UIView *element, NSUInteger idx, BOOL *stop) {
        return aweca_isAudioElementView(element);
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

    // 39.1.0 评论栏尾部顺序固定为“加号、定位”。
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

    CGFloat firstCenterX = elements.firstObject.center.x;
    CGFloat lastCenterX = elements.lastObject.center.x;
    NSUInteger totalSlotCount = orderedElements.count + 1;
    if (totalSlotCount < 2 || lastCenterX <= firstCenterX) {
        aiContainer.hidden = YES;
        return;
    }
    CGFloat slotWidth = (lastCenterX - firstCenterX) / (CGFloat)(totalSlotCount - 1);
    NSUInteger aiSlotIndex = orderedAudioIndex + 1;

    // 在原生左右边界内均分全部按钮，不侵入发送键占位区域。
    for (NSUInteger index = 0; index < orderedElements.count; index++) {
        UIView *element = orderedElements[index];
        NSUInteger slotIndex = index < aiSlotIndex ? index : index + 1;
        CGPoint center = element.center;
        center.x = firstCenterX + slotWidth * slotIndex;
        element.center = center;
    }

    CGFloat buttonSize = 24.0;
    aiContainer.bounds = CGRectMake(0, 0, buttonSize, buttonSize);
    aiContainer.center = CGPointMake(firstCenterX + slotWidth * aiSlotIndex, audioElement.center.y);
    aiContainer.transform = audioElement.transform;
    aiContainer.hidden = audioElement.hidden;
    aiContainer.alpha = audioElement.alpha;
    [stackView bringSubviewToFront:aiContainer];

    // 更新图标颜色
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

    objc_setAssociatedObject(elementView, &kAWECAAudioElementViewKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    elementView.userInteractionEnabled = YES;
    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc]
                                         initWithTarget:elementView
                                         action:@selector(aweca_longPressAudioIcon:)];
    lp.minimumPressDuration = 0.5;
    [elementView addGestureRecognizer:lp];

    if (![elementView viewWithTag:19527]) {
        UIView *redDot = [[UIView alloc] initWithFrame:CGRectMake(elementView.bounds.size.width - 8, 2, 6, 6)];
        redDot.backgroundColor = [UIColor redColor];
        redDot.layer.cornerRadius = 3;
        redDot.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        redDot.hidden = ![AWECAAudioReplacer shared].enabled;
        redDot.tag = 19527;
        [elementView addSubview:redDot];
    }

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
    
    // 用主题管理器判断颜色
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

// === Hook 8: 原生布局完成后插入 AI 槽位 ===

static void (*orig_stackViewLayoutSubviews)(id self, SEL _cmd);
static void hook_stackViewLayoutSubviews(id self, SEL _cmd) {
    UIView *sv = (UIView *)self;
    UIView *aiContainer = objc_getAssociatedObject(sv, &kAWECAAIContainerKey);
    if (aiContainer && aiContainer.superview == sv) {
        [aiContainer removeFromSuperview];
    }

    orig_stackViewLayoutSubviews(self, _cmd);

    if (aiContainer) {
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

// === %ctor 搞定收工，插件启动 ===

%ctor {
    @autoreleasepool {
        [AWECAUtils ensureDirectoriesExist];

        [AWECAAudioReplacer shared];

        // 别问为啥手动hook，问就是Swift类runtime搞不定
        setupAudioInputElementHook();
        setupAudioIconElementHook();
        setupTrailingIconElementHooks();
        setupStackViewLayoutHook();
    }
}
