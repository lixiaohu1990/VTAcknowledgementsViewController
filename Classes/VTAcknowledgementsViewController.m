//
// VTAcknowledgementsViewController.m
//
// Copyright (c) 2013-2017 Vincent Tourraine (http://www.vtourraine.net)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "VTAcknowledgementsViewController.h"
#import "VTAcknowledgementViewController.h"

#if !TARGET_OS_TV
#if __has_feature(modules)
@import SafariServices;
#else
#import <SafariServices/SafariServices.h>
#endif
#endif

static NSString *const VTDefaultHeaderText = @"This application makes use of the following third party libraries:";
static NSString *const VTDefaultFooterText = @"Generated by CocoaPods - https://cocoapods.org";
static NSString *const VTDefaultFooterTextLegacy = @"Generated by CocoaPods - http://cocoapods.org"; // For CocoaPods 0.x
static NSString *const VTCocoaPodsURLString = @"https://cocoapods.org";
static NSString *const VTCellIdentifier = @"Cell";

static const CGFloat VTLabelMargin = 20;
static const CGFloat VTFooterBottomMargin = 20;


@interface VTAcknowledgementsViewController ()

+ (NSString *)acknowledgementsPlistPathForName:(NSString *)name;
+ (NSString *)defaultAcknowledgementsPlistPath;
+ (NSString *)localizedStringForKey:(NSString *)key withDefault:(NSString *)defaultString;
+ (NSString *)localizedCocoaPodsFooterText;

- (void)configureHeaderView;
- (void)configureFooterView;
- (UIFont *)headerFooterFont;
- (CGFloat)heightForLabelWithText:(NSString *)labelText andWidth:(CGFloat)labelWidth;

- (IBAction)dismissViewController:(id)sender;
- (void)commonInitWithAcknowledgementsPlistPath:(NSString *)acknowledgementsPlistPath;
- (void)openCocoaPodsWebsite:(id)sender;

@end


@implementation VTAcknowledgementsViewController

+ (NSString *)acknowledgementsPlistPathForName:(NSString *)name {
    return [[NSBundle mainBundle] pathForResource:name ofType:@"plist"];
}

+ (NSString *)defaultAcknowledgementsPlistPath {
    NSString *targetName = [NSBundle mainBundle].infoDictionary[@"CFBundleName"];
    NSString *expectedPlistName = [NSString stringWithFormat:@"Pods-%@-acknowledgements", targetName];
    NSString *expectedPlistPath = [self acknowledgementsPlistPathForName:expectedPlistName];

    if ([[NSFileManager defaultManager] fileExistsAtPath:expectedPlistPath] == YES) {
        return expectedPlistPath;
    }
    else {
        // Legacy file name
        return [self acknowledgementsPlistPathForName:@"Pods-acknowledgements"];
    }
}

+ (instancetype)acknowledgementsViewController {
    NSString *path = self.defaultAcknowledgementsPlistPath;
    return [[self.class alloc] initWithAcknowledgementsPlistPath:path];
}

- (instancetype)initWithPath:(NSString *)acknowledgementsPlistPath {
    self = [super initWithStyle:UITableViewStyleGrouped];

    if (self) {
        [self commonInitWithAcknowledgementsPlistPath:acknowledgementsPlistPath];
    }

    return self;
}

- (instancetype)initWithAcknowledgementsPlistPath:(NSString *)acknowledgementsPlistPath {
    return [self initWithPath:acknowledgementsPlistPath];
}

- (nullable instancetype)initWithFileNamed:(nonnull NSString *)acknowledgementsFileName {
    NSString *path = [[NSBundle mainBundle] pathForResource:acknowledgementsFileName ofType:@"plist"];
    return [self initWithPath:path];
}

- (nullable instancetype)initWithAcknowledgementsFileNamed:(nullable NSString *)acknowledgementsFileName {
    return [self initWithFileNamed:acknowledgementsFileName];
}

- (void)awakeFromNib {
    [super awakeFromNib];

    NSString *path;
    if (self.acknowledgementsPlistName) {
        path = [self.class acknowledgementsPlistPathForName:self.acknowledgementsPlistName];
    }
    else {
        path = self.class.defaultAcknowledgementsPlistPath;
    }

    [self commonInitWithAcknowledgementsPlistPath:path];
}

