// IPDMenuCell.h — fully custom cell, no UIKit imageView conflict
#import <UIKit/UIKit.h>
#import "IPodLayout.h"

@interface IPDMenuCell : UITableViewCell
@property(nonatomic,strong) UIImageView *thumbView;
@property(nonatomic,strong) UILabel     *titleLbl;
@property(nonatomic,strong) UILabel     *subtitleLbl;
@property(nonatomic,strong) UILabel     *chevronLbl;
-(void)setTitle:(NSString*)title subtitle:(NSString*)subtitle artwork:(UIImage*)art hasAction:(BOOL)hasAction selected:(BOOL)sel;
@end
