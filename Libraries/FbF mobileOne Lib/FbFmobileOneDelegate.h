//
//  FbFmobileOneDelegate.h
//  FbF mobileOne Library
//
//  Created by Philip A. Walton on 4/20/11.
//  Copyright 2012 Fulcrum Biometrics, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

//////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////
/** The FbFmobileOneDelegate protocol provides the messaging interface between an iOS application and the FbF mobileOne.    
 
 */

@class FbFAccessoryController;

@protocol FbFmobileOneDelegate <NSObject>

@required

/** Notifies the application that the mobileOne has been disconnected or connected.  The same message is called for both events with a different connected value.
 
 @param connected The BOOL value indicating whether the mobileOne is connected.
 */
- (void) mobileOneAccessoryController:(FbFAccessoryController *)mobileOne didChangeConnectionStatus:(BOOL)connected;

/** This is the primary message for receiving data from the mobileOne.  If the didReceiveData message is triggered then the data parameter will have a fully formed byte array of bitmap data.  This data can be easily converted to a UIImage using the static method [UIImage imageWithData:data].
 
 It is important to know that the size of the bitmap image is determined by the type of scanner used in the mobileOne accessory.  The following is a list of image dimensions based upon the scanner hardware:
        - mobileOne with UPEK Touchchip 256x360 at 508dpi
        - mobileOne with Digital Persona 356x382 at 500dpi
        - mobileOne with UPEK Swipe 192x512 at 508dpi
 
 @param data The bitmap data returned from the mobileOne.
 */
- (void) mobileOneAccessoryController:(FbFAccessoryController *)mobileOne didReceiveData:(NSData *)data;

@optional

/** This optional message indicates that an error was encountered in the processing of the mobileOne data.  The code will correspond to the values in the FbfmobileOneErrors.h file.
 
 @param error The error object containing the error code.
 */
- (void) mobileOneAccessoryController:(FbFAccessoryController *)mobileOne didReceiveError:(NSError *)error;

/** This optional message indicates when the mobileOne has started or stopped scanning.
 
 @param started This BOOL will be true of the scanner is started and false if stopped.
 */
- (void) mobileOneAccessoryController:(FbFAccessoryController *)mobileOne didReceiveScannerStartStop:(BOOL)started;

/** This optional message indicates that a data transmission has started.  Since the mobileOne communicates over HID packets, the maximum performance for transmitting an image is 600ms for a non-PIV and 900ms for a PIV image.  In order to provide an indication to the user that the fingerprint has been captured and the data is being sent, the didReceiveDataSpin will indicate the start and stop of the data transmission.  At the point that the didReceiveDataSpin message is received, the entire fingerprint has been captured and the user should remove their finger.  Failure to remove the finger will result in additional images being captured at a rate of approximately 1 per second.
 
 @param started This BOOL value indicates that data transmission has started or stopped.
 */
- (void) mobileOneAccessoryController:(FbFAccessoryController *)mobileOne didReceiveDataSpin:(BOOL)started;


@end
