//
//  PhotoAlbumManager.h
//  CameraApp
//
//  Created by pongsil on 8/2/13.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import <AssetsLibrary/AssetsLibrary.h>
#import "ALAssetsLibrary+CustomPhotoAlbum.h"

typedef void (^LoadImageResponseBlock)(NSMutableArray* result);
typedef void (^LoadImageErrorBlock)(NSError* error);

@interface PhotoAlbumManager : NSObject

/** @name Creating AlbumManager Objects */

/** Initializes and returns a newly allocated AlbumManager object for the specified Library name.
 *   @param libraryName The string libraryName to saving Image into.  
 */
- (id)initWithLibraryName:(NSString *)libraryName;


/** @name Load/Save image into AssetLibrary */

/** Load Preview Image in only image in Library name and has ResponseBlock to return all Preview image
 *   @param ResponseBlock The LoadImageResponseBlock to call back when complete. 
 *   @param errorBlock The LoadImageErrorBlock to call back if error.
 */
-(void)loadPreviewImagesOnCompletionBlock:(LoadImageResponseBlock)ResponseBlock errorHandler:(LoadImageErrorBlock)errorBlock;

/** Load Preview Image near by Location and only image in Library name and has ResponseBlock to return all Preview image
 *   @param Location The CLLocationCoordinate2D to search neaby image by location
 *   @param ResponseBlock The LoadImageResponseBlock to call back when complete.
 *   @param errorBlock The LoadImageErrorBlock to call back if error.
 */
-(void)loadPreviewImagesNearLocation:(CLLocationCoordinate2D)location OnCompletionBlock:(LoadImageResponseBlock)ResponseBlock errorHandler:(LoadImageErrorBlock)errorBlock;

/** Save Images in library name and insert GPS Data
 *   @param info The NSDictionary for input image and default meta data.
 *   @param locationManager the CLLocationManager to extract gps data and use for insert into image meta data
 *   @param completionBlock the SaveImageCompletion to callback when save complete
 */
- (void)saveImageWithGPSForMediaInfo:(NSDictionary *)info withLocation:(CLLocation *)location andHeading:(CLHeading*)heading onComplete:(SaveImageCompletion)completionBlock;

/** Get GPSDictionry in Image Meta Data Form from loation and heading
 *   @param location The location for GPS of image.
 *   @param heading the CLHeading for heading of image
 *   @return NSDictionary the GPS Data in Dictionary Form
 */
- (NSDictionary *)getGPSDictionaryFromLocation:(CLLocation *)location andHeading:(CLHeading *)heading;



@end

@interface PreviewImage : NSObject

@property (nonatomic,strong) UIImage *thumbnail;
@property (nonatomic,strong) NSDictionary *metaData;

/** @name Creating PreviewImage Objects */

/** Initializes and returns a newly allocated PreviewImage object for the specified Thumbnail image and Metadata.
 *   @param thumbnail The image in object. 
 *   @param metaData The NSDictionary for decribe image MetaData **/
- (id)initWithThumbnail:(UIImage *)thumbnail andMetaData:(NSDictionary *)metaData;

@end
