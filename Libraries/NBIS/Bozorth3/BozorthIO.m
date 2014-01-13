//
//  BozorthIO.m
//  Bozorth3
//
//  Created by Mario Yohanes on 1/25/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "BozorthIO.h"

@interface BozorthIO(){
    char program_buffer[ 1024 ];
    char * pfile;
    char * gfile;
    int max_minutiae;
    int min_computable_minutiae;
    BozorthSort *sorter;
}

@end


@implementation BozorthIO

- (id)init{
    self = [super init];
    
    if (self) {
        max_minutiae = 200;
        min_computable_minutiae = 10;
        sorter = [[BozorthSort alloc] init];
    }
    
    return self;
}

- (int)parseLineRange:(const char *)sb begin:(int *)begin end:(int *)end{
    int ib, ie;
    char * se;
    
    if ( ! isdigit(*sb) ) return -1;
    ib = atoi( sb );
    
    se = strchr( sb, '-' );
    if ( se != (char *) NULL ) {
        se++;
        if ( ! isdigit(*se) ) return -2;
        ie = atoi( se );
    } else {
        ie = ib;
    }
    
    if ( ib <= 0 ) {
        if ( ie <= 0 ) return -3;
        else return -4;
    }
    
    if ( ie <= 0 )  return -5;
    if ( ib > ie )  return -6;
    
    *begin = ib;
    *end   = ie;
    
    return 0;
}

- (void)setProgname:(int)usePid basename:(char *)basename pid:(pid_t)pid{
    if ( usePid )   sprintf( program_buffer, "%s pid %ld", basename, (long) pid );
    else            sprintf( program_buffer, "%s", basename );
}

- (void)setProbeFilename:(char *)filename{
    pfile = filename;
}

- (void)setGalleryFilename:(char *)filename{
    gfile = filename;
}

- (char *)getProgname{
    return program_buffer;
}

- (char *)getProbeFilename{
    return pfile;
}

- (char *)getGalleryFilename{
    return gfile;
}

- (char *)getNextFile:(char *)fixed_file
               listFP:(FILE *)list_fp
              matesFP:(FILE *)mates_fp
              doneNow:(int *)done_now
       doneAfterwards:(int *)done_afterwards
                 line:(char *)line
                 argc:(int)argc
                 argv:(char **)argv
               optind:(int *)optind
               lineno:(int *)lineno
                begin:(int)begin
                  end:(int)end{
    char * p;
    FILE * fp;
    
    if ( fixed_file != (char *) NULL ) {
        return fixed_file;
    }
    
    fp = list_fp;
    if ( fp == (FILE *) NULL ) fp = mates_fp;
    if ( fp != (FILE *) NULL ) {
        while (1) {
            if ( fgets( line, MAX_LINE_LENGTH, fp ) == (char *) NULL ) {
                *done_now = 1;
                return (char *) NULL;
            }
            ++*lineno;
            
            if ( begin <= 0 )         /* no line number range was specified */
                break;
            if ( *lineno > end ) {
                *done_now = 1;
                return (char *) NULL;
            }
            if ( *lineno >= begin ) {
                break;
            }
            /* Otherwise ( *lineno < begin ) so read another line */
        }
        
        p = strchr( line, '\n' );
        if ( p == (char *) NULL ) {
            *done_now = 1;
            return (char *) NULL;
        }
        *p = '\0';
        
        p = line;
        return p;
    }
    
    
    p = argv[*optind];
    ++*optind;
    if ( *optind >= argc )
        *done_afterwards = 1;
    return p;
}

- (char *)getScoreFilename:(const char *)outdir listFile:(const char *)listfile{
    const char * basename;
    int baselen;
    int dirlen;
//    int extlen;
    char * outfile;
        
    basename = strrchr( listfile, '/' );
    if ( basename == CNULL ) {
        basename = listfile;
    } else {
        ++basename;
    }
    baselen = strlen( basename );
    if ( baselen == 0 ) {
        return(CNULL);
    }
    dirlen = strlen( outdir );
    if ( dirlen == 0 ) {
        return(CNULL);
    }
    
//    extlen = strlen( SCOREFILE_EXTENSION );
    outfile = 0;
    if ( outfile == CNULL)
        return(CNULL);
    
    sprintf( outfile, "%s/%s%s", outdir, basename, SCOREFILE_EXTENSION );
    
    return outfile;
}

