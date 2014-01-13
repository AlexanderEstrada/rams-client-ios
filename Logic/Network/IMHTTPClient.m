//
//  PMHTTPClient.m
//  Pandume
//
//  Created by Mario Yohanes on 6/20/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMHTTPClient.h"
#import "IMConstants.h"
#import "IMAuthManager.h"


@implementation IMHTTPClient

+ (IMHTTPClient *)sharedClient
{
    static dispatch_once_t once;
    static IMHTTPClient *singleton = nil;
    
    dispatch_once(&once, ^{
        singleton = [[IMHTTPClient alloc] init];
    });
    
    return singleton;
}

- (id)init
{
    self = [super initWithBaseURL:[NSURL URLWithString:IMBaseURL]];
    
    self.parameterEncoding = AFFormURLParameterEncoding;
    [self setDefaultHeader:@"User-Agent" value:@"IMS for iPad"];
    [self setDefaultHeader:@"Accept" value:@"application/json"];
    [self setupAuthenticationHeader];
    [self setAllowsInvalidSSLCertificate:YES];
    
    return self;
}

- (void)setupAuthenticationHeader
{
    NSString *accessToken = [IMAuthManager sharedManager].activeUser.accessToken;
    if (accessToken) { [self setAuthorizationHeaderWithUsername:IMAPIKey password:accessToken]; }
    else { [self clearAuthorizationHeader]; NSLog(@"default headers: %@", [self defaultValueForHeader:@"Authorization"]); }
}

- (void)getJSONWithPath:(NSString *)path
             parameters:(NSDictionary *)parameters
                success:(void (^)(NSDictionary *jsonData, int statusCode))success
                failure:(void (^)(NSError *))failure
{
    self.parameterEncoding = AFFormURLParameterEncoding;
    NSMutableURLRequest *request = [self requestWithMethod:@"GET" path:path parameters:parameters];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                      success:^(NSURLRequest *request, NSHTTPURLResponse *response, id json){
                                                                                          if (success) success(json, response.statusCode);
                                                                                      }
                                                                                      failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id json){
                                                                                          if ([self processResponse:response]) {
                                                                                              if (failure) failure(error);
                                                                                          }
                                                                                      }];
    [self enqueueHTTPRequestOperation:operation];
}

- (void)postJSONWithPath:(NSString *)path
              parameters:(NSDictionary *)parameters
                 success:(void (^)(NSDictionary *jsonData, int statusCode))success
                 failure:(void (^)(NSDictionary *jsonData, NSError *error, int statusCode))failure
{
    self.parameterEncoding = AFJSONParameterEncoding;
    NSMutableURLRequest *request = [self requestWithMethod:@"POST" path:path parameters:parameters];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id json){
                                                                                            if (success) success(json, response.statusCode);
                                                                                        }
                                                                                        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id json){
                                                                                            if ([self processResponse:response]) {
                                                                                                if (failure) failure(json, error, response.statusCode);
                                                                                            }
                                                                                        }];
    [self enqueueHTTPRequestOperation:operation];
    self.parameterEncoding = AFFormURLParameterEncoding;
}

- (void)getPhotoWithId:(NSString *)photoId
               success:(void (^)(NSData *imageData))success
               failure:(void (^)(NSError *error))failure
{
    self.parameterEncoding = AFFormURLParameterEncoding;
    [self getPath:@"photo"
       parameters:@{@"id":photoId}
          success:^(AFHTTPRequestOperation *operation, NSData *responseObject){
              if ([responseObject isKindOfClass:[NSData class]]) {
                  if (success) success(responseObject);
              }else if (failure) {
                  failure([NSError errorWithDomain:@"Null Pointer Exception" code:0 userInfo:nil]);
              }
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error){
              if (failure) failure(error);
          }];
}

- (BOOL)processResponse:(NSHTTPURLResponse *)httpResponse
{
    if (httpResponse.statusCode == 401 || httpResponse.statusCode == 403) {
        NSDictionary *userInfo;
        if (httpResponse.statusCode == 401) {
            userInfo = @{IMSyncKeyError: NSLocalizedString(@"Authentication Failed", @"Authentication Failed")};
        }else if (httpResponse.statusCode == 403) {
            userInfo = @{IMSyncKeyError: NSLocalizedString(@"Forbidden Access", @"Forbidden Access")};
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{ [[IMAuthManager sharedManager] logout]; });
        
        return NO;
    }
    
    return YES;
}

@end
