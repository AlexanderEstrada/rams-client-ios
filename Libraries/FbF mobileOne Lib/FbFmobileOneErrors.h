//
//  FbFmobileOneErrors.h
//  FbF mobileOne Library
//
//  Created by Philip A. Walton on 4/20/11.
//  Copyright 2011 Fulcrum Biometrics, LLC. All rights reserved.
//

//////////////////////////////////////////////////////////////////////////////////////////
/// @name Error Exceptions
//////////////////////////////////////////////////////////////////////////////////////////

/**
 No Error Received
 */
#define FBF_ERROR_NONE 0
/**
 Unexpected data was recieved from the mobileOne and the data communication was resynchronized.  Invalid data will be lost.
 */
#define FBF_ERROR_BAD_DATA 1000
/**
 The data stream from the mobileOne was terminated unexpectedly.  Invalid data will be lost.
 */
#define FBF_ERROR_STREAM_ENDED 1001
/**
 An unknown exception occured on the mobileOne.
 */
#define FBF_ERROR_UNKNOWN 9999
