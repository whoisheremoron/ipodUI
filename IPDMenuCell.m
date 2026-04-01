// IPDMenuCell.m — pixel-perfect iPod Classic row
#import "IPDMenuCell.h"

static CGFloat const kThumb = 36.0f;   // IPD_ROW_H(44) - 8
static CGFloat const kPad   =  4.0f;
static CGFloat const kChev  = 16.0f;

@implementation IPDMenuCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)rID {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:rID];
    if (!self) return nil;
    self.selectionStyle    = UITableViewCellSelectionStyleNone;
    self.backgroundColor   = IPD_SCREEN;
    self.contentView.backgroundColor = IPD_SCREEN;
    // Kill the default imageView
    self.imageView.hidden  = YES;
    self.textLabel.hidden  = YES;
    self.detailTextLabel.hidden = YES;

    // Thumb
    self.thumbView = [[UIImageView alloc] init];
    self.thumbView.contentMode  = UIViewContentModeScaleAspectFill;
    self.thumbView.clipsToBounds = YES;
    self.thumbView.layer.cornerRadius = 2;
    self.thumbView.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1];
    [self.contentView addSubview:self.thumbView];

    // Title
    self.titleLbl = [[UILabel alloc] init];
    self.titleLbl.font = [UIFont boldSystemFontOfSize:14];
    self.titleLbl.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.titleLbl];

    // Subtitle
    self.subtitleLbl = [[UILabel alloc] init];
    self.subtitleLbl.font = [UIFont systemFontOfSize:11];
    self.subtitleLbl.textColor = IPD_SUBTXT;
    self.subtitleLbl.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.subtitleLbl];

    // Chevron
    self.chevronLbl = [[UILabel alloc] init];
    self.chevronLbl.font = [UIFont systemFontOfSize:12];
    self.chevronLbl.text = @"›";
    self.chevronLbl.textAlignment = NSTextAlignmentCenter;
    self.chevronLbl.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.chevronLbl];

    // Selection bg
    self.selectedBackgroundView = [UIView new];
    self.selectedBackgroundView.backgroundColor = [UIColor clearColor]; // we handle via setSelected

    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.contentView.bounds.size.width;
    CGFloat h = self.contentView.bounds.size.height;

    BOOL hasThumb = !self.thumbView.hidden;
    BOOL hasSub   = (self.subtitleLbl.text.length > 0);
    BOOL hasChev  = !self.chevronLbl.hidden;

    CGFloat rightEdge = w - (hasChev ? kChev + kPad : kPad);
    CGFloat textX;

    if (hasThumb) {
        self.thumbView.frame = CGRectMake(kPad, (h - kThumb)/2.0f, kThumb, kThumb);
        textX = kPad + kThumb + 6.0f;
    } else {
        self.thumbView.frame = CGRectZero;
        textX = 10.0f;
    }

    CGFloat textW = rightEdge - textX;

    if (hasSub) {
        self.titleLbl.frame    = CGRectMake(textX, 4.0f,  textW, 18.0f);
        self.subtitleLbl.frame = CGRectMake(textX, 23.0f, textW, 14.0f);
    } else {
        self.titleLbl.frame    = CGRectMake(textX, 0, textW, h);
        self.subtitleLbl.frame = CGRectZero;
    }

    self.chevronLbl.frame = CGRectMake(w - kChev - kPad, 0, kChev, h);
}

-(void)setTitle:(NSString*)title subtitle:(NSString*)subtitle artwork:(UIImage*)art hasAction:(BOOL)hasAction selected:(BOOL)sel {
    self.titleLbl.text    = title;
    self.subtitleLbl.text = subtitle ?: @"";

    BOOL showThumb = (art != nil || subtitle != nil);
    self.thumbView.hidden    = !showThumb;
    self.thumbView.image     = art;
    self.thumbView.backgroundColor = art ? [UIColor clearColor] : [UIColor colorWithWhite:0.88 alpha:1];

    self.chevronLbl.hidden = !hasAction;

    [self applySelected:sel];
    [self setNeedsLayout];
}

-(void)applySelected:(BOOL)sel {
    UIColor *bg   = sel ? IPD_SEL_TOP    : IPD_SCREEN;
    UIColor *txt  = sel ? IPD_SEL_TXT    : IPD_TXT;
    UIColor *sub  = sel ? [UIColor colorWithWhite:0.9 alpha:1] : IPD_SUBTXT;
    UIColor *chev = sel ? [UIColor colorWithWhite:0.9 alpha:1] : IPD_SUBTXT;
    self.contentView.backgroundColor = bg;
    self.backgroundColor             = bg;
    self.titleLbl.textColor          = txt;
    self.subtitleLbl.textColor       = sub;
    self.chevronLbl.textColor        = chev;
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    [self applySelected:selected];
}
-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    [self applySelected:highlighted];
}

@end
