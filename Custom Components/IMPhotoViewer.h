//
//  IMPhotoViewer.h
//  IMDB Mobile
//
//  Created by Mario Yohanes on 5/6/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMViewController.h"

@interface IMPhotoViewer : IMViewController<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate>

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;

@property (nonatomic, strong) NSArray *photoPaths;

@end