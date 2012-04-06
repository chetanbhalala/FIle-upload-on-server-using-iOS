//
//  ViewController.m
//  FileUploadDownload
//
//  Created by kartik patel on 21/12/11.
//  Copyright (c) 2011 info@elegantmicroweb.com. All rights reserved.
//

#import "ViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "WebService.h"
#import <AssetsLibrary/AssetsLibrary.h>

@implementation ViewController

@synthesize btnUpload;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	imagePicker = [[UIImagePickerController alloc]init];
    imagePicker.delegate = self;
    isUpload = NO;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (IBAction)uploadFile:(id)sender {
    isUpload = YES;
    UIActionSheet *actionsheet;
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera])
    {
        actionsheet = [[UIActionSheet alloc]initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo or Video", nil];
    }
    else
    {
        actionsheet = [[UIActionSheet alloc]initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Choose Existing", nil];
    }
    [actionsheet showInView:[UIApplication sharedApplication].keyWindow];
    [actionsheet release];
}

#pragma mark - Actionsheet delegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    NSLog(@"%d",buttonIndex);
    
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        switch (buttonIndex)
        {
            case 0:
                imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
                NSArray *arraySourceTypes =[UIImagePickerController availableMediaTypesForSourceType:imagePicker.sourceType];  
                if ([arraySourceTypes containsObject:(NSString *)kUTTypeMovie])
                {
                    imagePicker.mediaTypes =  arraySourceTypes;
                    imagePicker.cameraDevice=UIImagePickerControllerCameraDeviceRear;
                    imagePicker.cameraCaptureMode=UIImagePickerControllerCameraCaptureModeVideo;
                    imagePicker.videoQuality=UIImagePickerControllerQualityTypeLow;
                }
                break;
            default:
                return;
                break;
        }
    } else {
        switch (buttonIndex)
        {
            case 0:
                imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                break;
            default:
                return;
                break;
        }
    }
    [self presentModalViewController:imagePicker animated:YES];
}

#pragma mark - Imagepicker controller delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if([[info objectForKey:@"UIImagePickerControllerMediaType"] isEqualToString:@"public.image"])
    {
        UIGraphicsBeginImageContext(CGSizeMake(480,320));
        UIGraphicsGetCurrentContext();
        [[info objectForKey:@"UIImagePickerControllerOriginalImage"] drawInRect: CGRectMake(0, 0, 480, 320)];
        UIImage        *smallImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext(); 
        NSData *imageData = UIImageJPEGRepresentation(smallImage,0);
        
        NSString *urlString = @"your url String";
        NSString *filename = @"image";
        NSMutableURLRequest *request= [[[NSMutableURLRequest alloc] init] autorelease];
        [request setURL:[NSURL URLWithString:urlString]];
        [request setHTTPMethod:@"POST"];
        NSString *boundary = @"---------------------------14737809831466499882746641449";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
        [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
        NSMutableData *postbody = [NSMutableData data];
        [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"image\"; filename=\"%@.jpg\"\r\n", filename] dataUsingEncoding:NSUTF8StringEncoding]];
        [postbody appendData:[[NSString stringWithString:@"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [postbody appendData:[NSData dataWithData:imageData]];
        [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [request setHTTPBody:postbody];
        
        NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        NSString *str = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
        NSLog(@"Data ---- %@", str);
        
        
    }
    else if ([[info objectForKey:@"UIImagePickerControllerMediaType"] isEqualToString:@"public.movie"]) 
    {
        NSURL *url =  [info objectForKey:UIImagePickerControllerMediaURL];
        NSData *data = [NSData dataWithContentsOfURL:url];
        NSString *urlString = @"your url String";
        NSString *filename = @"video1";
        NSMutableURLRequest *request= [[[NSMutableURLRequest alloc] init] autorelease];
        [request setURL:[NSURL URLWithString:urlString]];
        [request setHTTPMethod:@"POST"];
        NSString *boundary = @"---------------------------14737809831466499882746641449";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
        [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
        NSMutableData *postbody = [NSMutableData data];
        [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"%@.mov\"\r\n", filename] dataUsingEncoding:NSUTF8StringEncoding]];
        [postbody appendData:[[NSString stringWithString:@"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [postbody appendData:[NSData dataWithData:data]];
        [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [request setHTTPBody:postbody];
        
        NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        NSString *str = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
        NSLog(@"Data ---- %@", str);
    }
    [picker dismissModalViewControllerAnimated:YES];
}

- (void) downloadFile:(NSString*)urlString
{
    /**NSString *file = [NSString stringWithFormat:@"%@",url];
    NSURL *fileURL = [NSURL URLWithString:file];
    
    NSURLRequest *req = [NSURLRequest requestWithURL:fileURL];
    NSURLConnection *conn = [NSURLConnection connectionWithRequest:req delegate:self];
    */
    
    /*isUpload = NO;
    NSURL *url = [NSURL URLWithString:urlString];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setDelegate:self];
    [request startAsynchronous];*/
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSData *data = [NSData dataWithContentsOfURL:url];
    if (data)
    {
        NSString *documentFolderPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        NSString *videosFolderPath = [documentFolderPath stringByAppendingPathComponent:@"videos"]; 
        NSString *filePath = [videosFolderPath stringByAppendingPathComponent:@"chetan.mp4"];
        BOOL written = [data writeToFile:filePath atomically:NO];
        if (written)
            NSLog(@"Saved to file: %@", filePath);
        else
            NSLog(@"Error");
    }
    else
        NSLog(@"Error");
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
} 

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (IBAction)grabURLInBackground:(id)sender
{
    isUpload = NO;
    NSURL *url = [NSURL URLWithString:@"your url String"];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setDelegate:self];
    [request startAsynchronous];
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    // Use when fetching text data
    if (isUpload) {
        NSString *responseString = [request responseString];
        NSLog(@"responseData %@",responseString);
    } else {
        // Use when fetching binary data
        NSData *responseData = [request responseData];
        //NSLog(@"responseData %@",responseData);
        NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentPath = [searchPaths lastObject];
        documentPath = [NSString stringWithFormat:@"%@/test.mp4",documentPath];
        [responseData writeToFile:documentPath atomically:YES];
        //UIImageWriteToSavedPhotosAlbum(UIImage *image, id completionTarget, SEL completionSelector, void *contextInfo);
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];

        [library writeVideoAtPathToSavedPhotosAlbum:[NSURL URLWithString:documentPath]
                                    completionBlock:^(NSURL *assetURL, NSError *error){/*notify of completion*/}];        
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSError *error = [request error];
    //[error description];
    NSLog(@"Error -- %@",error);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end