- (void)commonInitWithAcknowledgementsPlistPath:(NSString *)acknowledgementsPlistPath {
    self.title = self.class.localizedTitle;

    VTAcknowledgementsParser *parser = [[VTAcknowledgementsParser alloc] initWithAcknowledgementsPlistPath:acknowledgementsPlistPath];

    if ([parser.header isEqualToString:VTDefaultHeaderText]) {
        self.headerText = nil;
    }
    else if (![parser.header isEqualToString:@""]) {
        self.headerText = parser.header;
    }

    if ([parser.footer isEqualToString:VTDefaultFooterText] ||
        [parser.footer isEqualToString:VTDefaultFooterTextLegacy]) {
        self.footerText = [VTAcknowledgementsViewController localizedCocoaPodsFooterText];
    }
    else if (![parser.footer isEqualToString:@""]) {
        self.footerText = parser.footer;
    }

    NSMutableArray *acknowledgements = [parser.acknowledgements mutableCopy];

    [acknowledgements sortUsingComparator:^NSComparisonResult(VTAcknowledgement *obj1, VTAcknowledgement *obj2) {
        return [obj1.title compare:obj2.title options:kNilOptions range:NSMakeRange(0, obj1.title.length) locale:[NSLocale currentLocale]];
    }];

    self.acknowledgements = acknowledgements;
}

#pragma mark - Localization

+ (NSString *)localizedStringForKey:(NSString *)key withDefault:(NSString *)defaultString {
    static NSBundle *bundle = nil;
    if (!bundle) {
        NSString *bundlePath = [[NSBundle bundleForClass:VTAcknowledgementsViewController.class] pathForResource:@"VTAcknowledgementsViewController" ofType:@"bundle"];
        bundle = [NSBundle bundleWithPath:bundlePath];

        NSString *language = NSBundle.mainBundle.preferredLocalizations.firstObject ?: @"en";
        if (![bundle.localizations containsObject:language]) {
            language = [language componentsSeparatedByString:@"-"].firstObject;
        }
        if ([bundle.localizations containsObject:language]) {
            bundlePath = [bundle pathForResource:language ofType:@"lproj"];
        }

        bundle = [NSBundle bundleWithPath:bundlePath] ?: NSBundle.mainBundle;
    }

    defaultString = [bundle localizedStringForKey:key value:defaultString table:nil];
    return [NSBundle.mainBundle localizedStringForKey:key value:defaultString table:nil];
}

+ (NSString *)localizedTitle {
    return [self localizedStringForKey:@"VTAckAcknowledgements" withDefault:@"Acknowledgements"];
}

+ (NSString *)localizedCocoaPodsFooterText {
    return [NSString stringWithFormat:@"%@\n%@", [self.class localizedStringForKey:@"VTAckGeneratedByCocoaPods" withDefault:@"Generated by CocoaPods"], VTCocoaPodsURLString];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.headerText) {
        [self configureHeaderView];
    }

    if (self.footerText) {
        [self configureFooterView];
    }

#if TARGET_OS_TV
    self.view.layoutMargins = UIEdgeInsetsMake(60.0, 90.0, 60.0, 90.0); // Margins from tvOS HIG
#endif
}

- (UIFont *)headerFooterFont {
    if ([UIFont respondsToSelector:@selector(preferredFontForTextStyle:)]) {
        return [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    }
    else {
        return [UIFont systemFontOfSize:12];
    }
}

- (void)configureHeaderView {
    UIFont *font = [self headerFooterFont];
    CGFloat labelWidth = CGRectGetWidth(self.view.frame) - 2 * VTLabelMargin;
    CGFloat labelHeight = [self heightForLabelWithText:self.headerText andWidth:labelWidth];

    CGRect labelFrame = CGRectMake(VTLabelMargin, VTLabelMargin, labelWidth, labelHeight);

    UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
    label.text = self.headerText;
    label.font = font;
    label.textColor = [UIColor grayColor];
    label.backgroundColor = [UIColor clearColor];
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);

    CGRect headerFrame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(label.frame) + 2 * VTLabelMargin);
    UIView *headerView = [[UIView alloc] initWithFrame:headerFrame];
    [headerView addSubview:label];
    self.tableView.tableHeaderView = headerView;
}

