#import "CameraRollHelper.h"
#import "ImageHelper.h"
#import <MobileCoreServices/MobileCoreServices.h>

#pragma clang diagnostic push
#pragma ide diagnostic ignored "UnavailableInDeploymentTarget"
@implementation CameraRollHelper {
}

static CameraRollHelper* _instance;
+(CameraRollHelper*) instance{
	if(_instance == nil) _instance = [[CameraRollHelper alloc] init];
	return _instance;
}

+(void) addNewAssetWithImagePath:(NSString*)imagePath onSuccess:(Action)a onFail:(StringAction)b {
	Action successAction = a;
	StringAction failAction = b;
	NSURL* imageUrl = [NSURL fileURLWithPath:imagePath];
	[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
		//TODO: Add to named asset collection 
		PHAssetChangeRequest *createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:imageUrl];
	} completionHandler:^(BOOL success, NSError *error) {
		if(success) successAction();
		else failAction([error localizedDescription]);
	}];
}

-(void) selectPictureWithCompletionHandler:(StringAction)onComplete onFail:(StringAction)onFail {
	self.onCompleteHandler = onComplete;
	self.onFailHandler = onFail;
	BOOL canPick = [self openImagePickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary
													then:^(NSDictionary *dictionary) {
														[self handlePictureSelected:dictionary];
													} or:^{
														self.onFailHandler(@"User cancelled");
			}];
	if(!canPick)
	{
		self.onFailHandler(@"Image library not available");
	}
}

-(void) handlePictureSelected:(NSDictionary *)info {

    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];

    if (CFStringCompare ((__bridge CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
        NSURL *videoUrl=(NSURL*)[info objectForKey:UIImagePickerControllerMediaURL];
        AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:urlAsset presetName:AVAssetExportPresetLowQuality];
        exportSession.outputURL = videoUrl;
        exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        exportSession.shouldOptimizeForNetworkUse = YES;
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            NSString *moviePath = [videoUrl path];
            self.onCompleteHandler(moviePath);
        }];
     }
    else{
        NSURL* imageUrl = info[@"UIImagePickerControllerReferenceURL"];
        NSLog(@"image url : %@",imageUrl);
        PHFetchResult* result = [PHAsset fetchAssetsWithALAssetURLs:@[imageUrl] options:nil];
        PHAsset* imageInfo = [result firstObject];
        NSLog(@"imageInfo : %@",imageInfo);
        
        if(imageInfo) {
            UIImage* image = [ImageHelper imageFromDictionary:info];
            image = [ImageHelper correctImageOrientation:image];
            PHImageRequestOptions* imageRequestOptions = [[PHImageRequestOptions alloc] init];
            imageRequestOptions.synchronous = YES;
            @try {
                [[PHImageManager defaultManager] requestImageDataForAsset:imageInfo options:imageRequestOptions
                                                            resultHandler:^(NSData *imageData, NSString *dataUTI,UIImageOrientation orientation, NSDictionary *info)
                 {
                     if (info[@"PHImageFileURLKey"]) {
                         NSURL* path = info[@"PHImageFileURLKey"];
                         @try {
                            NSString* newPath = [ImageHelper localPathFromPHImageFileURL:path temp:YES];
                            newPath = [newPath stringByDeletingPathExtension];
                            newPath = [NSString stringWithFormat:@"%@.jpg",newPath];
                            [ImageHelper saveImage:image path:newPath];
                            self.onCompleteHandler(newPath);
                         } @catch (NSException *exception) {
                            self.onFailHandler([exception reason]);
                         }
                     }
                 }
                 ];
            } @catch (NSException *exception) {
                self.onFailHandler([exception reason]);
            }
            
        }else{
            self.onFailHandler(@"Picture could not be selected for an unknown reason");
        }
    }
}

@end
#pragma clang diagnostic pop