- (char *)getScoreLine:(const char *)probe_file
           galleryFile:(const char *)gallery_file
                     n:(int)n
            staticFlag:(int)static_flag
                   fmt:(const char *)fmt{
    int nchars;
    char * bufptr;
    static char linebuf[1024];
    static_flag = 0;
    nchars = 0;
    bufptr = &linebuf[0];
    while ( *fmt ) {
        if ( nchars++ > 0 )
            *bufptr++ = ' ';
        switch ( *fmt++ ) {
            case 's':
                sprintf( bufptr, "%d", n );
                break;
            case 'p':
                sprintf( bufptr, "%s", probe_file );
                break;
            case 'g':
                sprintf( bufptr, "%s", gallery_file );
                break;
            default:
                return (char *) NULL;
        }
        bufptr = strchr( bufptr, '\0' );
    }
    *bufptr++ = '\n';
    *bufptr   = '\0';
    
    return static_flag ? &linebuf[0] : strdup(linebuf);
}

- (int)fdReadable:(int)fd{
    int retval;
    fd_set rfds;
    struct timeval tv;
    
    
    FD_ZERO( &rfds );
    FD_SET( fd, &rfds );
    tv.tv_sec = 0;
    tv.tv_usec = 0;
    
    retval = select( fd+1, &rfds, NULL, NULL, &tv );
    
    if ( retval < 0 ) {
        perror( "select() failed" );
        return 0;
    }
    
    if ( FD_ISSET( fd, &rfds ) ) {
        return 1;
    }
    
    return 0;
}

- (struct xyt_struct *)load:(NSString *)templatePath{
    if (!templatePath) return NULL;
    const char *xyt_file = [templatePath UTF8String];
    int nminutiae;
    int m;
    int i;
    int nargs_expected;
    FILE * fp;
    struct xyt_struct * xyt_s;
    struct xytq_struct * xytq_s;
    int xvals_lng[MAX_FILE_MINUTIAE],
    yvals_lng[MAX_FILE_MINUTIAE],
    tvals_lng[MAX_FILE_MINUTIAE],
    qvals_lng[MAX_FILE_MINUTIAE];
    char xyt_line[ MAX_LINE_LENGTH ];
    
    NSString *fileName = [NSString stringWithCString:xyt_file encoding:NSUTF8StringEncoding];
        
    fp = fopen( xyt_file, "r" );
    if ( fp == (FILE *) NULL )
    {
        NSLog(@"Failed opening minutiae file: %@", fileName);
        return XYT_NULL;
    }
    
    nminutiae = 0;
    nargs_expected = 0;
    
    while ( fgets( xyt_line, sizeof xyt_line, fp ) != CNULL )
    {
        m = sscanf( xyt_line, "%d %d %d %d",
                   &xvals_lng[nminutiae],
                   &yvals_lng[nminutiae],
                   &tvals_lng[nminutiae],
                   &qvals_lng[nminutiae] );
        
        if ( nminutiae == 0 )
        {
            if ( m != 3 && m != 4 )
            {
                NSLog(@"Failed scanning %@ on line %i", fileName, nminutiae + 1);
                return XYT_NULL;
            }
            nargs_expected = m;
        }
        else
        {
            if ( m != nargs_expected )
            {
                NSLog(@"Inconsistent argument count on line %i on minutiae file %@", nminutiae + 1, fileName);
                return XYT_NULL;
            }
        }
        if ( m == 3 )
            qvals_lng[nminutiae] = 1;
        
        ++nminutiae;
        if ( nminutiae == MAX_FILE_MINUTIAE )
            break;
    }
    
    if ( fclose(fp) != 0 )
    {
        NSLog(@"Error closing minutiae file %@", fileName);
        return XYT_NULL;
    }
    
    xytq_s = (struct xytq_struct *)malloc(sizeof(struct xytq_struct));
    if ( xytq_s == XYTQ_NULL )
    {
        NSLog(@"Error malloc() failure while loading minutiae buffer on %@", fileName);
        return XYT_NULL;
    }
    
    xytq_s->nrows = nminutiae;
    for (i=0; i<nminutiae; i++)
    {
        xytq_s->xcol[i] = xvals_lng[i];
        xytq_s->ycol[i] = yvals_lng[i];
        xytq_s->thetacol[i] = tvals_lng[i];
        xytq_s->qualitycol[i] = qvals_lng[i];
    }
    
    xyt_s = [self prune:xytq_s];
    free(xytq_s);
    
    if (self.verbose) NSLog(@"Loaded %@", fileName);
    
    return xyt_s;
}

#define C1 0
#define C2 1

