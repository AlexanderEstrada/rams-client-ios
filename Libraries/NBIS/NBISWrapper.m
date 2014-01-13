//
//  NBISWrapper.m
//  NBIS
//
//  Created by Mario Yohanes on 1/23/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "NBISWrapper.h"

#include <nfiq.h>
#include <imgdecod.h>
#include <sys/param.h>
#include <img_io.h>

int debug = 0;

@implementation NBISWrapper

#define kTemplateJunkExtensions     @[@".brw", @".dm", @".hcm", @".lcm", @".lfm", @".min", @".qm"]

+ (NSUInteger)computeNFIQ:(NSString *)imagePath deleteInputWhenDone:(BOOL)shouldDeleteInput
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
        return 0;
    }
    
    int ret;
    unsigned char *idata;
    int img_type, ilen, iw, ih, id, ippi;
    int nfiq;
    float conf;
    int verbose = 0;
    char *inputFile = strstr([imagePath UTF8String], "");
    
    if((ret = read_and_decode_grayscale_image(inputFile, &img_type, &idata, &ilen, &iw, &ih, &id, &ippi))) {
        if(ret == -3) return 0;
            fprintf(stderr, "Hint: Use -raw for raw images\n");
        return 0;
    }
    
    comp_nfiq(&nfiq, &conf, idata, iw, ih, id, ippi, &verbose);
    free(idata);
    
    if (shouldDeleteInput) {
        [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
    }
    
    return nfiq;
}

+ (NSString *)extractTemplate:(NSString *)inputPath intoDirectory:(NSString *)outputPath{
    const char * inputFile = [inputPath UTF8String];
    const char * outputFile = [outputPath UTF8String];
    int m1flag = FALSE;
    char *ifile, *oroot, ofile[MAXPATHLEN];
    unsigned char *idata, *bdata;
    int img_type;
    int ilen, iw, ih, id, ippi, bw, bh, bd;
    double ippmm;
    int *direction_map, *low_contrast_map, *low_flow_map;
    int *high_curve_map, *quality_map;
    int map_w, map_h;
    int ret;
    MINUTIAE *minutiae;
    
    ifile = strstr(inputFile, "");
    oroot = strstr(outputFile, "");
    
    /* Read the image data from file into memory */
    if((ret = read_and_decode_grayscale_image(ifile, &img_type, &idata, &ilen, &iw, &ih, &id, &ippi))){
        return nil;
    }
    
    /* If image ppi not defined, then assume 500 */
    if(ippi == UNDEFINED)
        ippmm = DEFAULT_PPI / (double)MM_PER_INCH;
    else
        ippmm = ippi / (double)MM_PER_INCH;
    
    /* 3. GET MINUTIAE & BINARIZED IMAGE. */
    if((ret = get_minutiae(&minutiae, &quality_map, &direction_map,
                           &low_contrast_map, &low_flow_map, &high_curve_map,
                           &map_w, &map_h, &bdata, &bw, &bh, &bd,
                           idata, iw, ih, id, ippmm, &lfsparms_V2))){
        free(idata);
        return nil;
    }
    
    /* Done with input image data */
    free(idata);
    
    /* 4. WRITE MINUTIAE & MAP RESULTS TO TEXT FILES */
    if((ret = write_text_results(oroot, m1flag, bw, bh,
                                 minutiae, quality_map,
                                 direction_map, low_contrast_map,
                                 low_flow_map, high_curve_map, map_w, map_h))){
        free_minutiae(minutiae);
        free(quality_map);
        free(direction_map);
        free(low_contrast_map);
        free(low_flow_map);
        free(high_curve_map);
        free(bdata);
        return nil;
    }
    
    /* Done with minutiae detection maps. */
    free(quality_map);
    free(direction_map);
    free(low_contrast_map);
    free(low_flow_map);
    free(high_curve_map);
    
    /* 5. WRITE ADDITIONAL RESULTS */
    sprintf(ofile, "%s.%s", oroot, BINARY_IMG_EXT);
    if((ret = write_raw_from_memsize(ofile, bdata, bw*bh))){
        free_minutiae(minutiae);
        free(bdata);
        return nil;
    }
    
    /* Done with minutiae and binary image results */
    free_minutiae(minutiae);
    free(bdata);
    
    //cleanup junk
    NSFileManager *manager = [NSFileManager defaultManager];
    for (NSString *extension in kTemplateJunkExtensions) {
        NSString *targetFile = [NSString stringWithFormat:@"%@%@", outputPath, extension];
        BOOL stat = [manager removeItemAtPath:targetFile error:nil];
        NSLog(@"%@ is %@", targetFile, stat ? @"DELETED" : @"NOT DELETED");
    }
    
    NSString *xytFile = [NSString stringWithFormat:@"%@.xyt", outputPath];
    if ([manager fileExistsAtPath:xytFile]) {
        return xytFile;
    }
    
    return nil;
}

@end
