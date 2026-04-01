// ClickWheelView.m — exact tannerv.com style: pure white, flat, gray labels
#import "ClickWheelView.h"
#import "IPodLayout.h"
#import <AudioToolbox/AudioToolbox.h>

@interface ClickWheelView () {
    CGFloat _lastAngle;
    CGFloat _accum;
    BOOL    _tracking;
    BOOL    _dragged;
}
@property (nonatomic, strong) CAShapeLayer *outerLayer;
@property (nonatomic, strong) CAShapeLayer *centerLayer;
@end

@implementation ClickWheelView

- (instancetype)initWithFrame:(CGRect)f {
    self = [super initWithFrame:f];
    if (self) { self.backgroundColor = [UIColor clearColor]; self.userInteractionEnabled = YES; }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    for (UIView *v in self.subviews) [v removeFromSuperview];
    [self buildWheel];
}

- (void)buildWheel {
    CGFloat s  = MIN(self.bounds.size.width, self.bounds.size.height);
    CGFloat cx = self.bounds.size.width/2, cy = self.bounds.size.height/2;
    CGFloat R  = s/2 - 1;
    CGFloat r  = R * 0.38f;

    // Outer shadow
    CAShapeLayer *shadow = [CAShapeLayer layer];
    UIBezierPath *sp = [UIBezierPath bezierPathWithArcCenter:CGPointMake(cx,cy) radius:R+1 startAngle:0 endAngle:M_PI*2 clockwise:YES];
    shadow.path = sp.CGPath; shadow.fillColor = [UIColor clearColor].CGColor;
    shadow.strokeColor = [UIColor colorWithWhite:0 alpha:0.12].CGColor; shadow.lineWidth = 2;
    [self.layer addSublayer:shadow];

    // Outer wheel — pure white with very subtle edge
    self.outerLayer = [CAShapeLayer layer];
    UIBezierPath *op = [UIBezierPath bezierPathWithArcCenter:CGPointMake(cx,cy) radius:R startAngle:0 endAngle:M_PI*2 clockwise:YES];
    self.outerLayer.path        = op.CGPath;
    self.outerLayer.fillColor   = [UIColor colorWithWhite:0.965 alpha:1].CGColor;
    self.outerLayer.strokeColor = [UIColor colorWithWhite:0.75 alpha:1].CGColor;
    self.outerLayer.lineWidth   = 0.5f;
    [self.layer addSublayer:self.outerLayer];

    // Inner ring groove
    CAShapeLayer *groove = [CAShapeLayer layer];
    UIBezierPath *gp = [UIBezierPath bezierPathWithArcCenter:CGPointMake(cx,cy) radius:r+1.5f startAngle:0 endAngle:M_PI*2 clockwise:YES];
    groove.path = gp.CGPath; groove.fillColor=[UIColor clearColor].CGColor;
    groove.strokeColor=[UIColor colorWithWhite:0.6 alpha:0.8].CGColor; groove.lineWidth=1.0f;
    [self.layer addSublayer:groove];

    // Center button — slightly lighter gray
    self.centerLayer = [CAShapeLayer layer];
    UIBezierPath *cp = [UIBezierPath bezierPathWithArcCenter:CGPointMake(cx,cy) radius:r startAngle:0 endAngle:M_PI*2 clockwise:YES];
    self.centerLayer.path      = cp.CGPath;
    self.centerLayer.fillColor = [UIColor colorWithWhite:0.84 alpha:1].CGColor;
    [self.layer addSublayer:self.centerLayer];

    // Labels — medium gray, exactly like tannerv
    CGFloat loff = (R + r) / 2.0f;
    CGFloat fs   = MAX(s * 0.060f, 9.0f);
    NSDictionary *a = @{
        NSFontAttributeName:            [UIFont boldSystemFontOfSize:fs],
        NSForegroundColorAttributeName: [UIColor colorWithWhite:0.45 alpha:1],
    };
    [self addLbl:@"MENU"  c:CGPointMake(cx, cy - loff) a:a];
    [self addLbl:@"▶▶"    c:CGPointMake(cx+loff, cy)   a:a];
    [self addLbl:@"◀◀"    c:CGPointMake(cx-loff, cy)   a:a];
    [self addLbl:@"▶ II"  c:CGPointMake(cx, cy+loff)   a:a];
}