- (struct xyt_struct *)prune:(struct xytq_struct *)xytq_s{
    int nminutiae;
    int j;
    struct xyt_struct * xyt_s;
    int * xptr;
    int * yptr;
    int * tptr;
    int * qptr;
    struct minutiae_struct c[MAX_FILE_MINUTIAE];
    int xvals_lng[MAX_FILE_MINUTIAE],
    yvals_lng[MAX_FILE_MINUTIAE],
    tvals_lng[MAX_FILE_MINUTIAE],
    qvals_lng[MAX_FILE_MINUTIAE];
    int order[MAX_FILE_MINUTIAE];
    int xvals[MAX_BOZORTH_MINUTIAE],
    yvals[MAX_BOZORTH_MINUTIAE],
    tvals[MAX_BOZORTH_MINUTIAE],
    qvals[MAX_BOZORTH_MINUTIAE];
    
    int i;
    nminutiae = xytq_s->nrows;
    for (i=0; i<nminutiae; i++)
    {
        xvals_lng[i] = xytq_s->xcol[i];
        yvals_lng[i] = xytq_s->ycol[i];
        
        if ( xytq_s->thetacol[i] > 180 )
            tvals_lng[i] = xytq_s->thetacol[i] - 360;
        else
            tvals_lng[i] = xytq_s->thetacol[i];
        
        qvals_lng[i] = xytq_s->qualitycol[i];
    }
    
    if ( nminutiae > max_minutiae )
    {
        //this code needs review
        if ([sorter sortOrderDecreasing:qvals_lng num:nminutiae order:order]) {
            return XYT_NULL;
        }
        
        for ( j = 0; j < nminutiae; j++ )
        {   
            if ( j == 0 )
                continue;
            if ( qvals_lng[order[j]] > qvals_lng[order[j-1]] ) {
                return XYT_NULL;
            }
        }
        
        
        for ( j = 0; j < max_minutiae; j++ )
        {
            xvals[j] = xvals_lng[order[j]];
            yvals[j] = yvals_lng[order[j]];
            tvals[j] = tvals_lng[order[j]];
            qvals[j] = qvals_lng[order[j]];
        }
        
        
        if ( C1 )
        {
            qsort( (void *) &c, (size_t) nminutiae, sizeof(struct minutiae_struct), sort_quality_decreasing );
            for ( j = 0; j < nminutiae; j++ )
            {
                if ( j > 0 && c[j].col[3] > c[j-1].col[3] )
                {
                    NSLog( @"ERROR: sort failed: c[%d].col[3] > c[%d].col[3]\n", j, j-1 );
                    return XYT_NULL;
                }
            }
        }
        
        xptr = xvals;
        yptr = yvals;
        tptr = tvals;
        qptr = qvals;
        
        nminutiae = max_minutiae;
    }
    else
    {
        xptr = xvals_lng;
        yptr = yvals_lng;
        tptr = tvals_lng;
        qptr = qvals_lng;
    }
    
    
    for ( j=0; j < nminutiae; j++ )
    {
        c[j].col[0] = xptr[j];
        c[j].col[1] = yptr[j];
        c[j].col[2] = tptr[j];
        c[j].col[3] = qptr[j];
    }
    qsort( (void *) &c, (size_t) nminutiae, sizeof(struct minutiae_struct), sort_x_y );
    
    xyt_s = (struct xyt_struct *) malloc( sizeof( struct xyt_struct ) );
    if ( xyt_s == XYT_NULL ) 
    {
        NSLog( @"ERROR: malloc() failure while xyt_struct.");
        return XYT_NULL;
    }
    
    for ( j = 0; j < nminutiae; j++ ) 
    {
        xyt_s->xcol[j]     = c[j].col[0];
        xyt_s->ycol[j]     = c[j].col[1];
        xyt_s->thetacol[j] = c[j].col[2];
    }
    xyt_s->nrows = nminutiae;
    
    return xyt_s;
}

int sort_quality_decreasing( const void * a, const void * b ){
    struct minutiae_struct * af;
    struct minutiae_struct * bf;
    
    af = (struct minutiae_struct *) a;
    bf = (struct minutiae_struct *) b;
    
    if ( af->col[3] > bf->col[3] )
        return -1;
    if ( af->col[3] < bf->col[3] )
        return 1;
    return 0;
}

int sort_x_y( const void * a, const void * b ){
    struct minutiae_struct * af;
    struct minutiae_struct * bf;
    
    af = (struct minutiae_struct *) a;
    bf = (struct minutiae_struct *) b;
    
    if ( af->col[0] < bf->col[0] )
        return -1;
    if ( af->col[0] > bf->col[0] )
        return 1;
    
    if ( af->col[1] < bf->col[1] )
        return -1;
    if ( af->col[1] > bf->col[1] )
        return 1;
    
    return 0;
}

@end
