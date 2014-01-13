//
//  BozorthSort.m
//  Bozorth3
//
//  Created by Mario Yohanes on 1/25/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "BozorthSort.h"


@interface BozorthSort(){
    int   stack[BZ_STACKSIZE];
    int * stack_pointer;
}

@end


@implementation BozorthSort

- (id)init{
    self = [super init];
    
    if (self) {
        stack_pointer = stack;
    }
    
    return self;
}


-(int)sortQualityDecreasing:(const void *)a pair:(const void *)b{
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

- (int)sortX:(const void *)a withY:(const void *)b{
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

- (int)popstack:(int *)popval{
    if ( --stack_pointer < stack ) return 1;
    *popval = *stack_pointer;
    return 0;
}

- (int)pushstack:(int)position{
    *stack_pointer++ = position;
    if ( stack_pointer > ( stack + BZ_STACKSIZE ) ) return 1;
    return 0;
}


- (int)selectPivot:(struct cell [])v left:(int)left right:(int)right{
    int midpoint;
    
    midpoint = ( left + right ) / 2;
    if ( v[left].index <= v[midpoint].index ) {
        if ( v[midpoint].index <= v[right].index ) {
            return midpoint;
        } else {
            if ( v[right].index > v[left].index ) {
                return right;
            } else {
                return left;
            }
        }
    } else {
        if ( v[left].index < v[right].index ) {
            return left;
        } else {
            if ( v[right].index < v[midpoint].index ) {
                return midpoint;
            } else {
                return right;
            }
        }
    }
}

#define iswap(a,b) { int itmp = (a); a = (b); b = itmp; }

- (void)partitionDec:(struct cell [])v llen:(int *)llen rlen:(int *)rlen ll:(int *)ll lr:(int *)lr rl:(int *)rl rr:(int *)rr p:(int)p l:(int)l r:(int)r{
    *ll = l;
    *rr = r;
    while ( 1 ) {
        if ( l < p ) {
            if ( v[l].index < v[p].index ) {
                iswap( v[l].index, v[p].index )
                iswap( v[l].item,  v[p].item )
                p = l;
            } else {
                l++;
            }
        } else {
            if ( r > p ) {
                if ( v[r].index > v[p].index ) {
                    iswap( v[r].index, v[p].index )
                    iswap( v[r].item,  v[p].item )
                    p = r;
                    l++;
                } else {
                    r--;
                }
            } else {
                *lr = p - 1;
                *rl = p + 1;
                *llen = *lr - *ll + 1;
                *rlen = *rr - *rl + 1;
                break;
            }
        }
    }
}

- (int)qsortDecreasing:(struct cell [])v left:(int)left right:(int)right{
    int pivot;
    int llen, rlen;
    int lleft, lright, rleft, rright;
    
    if ([self pushstack:left]) {
        return 1;
    }
    
    if ([self pushstack:right]) {
        return 2;
    }
    
    while ( stack_pointer != stack ) {
        if ([self popstack:&right])
            return 3;
        if ([self popstack:&left])
            return 4;
        if ( right - left > 0 ) {
            pivot = [self selectPivot:v left:left right:right];
            [self partitionDec:v llen:&llen rlen:&rlen ll:&lleft lr:&lright rl:&rleft rr:&rright p:pivot l:left r:right];
            if ( llen > rlen ) {
                if ( [self pushstack:lleft] )   return 5;
                if ( [self pushstack:lright] )  return 6;
                if ( [self pushstack:rleft] )   return 7;
                if ( [self pushstack:rright] )  return 8;
            } else{
                if ( [self pushstack:rleft] )   return 9;
                if ( [self pushstack:rright] )  return 10;
                if ( [self pushstack:lleft] )   return 11;
                if ( [self pushstack:lright] )  return 12;
            }
        }
    }
    
    return 0;
}

- (int)sortOrderDecreasing:(int [])values num:(int)num order:(int [])order{
    int i;
    struct cell * cells;
    
    
    cells = (struct cell *) malloc( num * sizeof(struct cell) );
    if ( cells == (struct cell *) NULL ){
        return 1;
    }
    
    for( i = 0; i < num; i++ ) {
        cells[i].index = values[i];
        cells[i].item  = i;
    }
    
    if ([self qsortDecreasing:cells left:0 right:num-1] < 0) return 2;
    
    for( i = 0; i < num; i++ ) {
        order[i] = cells[i].item;
    }
    
    free( (void *) cells );
    
    return 0;
}

@end
