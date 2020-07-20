#import "AblyFlutterPlugin.h"

// TODO work out why importing Ably as a module does not work like this:
//   @import Ably;
#import "Ably.h"

#import "codec/AblyFlutterReaderWriter.h"
#import "AblyFlutterMessage.h"
#import "AblyFlutter.h"
#import "AblyFlutterStreamHandler.h"
#import "AblyStreamsChannel.h"
#import "codec/AblyPlatformConstants.h"

#define LOG(fmt, ...) NSLog((@"%@:%d " fmt), [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, ##__VA_ARGS__)

NS_ASSUME_NONNULL_BEGIN

typedef void (^FlutterHandler)(AblyFlutterPlugin * plugin, FlutterMethodCall * call, FlutterResult result);

/**
 Anonymous category providing forward declarations of the methods implemented
 by this class for use within this implementation file, specifically from the
 static FlutterHandle declarations.
 */
@interface AblyFlutterPlugin ()
-(void)registerWithCompletionHandler:(FlutterResult)completionHandler;
@end

NS_ASSUME_NONNULL_END

static FlutterHandler _getPlatformVersion = ^void(AblyFlutterPlugin *const plugin, FlutterMethodCall *const call, const FlutterResult result) {
    result([@"iOS (UIKit) " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
};

static FlutterHandler _getVersion = ^void(AblyFlutterPlugin *const plugin, FlutterMethodCall *const call, const FlutterResult result) {
    result([@"CocoaPod " stringByAppendingString:[ARTDefault libraryVersion]]);
};

static FlutterHandler _register = ^void(AblyFlutterPlugin *const plugin, FlutterMethodCall *const call, const FlutterResult result) {
    [plugin registerWithCompletionHandler:result];
};

static FlutterHandler _createRestWithOptions = ^void(AblyFlutterPlugin *const plugin, FlutterMethodCall *const call, const FlutterResult result) {
    AblyFlutterMessage *const message = call.arguments;
    AblyFlutter *const ably = [plugin ably];
    result([ably createRestWithOptions:message.message]);
};

static FlutterHandler _publishRestMessage = ^void(AblyFlutterPlugin *const plugin, FlutterMethodCall *const call, const FlutterResult result) {
    AblyFlutterMessage *const message = call.arguments;
    AblyFlutter *const ably = [plugin ably];
    AblyFlutterMessage *const messageData = message.message;
    NSMutableDictionary<NSString *, NSObject *>* _dataMap = messageData.message;
    NSString *channelName = (NSString*)[_dataMap objectForKey:@"channel"];
    NSString *const eventName = (NSString*)[_dataMap objectForKey:@"name"];
    NSObject *const eventData = (NSString*)[_dataMap objectForKey:@"message"];
    ARTRest *client = [ably getRest:messageData.handle];
    ARTRestChannel *channel = [client.channels get:channelName];

    [channel publish:eventName data:eventData callback:^(ARTErrorInfo *_Nullable error){
        if(error){
            result([
                    FlutterError
                    errorWithCode:[NSString stringWithFormat: @"%ld", (long)error.code]
                    message:[NSString stringWithFormat:@"Unable to publish message to Ably server; err = %@", [error message]]
                    details:error
                    ]);
        }else{
            result(nil);
        }
    }];
};

static FlutterHandler _createRealtimeWithOptions = ^void(AblyFlutterPlugin *const plugin, FlutterMethodCall *const call, const FlutterResult result) {
    AblyFlutterMessage *const message = call.arguments;
    AblyFlutter *const ably = [plugin ably];
    result([ably createRealtimeWithOptions:message.message]);
};

static FlutterHandler _connectRealtime = ^void(AblyFlutterPlugin *const plugin, FlutterMethodCall *const call, const FlutterResult result) {
    AblyFlutterMessage *const message = call.arguments;
    AblyFlutter *const ably = [plugin ably];
    NSNumber *const handle = message.message;
    [[ably realtimeWithHandle:handle] connect];
    result(nil);
};

static FlutterHandler _closeRealtime = ^void(AblyFlutterPlugin *const plugin, FlutterMethodCall *const call, const FlutterResult result) {
    AblyFlutterMessage *const message = call.arguments;
    AblyFlutter *const ably = [plugin ably];
    NSNumber *const handle = message.message;
    [[ably realtimeWithHandle:handle] close];
    result(nil);
};

static FlutterHandler _attachRealtimeChannel = ^void(AblyFlutterPlugin *const plugin, FlutterMethodCall *const call, const FlutterResult result) {
    AblyFlutterMessage *const message = call.arguments;
    AblyFlutter *const ably = [plugin ably];
    AblyFlutterMessage *const data = message.message;
    NSNumber *const realtimeHandle = data.handle;
    ARTRealtime* realtimeWithHandle = [ably realtimeWithHandle: realtimeHandle];
    
    NSDictionary *const realtimePayload = data.message;
    NSString *channelName = (NSString*)[realtimePayload objectForKey:@"channel"];
    ARTChannelOptions *channelOptions = (ARTChannelOptions*)[realtimePayload objectForKey:@"options"];
    ARTRealtimeChannel *channel;
    channel = [realtimeWithHandle.channels get:channelName options:channelOptions];
    [channel attach:^(ARTErrorInfo *_Nullable error){
        if(error){
            result([
                    FlutterError
                    errorWithCode:[NSString stringWithFormat: @"%ld", (long)error.code]
                    message:[NSString stringWithFormat:@"Unable to publish message to Ably server; err = %@", [error message]]
                    details:error
                    ]);
        }else{
            result(nil);
        }
    }];
//    result(nil);
};

static FlutterHandler _detachRealtimeChannel = ^void(AblyFlutterPlugin *const plugin, FlutterMethodCall *const call, const FlutterResult result) {
    AblyFlutterMessage *const message = call.arguments;
    AblyFlutter *const ably = [plugin ably];
    AblyFlutterMessage *const data = message.message;
    NSNumber *const realtimeHandle = data.handle;
    ARTRealtime* realtimeWithHandle = [ably realtimeWithHandle: realtimeHandle];
    
    NSDictionary *const realtimePayload = data.message;
    NSString *channelName = (NSString*)[realtimePayload objectForKey:@"channel"];
    ARTChannelOptions *channelOptions = (ARTChannelOptions*)[realtimePayload objectForKey:@"options"];
    ARTRealtimeChannel *channel;
    channel = [realtimeWithHandle.channels get:channelName options:channelOptions];
    [channel detach:^(ARTErrorInfo *_Nullable error){
        if(error){
            result([
                    FlutterError
                    errorWithCode:[NSString stringWithFormat: @"%ld", (long)error.code]
                    message:[NSString stringWithFormat:@"Unable to publish message to Ably server; err = %@", [error message]]
                    details:error
                    ]);
        }else{
            result(nil);
        }
    }];
//    result(nil);
};

static FlutterHandler _setRealtimeChannelOptions = ^void(AblyFlutterPlugin *const plugin, FlutterMethodCall *const call, const FlutterResult result) {
    // cocoa library doesn't support setOptions yet!
    result(nil);
};


@implementation AblyFlutterPlugin {
    long long _nextRegistration;
    NSDictionary<NSString *, FlutterHandler>* _handlers;
    AblyStreamsChannel* _streamsChannel;
    FlutterMethodChannel* _channel;
}

@synthesize ably = _ably;

+(void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    LOG(@"registrar: %@", [registrar class]);

    // Initializing reader writer and method codecs
    FlutterStandardReaderWriter *const readerWriter = [AblyFlutterReaderWriter new];
    FlutterStandardMethodCodec *const methodCodec = [FlutterStandardMethodCodec codecWithReaderWriter:readerWriter];
    
    // initializing event channel for event listeners
    AblyStreamsChannel *const streamsChannel = [AblyStreamsChannel streamsChannelWithName:@"io.ably.flutter.stream" binaryMessenger:registrar.messenger codec: methodCodec];
    
    // initializing method channel for round-trip method calls
    FlutterMethodChannel *const channel = [FlutterMethodChannel methodChannelWithName:@"io.ably.flutter.plugin" binaryMessenger:[registrar messenger] codec:methodCodec];
    AblyFlutterPlugin *const plugin = [[AblyFlutterPlugin alloc] initWithChannel:channel streamsChannel: streamsChannel];
    
    // regustering method channel with registrar
    [registrar addMethodCallDelegate:plugin channel:channel];
    
    // setting up stream handler factory for eventChannel to handle multiple listeners
    [streamsChannel setStreamHandlerFactory:^NSObject<FlutterStreamHandler> *(id arguments) {
        return [AblyFlutterStreamHandler new];
    }];
    
}

-(instancetype)initWithChannel:(FlutterMethodChannel *const)channel streamsChannel:(AblyStreamsChannel *const)streamsChannel {
    self = [super init];
    if (!self) {
        return nil;
    }
    _ably = [AblyFlutter instance];
    self->_streamsChannel = streamsChannel;
    
    _handlers = @{
        AblyPlatformMethod_getPlatformVersion: _getPlatformVersion,
        AblyPlatformMethod_getVersion: _getVersion,
        AblyPlatformMethod_registerAbly: _register,
        AblyPlatformMethod_createRestWithOptions: _createRestWithOptions,
        AblyPlatformMethod_publish: _publishRestMessage,
        AblyPlatformMethod_createRealtimeWithOptions: _createRealtimeWithOptions,
        AblyPlatformMethod_connectRealtime: _connectRealtime,
        AblyPlatformMethod_closeRealtime: _closeRealtime,
        AblyPlatformMethod_attachRealtimeChannel: _attachRealtimeChannel,
        AblyPlatformMethod_detachRealtimeChannel: _detachRealtimeChannel,
        AblyPlatformMethod_setRealtimeChannelOptions: _setRealtimeChannelOptions
    };
    
    _nextRegistration = 1;
    _channel = channel;
    
    return self;
}

-(void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    LOG(@"%@(%@)", call.method, call.arguments ? [call.arguments class] : @"");
    const FlutterHandler handler = [_handlers objectForKey:call.method];
    if (!handler) {
        // We don't have a handler for a method with this name so tell the caller.
        result(FlutterMethodNotImplemented);
    } else {
        // We have a handler for a method with this name so delegate to it.
        handler(self, call, result);
    }
}

-(void)registerWithCompletionHandler:(const FlutterResult)completionHandler {
    if (!completionHandler) {
        [NSException raise:NSInvalidArgumentException format:@"completionHandler cannot be nil."];
    }
    [_ably disposeWithCompletionHandler:^{
        [self->_streamsChannel reset];
        completionHandler(nil);
    }];
}

@end
