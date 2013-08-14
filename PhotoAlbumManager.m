//
//  PhotoAlbumManager.m
//  CameraApp
//
//  Created by pongsil on 8/2/13.
//

#import "PhotoAlbumManager.h"
#import <ImageIO/ImageIO.h>

#define NEARBY_RADIUS   0.03
#define DEFAULT_LIBRARY @"CameraApp"

@interface PhotoAlbumManager()

@property (nonatomic,strong) NSString* libraryName;

/** @name Load/Save image into AssetLibrary */

/** Load Preview Image for specific assetgroup
 *   @param asset Group The ALAssetsGroup yo load image.
 *   @return all preview image as NSMutableArray.
 */
- (NSMutableArray*)loadPreviewImagesNearLocation:(CLLocationCoordinate2D)location inAssetGroup:(ALAssetsGroup *)assetGroup;

@end

@implementation PhotoAlbumManager

- (id)init{
    if (self = [super init])
    {
        _libraryName = DEFAULT_LIBRARY;
        return self;
    }
    return nil;
}

- (id)initWithLibraryName:(NSString *)libraryName{
    if (self = [super init])
    {
        _libraryName = libraryName;
        return self;
    }
    return nil;
}

-(void)loadPreviewImagesOnCompletionBlock:(LoadImageResponseBlock)ResponseBlock errorHandler:(LoadImageErrorBlock)errorBlock{
    
    [self loadPreviewImagesNearLocation:CLLocationCoordinate2DMake(0, 0) OnCompletionBlock:ResponseBlock errorHandler:errorBlock];
}

-(void)loadPreviewImagesNearLocation:(CLLocationCoordinate2D)location OnCompletionBlock:(LoadImageResponseBlock)ResponseBlock errorHandler:(LoadImageErrorBlock)errorBlock{

    // Group enumerator Block    
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       void (^assetGroupEnumerator)( ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop)
                       {
                           if (group == nil)
                           {
                               return;
                           }
                           if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:_libraryName]) {
                               NSMutableArray *result = [self loadPreviewImagesNearLocation:location inAssetGroup:group];
                               ResponseBlock(result);
                           }
                           
                           if (stop) {
                               return;
                           }
                           
                       };
                       
                       // Group Enumerator Failure Block
                       void (^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *error) {
                           
                           UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"ERROR" message:[NSString stringWithFormat:@"No Albums Available"] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                           [alert show];
                       };
                       
                       // Enumerate Albums
                       ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                       [library enumerateGroupsWithTypes:ALAssetsGroupAll
                                              usingBlock:assetGroupEnumerator
                                            failureBlock:assetGroupEnumberatorFailure];
                       
                       
                   });
    
}

- (NSMutableArray*)loadPreviewImagesNearLocation:(CLLocationCoordinate2D)location inAssetGroup:(ALAssetsGroup *)assetGroup{
    
    NSMutableArray *response = [[NSMutableArray alloc] init];
    
    [assetGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop)
     {
         if(result == nil)
         {
             return;
         }
         
         ALAssetRepresentation *assetRepresentation = [result defaultRepresentation];

         UIImage *thumbnail = [UIImage imageWithCGImage:[result thumbnail]];
                               //[assetRepresentation CGImageWithOptions:thumbnailOptions]];
         NSDictionary *metaData = [assetRepresentation metadata];
         
         PreviewImage *previewImage = [[PreviewImage alloc] initWithThumbnail:thumbnail andMetaData:metaData];
         
         BOOL isNearImage = YES;
         
         if (CLLocationCoordinate2DIsValid(location)){
             double lat = [[[metaData objectForKey:@"{GPS}"] objectForKey:@"Latitude"] doubleValue];
             double lng = [[[metaData objectForKey:@"{GPS}"] objectForKey:@"Longitude"] doubleValue];
             
             if ([self calculateDistanceOfLat1:lat Lng1:lng Lat2:[[NSNumber numberWithDouble:location.latitude] doubleValue] Lng2:[[NSNumber numberWithDouble:location.longitude] doubleValue]] > NEARBY_RADIUS)
                 isNearImage = NO;
         }
         
         if (isNearImage)
             [response addObject:previewImage];
         
//         if (index == 0){
//             lat = [[[[[result defaultRepresentation] metadata] objectForKey:@"{GPS}"] objectForKey:@"Latitude"] doubleValue];
//             lng = [[[[[result defaultRepresentation] metadata] objectForKey:@"{GPS}"] objectForKey:@"Longitude"] doubleValue];
//         }
//         else {
//             NSLog(@"%f",[self calculateDistanceOfLat1:lat Lng1:lng Lat2:[[[[[result defaultRepresentation] metadata] objectForKey:@"{GPS}"] objectForKey:@"Latitude"] doubleValue] Lng2:[[[[[result defaultRepresentation] metadata] objectForKey:@"{GPS}"] objectForKey:@"Longitude"] doubleValue]]);
//             
//         }
         //         NSLog(@"Image:Lat->%@ lng->%@ Direction->%@",[[[[result defaultRepresentation] metadata] objectForKey:@"{GPS}"] objectForKey:@"Latitude"],[[[[result defaultRepresentation] metadata] objectForKey:@"{GPS}"] objectForKey:@"Longitude"],[[[[result defaultRepresentation] metadata] objectForKey:@"{GPS}"] objectForKey:@"ImgDirection"]);
         
         //         NSLog(@"%f",[self calculateDistanceOfLat1:locationManager.location.coordinate.latitude Lng1:locationManager.location.coordinate.longitude Lat2:[[[[[result defaultRepresentation] metadata] objectForKey:@"{GPS}"] objectForKey:@"Latitude"] doubleValue] Lng2:[[[[[result defaultRepresentation] metadata] objectForKey:@"{GPS}"] objectForKey:@"Longitude"] doubleValue]]);
         
         //         UIImage *img = [UIImage imageWithCGImage:[[result defaultRepresentation] fullScreenImage] scale:1.0 orientation:(UIImageOrientation)[[result valueForProperty:@"ALAssetPropertyOrientation"] intValue]];
         
     }];

    return response;
}

