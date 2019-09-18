#import "MultiImagePickerPlugin.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/Photos.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
@import BSImagePicker;

@interface PHAsset(MultiImagePickerPlugin)

- (NSString *)originalFilename;

@end

@implementation PHAsset(MultiImagePickerPlugin)

- (NSString *)originalFilename {
    NSString *fname = nil;
    if (@available(iOS 9.0, *)) {
        NSArray<PHAssetResource *> *resources = [PHAssetResource assetResourcesForAsset:self];
        
        if (resources.count > 0) {
            fname = resources[0].originalFilename;
        }
        
        if (fname == nil) {
            fname = @"";
        }
    }
    return fname;
}

@end

@interface MultiImagePickerPlugin()

@property (nonatomic, copy) id<FlutterBinaryMessenger> messenger;

@end

@implementation MultiImagePickerPlugin {
    FlutterResult _result;
    NSDictionary *_arguments;
    UIImagePickerController *_imagePickerController;
    UIViewController *_viewController;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel *channel =
    [FlutterMethodChannel methodChannelWithName:@"multi_image_picker"
                                binaryMessenger:[registrar messenger]];
    UIViewController *viewController =
    [UIApplication sharedApplication].delegate.window.rootViewController;
    MultiImagePickerPlugin *instance =
    [[MultiImagePickerPlugin alloc] initWithViewController:viewController messager:[registrar messenger]];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithViewController:(UIViewController *)viewController messager:(id<FlutterBinaryMessenger>)messager {
    self = [super init];
    if (self) {
        _viewController = viewController;
        _messenger = messager;
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    
    if ([@"pickImages" isEqualToString:call.method]) {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (status == PHAuthorizationStatusDenied) {
            if (result) {
                result([FlutterError errorWithCode:@"PERMISSION_PERMANENTLY_DENIED"
                                           message:@"The user has denied the gallery access."
                                           details:nil]);
                return;
            }
        }
        
        BSImagePickerViewController *pickerViewContoller = [[BSImagePickerViewController alloc] init];
        
        NSDictionary *arguments = call.arguments;
        NSInteger maxImages = [arguments[@"maxImages"] integerValue];
        BOOL enableCamera = [arguments[@"enableCamera"] boolValue];
        NSDictionary *options = arguments[@"iosOptions"];
        NSArray *selectedAssets = arguments[@"selectedAssets"];
        pickerViewContoller.maxNumberOfSelections = maxImages;
        
        if (enableCamera) {
            pickerViewContoller.takePhotos = YES;
        }
        
        if (selectedAssets.count > 0) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:selectedAssets options:nil];
            pickerViewContoller.defaultSelections = fetchResult;
        }
        
        id takePhotoIcon = options[@"takePhotoIcon"];
        if (takePhotoIcon)  {
            if ([takePhotoIcon length] > 0) {
                pickerViewContoller.takePhotoIcon = [UIImage imageNamed:takePhotoIcon];
            }
        }
        
        id backgroundColor = options[@"backgroundColor"];
        if (backgroundColor) {
            if ([backgroundColor length] > 0) {
                pickerViewContoller.backgroundColor = [self hexStringToUIColor:backgroundColor];
            }
        }
        
        id selectionFillColor = options[@"selectionFillColor"];
        if (selectionFillColor) {
            if ([selectionFillColor length] > 0) {
                pickerViewContoller.selectionFillColor = [self hexStringToUIColor:selectionFillColor];
            }
        }
        
        id selectionShadowColor = options[@"selectionShadowColor"];
        if (selectionShadowColor) {
            if ([selectionShadowColor length] > 0) {
                pickerViewContoller.selectionShadowColor = [self hexStringToUIColor:selectionShadowColor];
            }
        }
        
        id selectionStrokeColor = options[@"selectionStrokeColor"];
        if (selectionStrokeColor) {
            if ([selectionStrokeColor length] > 0) {
                pickerViewContoller.selectionStrokeColor = [self hexStringToUIColor:selectionStrokeColor];
            }
        }
        
        id selectionTextColor = options[@"selectionTextColor"];
        if (selectionTextColor) {
            if ([selectionTextColor length] > 0) {
//                pickerViewContoller.selectionTextAttributes[NSForegroundColorAttributeName] = nil;
            }
        }
    
        id selectionCharacter = options[@"selectionCharacter"];
        if (selectionCharacter) {
            if ([selectionCharacter length] > 0) {
//                pickerViewContoller.selectionCharacter = nil;
            }
        }
        
        
        [_viewController bs_presentImagePickerController:pickerViewContoller animated:YES select:^(PHAsset * _Nonnull selectAsset) {

        } deselect:^(PHAsset * _Nonnull deselectAsset) {

        } cancel:^(NSArray<PHAsset *> * _Nonnull cancel) {
            if (result) {
                result([FlutterError errorWithCode:@"CANCELLED"
                                           message:@"The user has cancelled the selection."
                                           details:nil]);
            }
        } finish:^(NSArray<PHAsset *> * _Nonnull assets) {
            NSMutableArray *results = [NSMutableArray arrayWithCapacity:0];
            for (PHAsset *asset in assets) {
                NSMutableDictionary *dictAsset = [NSMutableDictionary dictionaryWithCapacity:0];
                [dictAsset setObject:asset.localIdentifier forKey:@"identifier"];
                [dictAsset setObject:@(asset.pixelWidth) forKey:@"width"];
                [dictAsset setObject:@(asset.pixelHeight) forKey:@"height"];
                [dictAsset setObject:asset.originalFilename forKey:@"name"];
                [results addObject:dictAsset];
            }
            if (result) {
                result(results);
            }
        } completion:^{

        } selectLimitReached:^(NSInteger selectionLimit) {

        }];
    }
    else if ([@"requestThumbnail" isEqualToString:call.method]) {
        
        NSDictionary *arguments = call.arguments;
        NSString *identifier = arguments[@"identifier"];
        NSInteger width = [arguments[@"width"] integerValue];
        NSInteger height = [arguments[@"height"] integerValue];
        NSInteger quality = [arguments[@"quality"] integerValue];
        
        PHImageManager *manager = [PHImageManager defaultManager];
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        options.resizeMode = PHImageRequestOptionsResizeModeExact;
        options.synchronous = NO;
        options.networkAccessAllowed = YES;
        
        PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
        
        if (fetchResult.count > 0) {
            PHAsset *asset = fetchResult[0];
            PHImageRequestID requestId = [manager requestImageForAsset:asset targetSize:CGSizeMake(width, height) contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                if (self.messenger && [self.messenger respondsToSelector:@selector(sendOnChannel:message:)]) {
                    [self.messenger sendOnChannel:[NSString stringWithFormat:@"multi_image_picker/image/%@.thumb", identifier] message:UIImageJPEGRepresentation(result, quality / 100.0)];
                }
            }];
            
            if(PHInvalidImageRequestID != requestId) {
                if (result) {
                    result(@(YES));
                    return;
                };
            }
        }
        
        if (result) {
            result([FlutterError errorWithCode:@"ASSET_DOES_NOT_EXIST"
                                       message:@"The requested image does not exist."
                                       details:nil]);
        }
    }
    else if ([@"requestOriginal" isEqualToString:call.method]) {
        
        NSDictionary *arguments = call.arguments;
        NSString *identifier = arguments[@"identifier"];
        NSInteger quality = [arguments[@"quality"] integerValue];

        PHImageManager *manager = [PHImageManager defaultManager];
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        options.synchronous = NO;
        options.networkAccessAllowed = YES;
        
        PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
        
        if (fetchResult.count > 0) {
            PHAsset *asset = fetchResult[0];
            PHImageRequestID requestId = [manager requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                if (self.messenger && [self.messenger respondsToSelector:@selector(sendOnChannel:message:)]) {
                    [self.messenger sendOnChannel:[NSString stringWithFormat:@"multi_image_picker/image/%@.original", identifier] message:UIImageJPEGRepresentation(result, quality / 100.0)];
                }
            }];
            
            if(PHInvalidImageRequestID != requestId) {
                if (result) {
                    result(@(YES));
                }
                return;
            }
        }
        
        if (result) {
            result([FlutterError errorWithCode:@"ASSET_DOES_NOT_EXIST"
                                       message:@"The requested image does not exist."
                                       details:nil]);
        }
    }
    else if ([@"refreshImage" isEqualToString:call.method]) {
        if (result) {
            result(@(YES));
        }
    }
    else if ([@"requestFilePath" isEqualToString:call.method]) {
        
        NSDictionary *arguments = call.arguments;
        NSString *identifier = arguments[@"identifier"];
        
        PHImageManager *manager = [PHImageManager defaultManager];
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        options.synchronous = NO;
        options.networkAccessAllowed = YES;
        
        PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
        
        if (fetchResult.count > 0) {
            PHAsset *asset = fetchResult[0];
            [self getURLPhotoWithAsset:asset completionHandler:^(NSURL *responseURL) {
                if (responseURL) {
                    NSURL *url = responseURL;
                    NSString *slicedUrl = [url path];
                    if (result) {
                        result(slicedUrl);
                    }
                }
            }];
        }
        else {
            if (result) {
                result([FlutterError errorWithCode:@"ASSET_DOES_NOT_EXIST"
                                           message:@"The requested image does not exist."
                                           details:nil]);
            }
        }
    }
    else if ([@"requestMetadata" isEqualToString:call.method]) {
        
        NSDictionary *arguments = call.arguments;
        NSString *identifier = arguments[@"identifier"];
        
        NSOperationQueue *queue = [NSOperationQueue currentQueue];
        
        PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
        
        [queue addOperationWithBlock:^{
            [self readPhotosMetadataWithResult:fetchResult operationQueue:queue complete:result];
        }];
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)getURLPhotoWithAsset:(PHAsset *)asset completionHandler:(nullable void (^)(NSURL *responseURL))complete {
    PHContentEditingInputRequestOptions *options = [[PHContentEditingInputRequestOptions alloc] init];
    options.canHandleAdjustmentData = ^BOOL(PHAdjustmentData * _Nonnull adjustmentData) {
        return YES;
    };
    [asset requestContentEditingInputWithOptions:options completionHandler:^(PHContentEditingInput * _Nullable contentEditingInput, NSDictionary * _Nonnull info) {
        if (complete) {
            complete(contentEditingInput.fullSizeImageURL);
        }
    }];
}

