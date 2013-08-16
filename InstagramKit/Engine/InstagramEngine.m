//
//    Copyright (c) 2013 Shyam Bhat
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy of
//    this software and associated documentation files (the "Software"), to deal in
//    the Software without restriction, including without limitation the rights to
//    use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//    the Software, and to permit persons to whom the Software is furnished to do so,
//    subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//    FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//    COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//    IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "InstagramEngine.h"
#import "InstagramUser.h"
#import "InstagramMedia.h"

#define kInstagramAPIBaseURL @"https://api.instagram.com/v1/"
#define kInstagramAuthorizationURL @"https://api.instagram.com/oauth/authorize/"

#define kAppClientID @"fe23f3a4303d4970a52b1d2ab143f60c"
#define kAppClientSecret CypressAppClientSecret

#define kKeyClientID @"client_id"
#define kKeyAccessToken @"access_token"

#define kData @"data"

@interface InstagramEngine()
{
    dispatch_queue_t mBackgroundQueue;
}

@property (nonatomic, strong) NSString *accessToken;

@end
@implementation InstagramEngine

#pragma mark - Initializers -

+ (InstagramEngine *)sharedEngine {
    static InstagramEngine *_sharedEngine = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _sharedEngine = [[self alloc] initWithBaseURL:[NSURL URLWithString:kInstagramAPIBaseURL]];
    });
    return _sharedEngine;
}


- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
	mBackgroundQueue = dispatch_queue_create("background", NULL);
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [self setDefaultHeader:@"Accept" value:@"application/json"];
    
    return self;
}


#pragma mark - Authentication -

- (void)presentAuthenticationDialog
{
    
}

#pragma mark - Base Call -

- (void)getPath:(NSString*)path
     responseModel:(Class)modelClass
     parameters:(NSDictionary *)parameters
        success:(void (^)(id response))success
        failure:(void (^)(NSError* error, NSInteger statusCode))failure
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:parameters];
    if (self.accessToken) {
        [params setObject:self.accessToken forKey:kKeyAccessToken];
    }
    [params setObject:kAppClientID forKey:kKeyClientID];
    [super getPath:path
        parameters:params
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               NSDictionary *responseDictionary = (NSDictionary *)responseObject;
               BOOL collection = ([responseDictionary[kData] isKindOfClass:[NSArray class]]);
               if (collection) {
                   NSArray *responseObjects = responseDictionary[kData];
                   NSMutableArray*objects = [NSMutableArray arrayWithCapacity:responseObjects.count];
                   dispatch_async(mBackgroundQueue, ^{
                       for (NSDictionary *info in responseObjects) {
                           id model = [[modelClass alloc] initWithInfo:info];
                           [objects addObject:model];
                       }
                       dispatch_async(dispatch_get_main_queue(), ^{
                           success(objects);
                       });
                   });
               }
               else {
                   id model = [[modelClass alloc] initWithInfo:responseDictionary[kData]];
                   success(model);
               }
           }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               failure(error,[[operation response] statusCode]);
           }];
}


#pragma mark - Media -

- (void)getPopularMediaWithSuccess:(void (^)(NSArray *media))success
                           failure:(void (^)(NSError* error))failure
{
    [self getPath:@"media/popular" responseModel:[InstagramMedia class] parameters:nil success:^(id response) {
        NSArray *objects = response;
        success(objects);
    } failure:^(NSError *error, NSInteger statusCode) {
        failure(error);
    }];
}

- (void)getMediaDetails:(NSString *)mediaID
               withSuccess:(void (^)(InstagramMedia *media))success
                   failure:(void (^)(NSError* error))failure
{
    [self getPath:[NSString stringWithFormat:@"media/%@",mediaID] responseModel:[InstagramMedia class] parameters:nil success:^(id response) {
        InstagramMedia *media = response;
        success(media);
    } failure:^(NSError *error, NSInteger statusCode) {
        failure(error);
    }];
}



#pragma mark - Users -

//- (void)requestUserDetails:(NSString *)userID
//               withSuccess:(void (^)(NSDictionary *userDetails))success
//                   failure:(void (^)(NSError* error, NSInteger statusCode))failure
//{
//    NSString *path = [NSString stringWithFormat:@"media/popular?client_id=fe23f3a4303d4970a52b1d2ab143f60c"];
//    [self bodyForPath:path method:@"GET" body:nil onCompletion:^(NSDictionary *responseBody) {
//        NSArray *mediaInfo = responseDictionary[kData];
//        NSMutableArray*objects = [NSMutableArray arrayWithCapacity:mediaInfo.count];
//        for (NSDictionary *info in mediaInfo) {
//            InstagramMedia *media = [[InstagramMedia alloc] initWithInfo:info];
//            [objects addObject:media];
//        }
//        NSArray *mediaArray = [NSArray arrayWithArray:objects];
//        success(mediaArray);
//
//    } onError:^(NSError *error) {
//        NSLog(@"Error : %@",error.description);
//        failure(error);
//    }];
//}

@end
