//
//  ABI25_0_0EXMailComposer.m
//  Exponent
//
//  Created by Alicja Warchał on 20.12.2017.
//  Copyright © 2017 650 Industries. All rights reserved.
//

#import "ABI25_0_0EXMailComposer.h"
#import "ABI25_0_0EXFileSystem.h"
#import <ReactABI25_0_0/ABI25_0_0RCTConvert.h>
#import <ReactABI25_0_0/ABI25_0_0RCTLog.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface ABI25_0_0EXMailComposer ()

@property (nonatomic, strong) ABI25_0_0RCTPromiseResolveBlock resolve;
@property (nonatomic, strong) ABI25_0_0RCTPromiseRejectBlock reject;

@end

@implementation ABI25_0_0EXMailComposer

ABI25_0_0RCT_EXPORT_MODULE(ExponentMailComposer);

@synthesize bridge = _bridge;

- (void)setBridge:(ABI25_0_0RCTBridge *)bridge
{
  _bridge = bridge;
}

ABI25_0_0RCT_EXPORT_METHOD(composeAsync:(NSDictionary *)options
                  resolver:(ABI25_0_0RCTPromiseResolveBlock)resolve
                  rejecter:(ABI25_0_0RCTPromiseRejectBlock)reject)
{
  if (![MFMailComposeViewController canSendMail]) {
    reject(@"E_COMPOSE_UNAVAILABLE", @"Mail services are not available.", nil);
    return;
  }
  
  MFMailComposeViewController* composeController = [[MFMailComposeViewController alloc] init];
  composeController.mailComposeDelegate = self;
  
  NSMutableArray *recipients = [[NSMutableArray alloc] init];
  for (NSString *recipient in options[@"recipients"]) {
    [recipients addObject:recipient];
  }
  [composeController setToRecipients:recipients];
  
  NSMutableArray *ccRecipients = [[NSMutableArray alloc] init];
  for (NSString *ccRecipient in options[@"ccRecipients"]) {
    [ccRecipients addObject:ccRecipient];
  }
  [composeController setCcRecipients:ccRecipients];
  
  NSMutableArray *bccRecipients = [[NSMutableArray alloc] init];
  for (NSString *bccRecipient in options[@"bccRecipients"]) {
    [bccRecipients addObject:bccRecipient];
  }
  [composeController setBccRecipients:bccRecipients];
  
  if (options[@"subject"] != nil) {
    [composeController setSubject:options[@"subject"]];
  }
  
  if (options[@"body"] != nil) {
    BOOL isHTML = NO;
    if (options[@"isHtml"]) {
      isHTML = YES;
    }
    [composeController setMessageBody:options[@"body"] isHTML:isHTML];
  }
  
  if (options[@"attachments"] != nil) {
    for (NSString *uri in options[@"attachments"]) {
      NSURL *url = [NSURL URLWithString:uri];
      NSString *path = [url.path stringByStandardizingPath];
      if (!([self.bridge.scopedModules.fileSystem permissionsForURI:url] & ABI25_0_0EXFileSystemPermissionRead)) {
        reject(@"E_FILESYSTEM_PERMISSIONS", [NSString stringWithFormat:@"File '%@' isn't readable.", uri], nil);
        return;
      }
      
      if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        reject(@"E_INVALID_ATTACHMENT", [NSString stringWithFormat:@"The file does not exist. Given path: `%@`.", path], nil);
        return;
      }
      
      CFStringRef identifier = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[path pathExtension], NULL);
      CFStringRef typeRef = UTTypeCopyPreferredTagWithClass (identifier, kUTTagClassMIMEType);
      CFRelease(identifier);
      NSString *mimeType = [NSString stringWithString:(__bridge NSString *)(typeRef)];
      CFRelease(typeRef);
      
      NSData *fileData = [NSData dataWithContentsOfFile:path];
      
      [composeController addAttachmentData:fileData mimeType:mimeType fileName:[path lastPathComponent]];
    }
  }

  self.resolve = resolve;
  self.reject = reject;
  dispatch_async(dispatch_get_main_queue(), ^{
    [ABI25_0_0RCTPresentedViewController() presentViewController:composeController animated:YES completion:nil];
  });
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
  
  if (self.resolve != nil && self.reject != nil) {
    if (error != nil) {
      self.reject(@"E_MAIL_ERROR", @"An error occurred while trying to send the e-mail.", error);
      self.reject = nil;
      self.resolve = nil;
      return;
    }
    
    switch (result) {
      case MFMailComposeResultSent:
        self.resolve(@{ @"status": @"sent" });
        break;
      case MFMailComposeResultSaved:
        self.resolve(@{ @"status": @"saved" });
        break;
      case MFMailComposeResultCancelled:
        self.resolve(@{ @"status": @"cancelled" });
        break;
      case MFMailComposeResultFailed:
        self.reject(@"E_MAIL_ERROR", @"Something went wrong while trying to send the e-mail.", error);
        break;
      default:
        self.reject(@"E_MAIL_ERROR", @"Something went wrong while trying to send the e-mail.", error);
        break;
    }
    
    self.reject = nil;
    self.resolve = nil;
  }
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [controller dismissViewControllerAnimated:YES completion:nil];
  });
}

@end