- (void)addLbl:(NSString*)t c:(CGPoint)c a:(NSDictionary*)a {
    UILabel *l=[UILabel new];
    l.attributedText=[[NSAttributedString alloc]initWithString:t attributes:a];
    [l sizeToFit]; l.center=c; l.backgroundColor=[UIColor clearColor];
    l.userInteractionEnabled=NO; [self addSubview:l];
}

- (CGFloat)radius:(CGPoint)p {
    CGFloat dx=p.x-self.bounds.size.width/2, dy=p.y-self.bounds.size.height/2;
    return sqrtf(dx*dx+dy*dy);
}
- (CGFloat)angle:(CGPoint)p {
    return atan2f(p.y-self.bounds.size.height/2, p.x-self.bounds.size.width/2);
}
- (CGFloat)R { return MIN(self.bounds.size.width,self.bounds.size.height)/2-1; }
- (CGFloat)r { return [self R]*0.38f; }

- (void)touchesBegan:(NSSet<UITouch*>*)t withEvent:(UIEvent*)e {
    CGPoint p=[t.anyObject locationInView:self];
    if([self radius:p]>=[self r]) { _lastAngle=[self angle:p]; _accum=0; _dragged=NO; _tracking=YES; }
}
- (void)touchesMoved:(NSSet<UITouch*>*)t withEvent:(UIEvent*)e {
    if(!_tracking) return;
    CGPoint p=[t.anyObject locationInView:self];
    if([self radius:p]<[self r]) return;
    CGFloat ang=[self angle:p], d=ang-_lastAngle;
    if(d>M_PI)d-=2*M_PI; if(d<-M_PI)d+=2*M_PI;
    _accum+=d; _lastAngle=ang;
    const CGFloat th=(2.0f*M_PI)/20.0f;
    while(_accum>th){_accum-=th;_dragged=YES;IPDClick();IPDHaptic();[self.delegate wheelDidTrigger:WheelActionScrollDown];}
    while(_accum<-th){_accum+=th;_dragged=YES;IPDClick();IPDHaptic();[self.delegate wheelDidTrigger:WheelActionScrollUp];}
}
- (void)touchesEnded:(NSSet<UITouch*>*)t withEvent:(UIEvent*)e {
    CGPoint p=[t.anyObject locationInView:self];
    CGFloat dist=[self radius:p]; _tracking=NO;
    if(dist<[self r]){[self animCenter];IPDClick();[self.delegate wheelDidTrigger:WheelActionCenter];return;}
    if(_dragged||dist>[self R]) return;
    CGFloat ang=[self angle:p]; IPDClick();
    if     (ang>-M_PI*0.75&&ang<-M_PI*0.25)[self.delegate wheelDidTrigger:WheelActionMenu];
    else if(ang>-M_PI*0.25&&ang< M_PI*0.25)[self.delegate wheelDidTrigger:WheelActionNext];
    else if(ang> M_PI*0.25&&ang< M_PI*0.75)[self.delegate wheelDidTrigger:WheelActionPlayPause];
    else                                    [self.delegate wheelDidTrigger:WheelActionPrev];
}
- (void)touchesCancelled:(NSSet<UITouch*>*)t withEvent:(UIEvent*)e { _tracking=NO; }
- (void)animCenter {
    CABasicAnimation *a=[CABasicAnimation animationWithKeyPath:@"fillColor"];
    a.fromValue=(__bridge id)self.centerLayer.fillColor;
    a.toValue=(__bridge id)[UIColor colorWithWhite:0.55 alpha:1].CGColor;
    a.duration=0.07; a.autoreverses=YES;
    [self.centerLayer addAnimation:a forKey:@"tap"];
}

@end