- (void)configureFooterView {
    UIFont *font = [self headerFooterFont];
    CGFloat labelWidth = CGRectGetWidth(self.view.frame) - 2 * VTLabelMargin;
    CGFloat labelHeight = [self heightForLabelWithText:self.footerText andWidth:labelWidth];

    CGRect labelFrame = CGRectMake(VTLabelMargin, 0, labelWidth, labelHeight);

    UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
    label.text = self.footerText;
    label.font = font;
    label.textColor = [UIColor grayColor];
    label.backgroundColor = [UIColor clearColor];
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);
    label.userInteractionEnabled = YES;

    if ([self.footerText rangeOfString:[NSURL URLWithString:VTCocoaPodsURLString].host].location != NSNotFound) {
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openCocoaPodsWebsite:)];
        [label addGestureRecognizer:tapGestureRecognizer];
    }

    CGRect footerFrame = CGRectMake(0, 0, CGRectGetWidth(label.frame), CGRectGetHeight(label.frame) + VTFooterBottomMargin);
    UIView *footerView = [[UIView alloc] initWithFrame:footerFrame];
    footerView.userInteractionEnabled = YES;
    [footerView addSubview:label];
    label.frame = CGRectMake(0, 0, CGRectGetWidth(label.frame), CGRectGetHeight(label.frame));
    self.tableView.tableFooterView = footerView;
}

- (CGFloat)heightForLabelWithText:(NSString *)labelText andWidth:(CGFloat)labelWidth {
    UIFont *font = self.headerFooterFont;
    CGFloat labelHeight;

    if ([labelText respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        NSStringDrawingOptions options = (NSLineBreakByWordWrapping | NSStringDrawingUsesLineFragmentOrigin);
        CGRect labelBounds = [labelText boundingRectWithSize:CGSizeMake(labelWidth, CGFLOAT_MAX) options:options attributes:@{NSFontAttributeName: font} context:nil];
        labelHeight = CGRectGetHeight(labelBounds);
    }
    else {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#if !TARGET_OS_TV
        CGSize size = [labelText sizeWithFont:font constrainedToSize:(CGSize){labelWidth, CGFLOAT_MAX}];
#else
        CGSize size = CGSizeMake(labelWidth, font.pointSize); // This is probably wrong logically, but it works/looks fine on tvOS
#endif
#pragma GCC diagnostic pop
        labelHeight = size.height;
    }

    return ceilf(labelHeight);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.presentingViewController && self == [self.navigationController.viewControllers firstObject]) {
        UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissViewController:)];
#if !TARGET_OS_TV
        self.navigationItem.leftBarButtonItem = doneItem;
#else
        // Add a spacer item because the leftBarButtonItem is misplaced on tvOS (doesn't obey the HIG)
        UIBarButtonItem *spacerItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        spacerItem.width = 90.0;
        self.navigationItem.leftBarButtonItems = @[spacerItem, doneItem];
#endif
    }

    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (self.acknowledgements.count == 0) {
        NSLog(@"** VTAcknowledgementsViewController Warning **");
        NSLog(@"No acknowledgements found.");
        NSLog(@"This probably means that you didn’t import the `Pods-acknowledgements.plist` to your main target.");
        NSLog(@"Please take a look at https://github.com/vtourraine/VTAcknowledgementsViewController for instructions.");
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    if (self.headerText) {
        [self configureHeaderView];
    }

    if (self.footerText) {
        [self configureFooterView];
    }
}

#pragma mark - Actions

- (void)openCocoaPodsWebsite:(id)sender {
#if !TARGET_OS_TV
    NSURL *URL = [NSURL URLWithString:VTCocoaPodsURLString];

    if (@available(iOS 9.0, *)) {
        SFSafariViewController *viewController = [[SFSafariViewController alloc] initWithURL:URL];
        [self presentViewController:viewController animated:YES completion:nil];
    }
    else {
        [[UIApplication sharedApplication] openURL:URL];
    }
#endif
}

- (IBAction)dismissViewController:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.acknowledgements.count;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:VTCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:VTCellIdentifier];
    }

    VTAcknowledgement *acknowledgement = self.acknowledgements[indexPath.row];
    cell.textLabel.text = acknowledgement.title;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    VTAcknowledgement *acknowledgement = self.acknowledgements[indexPath.row];
    VTAcknowledgementViewController *viewController = [[VTAcknowledgementViewController alloc] initWithTitle:acknowledgement.title text:acknowledgement.text];

    [self.navigationController pushViewController:viewController animated:YES];
}

@end
