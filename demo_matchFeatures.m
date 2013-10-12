% DEMO_MATCHFEATURES  Demonstrates matching features between two images
%   Demonstrates how to use covariant features,
%   SIFT, a KD-tree, and geometric verification to match two images.

run vlfeat/toolbox/vl_setup ;

im1 = vl_impattern('river1') ;
im2 = vl_impattern('river2') ;
im1g = im2single(rgb2gray(im1)) ;
im2g = im2single(rgb2gray(im2)) ;

opts = {'Method', 'DoG', ...
        'DoubleImage', false} ;

[f1,d1] = vl_covdet(im1g, opts{:}) ;
[f2,d2] = vl_covdet(im2g, opts{:}) ;

[matches, H] = matchFeatures(f1,d1,f2,d2) ;

plotMatches(im1,im2,f1,f2,matches,'homography',H) ;
