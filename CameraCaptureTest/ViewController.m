//
//  ViewController.m
//  CameraCaptureTest
//
//  Created by tstone10 on 6/22/16.
//  Copyright © 2016 DetroitLabs. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *takePhotoButton;
@property (weak, nonatomic) IBOutlet UIButton *chooseFromLibraryButton;

@end

@implementation ViewController

UIImagePickerController *appImagePicker;

- (void)viewDidLoad {
	[super viewDidLoad];
	
	if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		
		UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:@"Error"
															  message:@"Device has no camera"
															 delegate:nil
													cancelButtonTitle:@"OK"
													otherButtonTitles: nil];
		
		[myAlertView show];
	}
	else {
		appImagePicker = [self createAppImagePicker];
	}
	
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (IBAction)takePhoto:(id)sender {
	appImagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
	
	[self presentViewController:appImagePicker animated:YES completion:NULL];
}

- (IBAction)choosePhoto:(id)sender {
	appImagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	
	[self presentViewController:appImagePicker animated:YES completion:NULL];
}

- (UIImagePickerController *)createAppImagePicker {
	UIImagePickerController *picker = [[UIImagePickerController alloc] init];
	picker.delegate = self;
	picker.allowsEditing = YES;
	
	return picker;
}

// imagePicker delegate methods
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	
	UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
	
	NSString * b64ImgStrURI = [UIImageJPEGRepresentation(chosenImage, 0.25) base64EncodedStringWithOptions:kNilOptions];
	
	b64ImgStrURI = [NSString stringWithFormat:@"data:image/jpeg;base64,%@", b64ImgStrURI];
	
	NSLog(b64ImgStrURI);
	
	_imageView.image = chosenImage;
	
	[picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
 
	[picker dismissViewControllerAnimated:YES completion:NULL];
}

@end