- (void)readPhotosMetadataWithResult:(PHFetchResult *)result operationQueue:(NSOperationQueue *)queue complete:(FlutterResult)complete {
    PHImageManager *imageManager = [PHImageManager defaultManager];
    [result enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.networkAccessAllowed = YES;
        options.synchronous = NO;
        [imageManager requestImageDataForAsset:obj options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
            [queue addOperationWithBlock:^{
                NSData *data = imageData;
                NSDictionary *metaData = [MultiImagePickerPlugin fetchPhotoMetadata:data];
                if (complete) {
                    complete(metaData);
                }
            }];
        }];

    }];
}

+ (NSDictionary *)fetchPhotoMetadata:(NSData *)data {
    CFDataRef dataref = CFBridgingRetain(data);
    CGImageSourceRef selectedImageSourceRef = CGImageSourceCreateWithData(dataref, nil);
    CFDictionaryRef imagePropertiesDictionary = CGImageSourceCopyPropertiesAtIndex(selectedImageSourceRef, 0, nil);
    return (__bridge_transfer NSDictionary *)imagePropertiesDictionary;
}

- (UIColor *)hexStringToUIColor:(NSString *)hex {
    NSString *string = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    if ([string hasPrefix:@"#"]) {
        NSRange range = [string rangeOfString:@"#"];
        string = [string substringFromIndex:range.location + range.length];
    }
    
    if (string.length != 6) {
        return [UIColor grayColor];
    }
    
    unsigned rgbValue = 0;
    NSScanner *scanner = [[NSScanner alloc] initWithString:string];
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16) / 255.0
                           green:((rgbValue & 0x00FF00) >> 8) / 255.0
                            blue:(rgbValue & 0x0000FF) / 255.0
                           alpha:1.0];
}

@end
