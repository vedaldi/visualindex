function [f,d] = visualindex_get_features(model, im)
% VISUALINDEX_GET_FEATURES  Extract features from an image
%   [F,D] = VISUALINDEX_GET_FEATURES(MODEL, IM) extracts the SIFT
%   frames F and descriptors D from image IM for indexing based on the
%   specified MODEL.

% Author: Andrea Vedaldi

if size(im,3) > 1
  im = rgb2gray(im) ;
end
if ~isa(im,'single')
  im = im2single(im) ;
end

[f,d] = vl_covdet(...
  im, ...
  'DoubleImage', true, ...
  'EstimateAffineShape', true, ...
  'PatchRelativeExtent', 10, ...
  'PatchRelativeSmoothing', 1, ...
  'Method', 'DoG') ;

if model.rootSift
  d = sqrt(d) ;
  d = bsxfun(@times, d, 1./max(1e-12, sqrt(sum(d.^2)))) ;
end