- (void)saveImageWithGPSForMediaInfo:(NSDictionary *)info withLocation:(CLLocation *)location andHeading:(CLHeading*)heading onComplete:(SaveImageCompletion)completionBlock{
    
    ///Sava image to photoalbum with metadata
    ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
    NSMutableDictionary *imageMetaData = [[NSMutableDictionary alloc] init];
    
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    ///Load Default metadata And Add Gps Metadata
    [imageMetaData setDictionary:[[info objectForKey:UIImagePickerControllerMediaMetadata] copy]];
    [imageMetaData setObject:[self getGPSDictionaryFromLocation:location andHeading:heading] forKey:(NSString*)kCGImagePropertyGPSDictionary];
    [assetLibrary saveImage:image metadata:imageMetaData toAlbum:_libraryName withCompletionBlock:^(NSError *error) {
        completionBlock(error);
        
    }];
}

- (NSDictionary *)getGPSDictionaryFromLocation:(CLLocation *)location andHeading:(CLHeading *)heading{
    NSMutableDictionary *gps = [NSMutableDictionary dictionary];
    
    // GPS tag version
    [gps setObject:@"2.2.0.0" forKey:(NSString *)kCGImagePropertyGPSVersion];
    
    // Time and date must be provided as strings, not as an NSDate object
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss.SSSSSS"];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [gps setObject:[formatter stringFromDate:location.timestamp] forKey:(NSString *)kCGImagePropertyGPSTimeStamp];
    [formatter setDateFormat:@"yyyy:MM:dd"];
    [gps setObject:[formatter stringFromDate:location.timestamp] forKey:(NSString *)kCGImagePropertyGPSDateStamp];
    
    
    // Latitude
    CLLocationDegrees latitude = location.coordinate.latitude;
    if (latitude < 0) {
        latitude = -latitude;
        [gps setObject:@"S" forKey:(NSString *)kCGImagePropertyGPSLatitudeRef];
    } else {
        [gps setObject:@"N" forKey:(NSString *)kCGImagePropertyGPSLatitudeRef];
    }
    [gps setObject:[NSNumber numberWithDouble:latitude] forKey:(NSString *)kCGImagePropertyGPSLatitude];
    
    // Longitude
    CLLocationDegrees longitude = location.coordinate.longitude;
    if (longitude < 0) {
        longitude = -longitude;
        [gps setObject:@"W" forKey:(NSString *)kCGImagePropertyGPSLongitudeRef];
    } else {
        [gps setObject:@"E" forKey:(NSString *)kCGImagePropertyGPSLongitudeRef];
    }
    [gps setObject:[NSNumber numberWithDouble:longitude] forKey:(NSString *)kCGImagePropertyGPSLongitude];
    
    // Altitude
    double altitude = location.altitude;
    if (!isnan(altitude)){
        if (altitude < 0) {
            altitude = -altitude;
            [gps setObject:@"1" forKey:(NSString *)kCGImagePropertyGPSAltitudeRef];
        } else {
            [gps setObject:@"0" forKey:(NSString *)kCGImagePropertyGPSAltitudeRef];
        }
        [gps setObject:[NSNumber numberWithDouble:altitude] forKey:(NSString *)kCGImagePropertyGPSAltitude];
    }
    
    // Speed, must be converted from m/s to km/h
    if (location.speed >= 0){
        [gps setObject:@"K" forKey:(NSString *)kCGImagePropertyGPSSpeedRef];
        [gps setObject:[NSNumber numberWithDouble:location.speed*3.6] forKey:(NSString *)kCGImagePropertyGPSSpeed];
    }
    
    // Heading
    if (location.course >= 0){
        [gps setObject:@"T" forKey:(NSString *)kCGImagePropertyGPSTrackRef];
        [gps setObject:[NSNumber numberWithDouble:location.course] forKey:(NSString *)kCGImagePropertyGPSTrack];
    }
    
    if (heading.trueHeading >=0){
        [gps setObject:@"T" forKey:(NSString *)kCGImagePropertyGPSImgDirectionRef];
        [gps setObject:[NSNumber numberWithDouble:heading.trueHeading] forKey:(NSString *)kCGImagePropertyGPSImgDirection];
    }
    
    return gps;
}

-(double)calculateDistanceOfLat1:(double)lat1 Lng1:(double)lng1 Lat2:(double)lat2 Lng2:(double)lng2
{
    double distance;
    distance = 6371 * acos(sin(lat1  * (M_PI/180)) * sin(lat2 * (M_PI/180)) +
                           cos(lat1 * (M_PI/180)) * cos(lat2 * (M_PI/180)) * cos(lng2* (M_PI/180) - lng1* (M_PI/180)));
//    NSLog(@"%f",distance);
    return distance;
}

@end

@implementation PreviewImage

- (id)initWithThumbnail:(UIImage *)thumbnail andMetaData:(NSDictionary *)metaData{
    if (self = [super init])
    {
        _thumbnail = thumbnail;
        _metaData = metaData;
        
        return self;
    }
    return nil;
}

@end
