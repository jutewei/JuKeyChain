//
//  ViewController.m
//  JuKeyChain
//
//  Created by Juvid on 2019/1/4.
//  Copyright © 2019 Juvid. All rights reserved.
//

#import "ViewController.h"
#import "JuKeyChainData.h"
@interface ViewController ()<UITextFieldDelegate>{

    __weak IBOutlet UITextField *shKey;
    __weak IBOutlet UITextField *shValue;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}
- (IBAction)shTouchKey:(id)sender {

    [JuKeyChainData shSetObject:@"23456789" forKey:@"zhu"];
    NSString *string=[JuKeyChainData shObjectForKey:@"zhu"];
    NSLog(@"%@",string);
}

@end
