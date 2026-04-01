// IPodLayout.h — pixel-perfect tannerv.com iPod Classic layout
// Display: ~40% height, thin black bezel, white screen, GRAY header
// Wheel: ~60% height, pure white flat design
#pragma once
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <AudioToolbox/AudioToolbox.h>

// ── Aliases for convenience ─────────────────────────────────────────────────
#define IPD_BODY            IPD_BODY_BG
#define IPD_SEL             IPD_SEL_TOP

// ── Palette (exact from screenshots) ──────────────────────────────────────
#define IPD_BODY_BG         [UIColor colorWithRed:0.878 green:0.878 blue:0.878 alpha:1]
#define IPD_BEZEL           [UIColor colorWithRed:0.12  green:0.12  blue:0.12  alpha:1]
#define IPD_SCREEN          [UIColor whiteColor]
// Header: light gray gradient (like tannerv — NOT blue)
#define IPD_HDR_TOP         [UIColor colorWithRed:0.92  green:0.92  blue:0.92  alpha:1]
#define IPD_HDR_BOT         [UIColor colorWithRed:0.82  green:0.82  blue:0.82  alpha:1]
#define IPD_HDR_TXT         [UIColor colorWithRed:0.08  green:0.08  blue:0.08  alpha:1]
#define IPD_HDR_BORDER      [UIColor colorWithRed:0.65  green:0.65  blue:0.65  alpha:1]
// Selection: bright blue (exact tannerv blue)
#define IPD_SEL_TOP         [UIColor colorWithRed:0.247 green:0.616 blue:0.867 alpha:1]
#define IPD_SEL_BOT         [UIColor colorWithRed:0.047 green:0.420 blue:0.780 alpha:1]
#define IPD_SEL_TXT         [UIColor whiteColor]
// List
#define IPD_SEP             [UIColor colorWithRed:0.82  green:0.82  blue:0.82  alpha:1]
#define IPD_TXT             [UIColor colorWithRed:0.08  green:0.08  blue:0.08  alpha:1]
#define IPD_SUBTXT          [UIColor colorWithRed:0.45  green:0.45  blue:0.45  alpha:1]
// Progress bar fill: same blue as selection
#define IPD_PROGRESS        [UIColor colorWithRed:0.247 green:0.616 blue:0.867 alpha:1]

// ── Dimensions ─────────────────────────────────────────────────────────────
#define IPD_DISPLAY_FRAC    0.400f   // display = 40% of screen height (tannerv ratio)
#define IPD_BEZEL_W         4.0f
#define IPD_SCREEN_R        6.0f
#define IPD_HDR_H           28.0f
#define IPD_ROW_H           44.0f   // standard row with artwork
#define IPD_WHEEL_PAD       8.0f

// ── Geometry ───────────────────────────────────────────────────────────────
static inline CGRect IPDScreenRect(CGRect b) {
    CGFloat dh = floorf(b.size.height * IPD_DISPLAY_FRAC);
    return CGRectMake(IPD_BEZEL_W, IPD_BEZEL_W,
                      b.size.width - IPD_BEZEL_W*2,
                      dh - IPD_BEZEL_W*2);
}
static inline CGRect IPDWheelRect(CGRect b) {
    CGFloat dh    = floorf(b.size.height * IPD_DISPLAY_FRAC);
    CGFloat bodyH = b.size.height - dh;
    CGFloat size  = MIN(bodyH - IPD_WHEEL_PAD*2, b.size.width - IPD_WHEEL_PAD*2);
    return CGRectMake(floorf((b.size.width-size)/2.0f),
                      dh + floorf((bodyH-size)/2.0f), size, size);
}

// ── Haptic/click ───────────────────────────────────────────────────────────
static inline void IPDHaptic(void) {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"com.ipodclassic.haptic"] &&
        ![[NSUserDefaults standardUserDefaults] boolForKey:@"com.ipodclassic.haptic"]) return;
    [[UIImpactFeedbackGenerator.alloc initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
}
static inline void IPDClick(void) {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"com.ipodclassic.clicksound"] &&
        ![[NSUserDefaults standardUserDefaults] boolForKey:@"com.ipodclassic.clicksound"]) return;
    AudioServicesPlaySystemSound(1104);
}

