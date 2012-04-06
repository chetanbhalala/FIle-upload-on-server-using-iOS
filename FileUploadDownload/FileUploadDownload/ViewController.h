//
//  ViewController.h
//  FileUploadDownload
//
//  Created by kartik patel on 21/12/11.
//  Copyright (c) 2011 info@elegantmicroweb.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASIFormDataRequest.h"

@interface ViewController : UIViewController <UIActionSheetDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,ASIHTTPRequestDelegate> {
    
    UIImagePickerController *imagePicker;
    UIButton    *btnUpload;
    BOOL isUpload;
    
    NSMutableData *fileData;
    NSNumber *totalFileSize;
}

@property (nonatomic, retain) IBOutlet UIButton    *btnUpload;

- (IBAction)uploadFile:(id)sender;
- (IBAction)grabURLInBackground:(id)sender;
- (void) downloadFile:(NSString*)urlString;

@end
