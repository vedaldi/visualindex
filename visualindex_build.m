function model = visualindex_build(images, varargin)
% VISUALINDEX_BUILD  Initialize a visual index from a set of images
%   MODEL = VISUALDINDEX_BUILD(IMAGES) builds an index using the
%   specified list of images to construct the visual word vocabulary
%   and compuring the TF-IDF weights.
%
%   VISUALINDEX_BUILD(..., 'numWords', K, 'maxNumKMeansIterations', T)
%   allows specifying the number of visual words and K-means
%   iterations used to build the visual words vocabulary.
%
%   MODEL is a structure with the following fields
%
%   model.vocab.size:
%      Size of the visual vocabulary (number of visual wrods).
%
%   model.vocab.centers:
%      Visual words (quantized SIFT features).
%
%   model.vocab.tree:
%      KD-Tree index of the visual words (see VL_KDTREEBUILD()).
%
%   model.vocab.weights:
%      TF-IDF weights of the visual words.
%
%   model.index.frames:
%   model.index.words:
%      Cell array of frames (keypoints) and quantized descriptors of
%      the SIFT features of each image.
%
%   model.index.histograms
%      Cell array of histogram of visual words for each image.

% Author: Andrea Vedaldi

opts.numWords = 1e4 ;
opts.maxNumKMeansIterations = 20 ;
opts = vl_argparse(opts, varargin) ;

randn('state',0) ;
rand('state',0) ;

model.rerankDepth = 40 ;
model.vocab.size = opts.numWords ;
model.vocab.centers = [] ;
model.vocab.tree = struct ;
model.vocab.weights = ones(opts.numWords,1) ;
model.index = struct('ids',[],'frames',[],'words',[],'histograms',[]) ;

%% Sample descriptors from example images
num = opts.numWords * 10 ;
numPerImage = ceil(num / length(images)) ;
descrs = cell(1, length(images)) ;
parfor i = 1:length(images)
  fprintf('%s: extracting features from %s (%d of %d)\n', ...
          mfilename, images{i}, i, numel(images)) ;
  im = imread(images{i}) ;
  [drop, descrs{i}] = visualindex_get_features(model, im) ;
  descrs{i} = vl_colsubset(descrs{i}, numPerImage, 'uniform') ;
end
descrs = cat(2, descrs{:}) ;

%% Run ANN k-means to construct the visual word vocabulary
vl_twister('state',0) ;
model.vocab.centers = vl_kmeans(descrs, opts.numWords, ...
                                'verbose', ...
                                'algorithm', 'ann', ...
                                'maxNumIterations', opts.maxNumKMeansIterations)  ;
model.vocab.tree = vl_kdtreebuild(model.vocab.centers) ;