// ── Header factory (gray, like tannerv) ───────────────────────────────────
// titleOut: optional label for dynamic title updates
// leftIconOut: optional label for ▶/⏸ or ◀ icon on left
static inline UIView* IPDHeader(CGFloat w, NSString *title,
                                 UILabel * __autoreleasing *titleOut,
                                 UILabel * __autoreleasing *leftIconOut) {
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0,0,w,IPD_HDR_H)];

    // Gray gradient background
    CAGradientLayer *g = [CAGradientLayer layer];
    g.frame     = v.bounds;
    g.colors    = @[(__bridge id)IPD_HDR_TOP.CGColor, (__bridge id)IPD_HDR_BOT.CGColor];
    g.locations = @[@0, @1];
    [v.layer addSublayer:g];

    // Bottom border
    CALayer *bl = [CALayer layer];
    bl.frame           = CGRectMake(0, IPD_HDR_H-0.5f, w, 0.5f);
    bl.backgroundColor = IPD_HDR_BORDER.CGColor;
    [v.layer addSublayer:bl];

    // Left icon (◀ for menus, ▶/⏸ for now playing)
    UILabel *li = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, 18, IPD_HDR_H)];
    li.font            = [UIFont systemFontOfSize:10];
    li.textColor       = IPD_SUBTXT;
    li.backgroundColor = [UIColor clearColor];
    li.text            = @"◀";
    [v addSubview:li];
    if (leftIconOut) *leftIconOut = li;

    // Title (black, bold, small)
    UILabel *ttl = [[UILabel alloc] initWithFrame:CGRectMake(22, 0, w-60, IPD_HDR_H)];
    ttl.text          = title;
    ttl.font          = [UIFont boldSystemFontOfSize:13];
    ttl.textColor     = IPD_HDR_TXT;
    ttl.backgroundColor = [UIColor clearColor];
    ttl.lineBreakMode = NSLineBreakByTruncatingTail;
    [v addSubview:ttl];
    if (titleOut) *titleOut = ttl;

    // Battery (right) — colored green fill
    CGFloat bx = w-36;
    UIView *bo=[[UIView alloc]initWithFrame:CGRectMake(bx,8,24,13)];
    bo.layer.borderColor=[UIColor colorWithWhite:0.35 alpha:1].CGColor;
    bo.layer.borderWidth=1.2f; bo.layer.cornerRadius=2; bo.backgroundColor=[UIColor clearColor];
    [v addSubview:bo];
    UIView *bf=[[UIView alloc]initWithFrame:CGRectMake(bx+1,9,18,11)];
    bf.backgroundColor=[UIColor colorWithRed:0.2 green:0.75 blue:0.2 alpha:1];
    bf.layer.cornerRadius=1; [v addSubview:bf];
    UIView *bn=[[UIView alloc]initWithFrame:CGRectMake(bx+25,12,3,6)];
    bn.backgroundColor=[UIColor colorWithWhite:0.35 alpha:1]; bn.layer.cornerRadius=1;
    [v addSubview:bn];

    // Pause/play indicator (left of battery, small gray ⏸ or ▶)
    UILabel *ps=[[UILabel alloc]initWithFrame:CGRectMake(w-56,0,18,IPD_HDR_H)];
    ps.font=[UIFont systemFontOfSize:11]; ps.textColor=[UIColor colorWithWhite:0.4 alpha:1];
    ps.backgroundColor=[UIColor clearColor]; ps.textAlignment=NSTextAlignmentCenter;
    ps.text=@"⏸"; ps.tag=77;
    [v addSubview:ps];

    return v;
}

// ── Selection background (blue gradient, like tannerv) ─────────────────────
static inline UIView* IPDSelectionView(CGFloat w, CGFloat h) {
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0,0,w,h)];
    CAGradientLayer *g = [CAGradientLayer layer];
    g.frame     = v.bounds;
    g.colors    = @[(__bridge id)IPD_SEL_TOP.CGColor, (__bridge id)IPD_SEL_BOT.CGColor];
    g.locations = @[@0, @1];
    [v.layer addSublayer:g];
    return v;
}

// ── Screen scaffold ────────────────────────────────────────────────────────
static inline UIView* IPDBuildScaffold(UIView *parent) {
    CGRect b  = parent.bounds;
    CGFloat dh = floorf(b.size.height * IPD_DISPLAY_FRAC);
    CGRect dz  = CGRectMake(0, 0, b.size.width, dh);
    CGRect sr  = IPDScreenRect(b);

    // Body: flat light gray
    parent.backgroundColor = IPD_BODY_BG;

    // Bezel
    UIView *bz = [[UIView alloc] initWithFrame:dz];
    bz.backgroundColor    = IPD_BEZEL;
    [parent addSubview:bz];

    // Screen
    UIView *sc = [[UIView alloc] initWithFrame:sr];
    sc.backgroundColor    = IPD_SCREEN;
    sc.layer.cornerRadius = IPD_SCREEN_R;
    sc.clipsToBounds      = YES;
    [parent addSubview:sc];
    return sc;
}
