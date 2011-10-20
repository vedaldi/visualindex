function model = visualindex_build(images, ids, varargin)
% VISUALINDEX_BUILD  Build an index for a set of images
%   MODEL = VISUALDINDEX_BUILD(IMAGES, IDS) indexes the specified
%   IMAGES associating to them the given IDS. IMAGES is a cell array
%   of strings containitn path to the images and IDS are unique
%   numeric identifiers (in DOUBLE class).
%
%   VISUALINDEX_BUILD(..., 'numWords', K, 'numKMeansIterations', T)
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
%   model.index.frames
%   model.index.descrs
%   model.index.words
%      Cell array of frames (keypoints), descriptors, and visual words
%      of the SIFT features of each image.
%
%   model.index.histograms
%      Cell array of histogram of visual words for each image.

% Author: Andrea Vedaldi

opts.numWords = 10000 ;
opts.numKMeansIterations = 20 ;
opts = vl_argparse(opts, varargin) ;

randn('state',0) ;
rand('state',0) ;

model.rerankDepth = 40 ;
model.vocab.size = opts.numWords ;
model.index = struct ;

% --------------------------------------------------------------------
%                                              Extract visual features
% --------------------------------------------------------------------
% Extract SIFT features from each image.

% read features
f = {} ; d = {} ;
for i = 1:length(images)
  fprintf('Adding image %s (%d of %d)\n', ...
          images{i}, i, numel(images)) ;
  im = readimage(images{i}) ;
  [model.index.frames{i}, ...
   model.index.descrs{i}] = visualindex_get_features(model, im) ;
end
model.index.ids = ids ;

% --------------------------------------------------------------------
%                                                  Large scale k-means
% --------------------------------------------------------------------
% Quantize the SIFT features to obtain a visual word vocabulary.
% Implement a fast approximate version of K-means by using KD-Trees
% for quantization.

E = [] ;
assign = []  ;
descrs = vl_colsubset(cat(2,model.index.descrs{:}), opts.numWords * 15) ;
dist = inf(1, size(descrs,2)) ;

model.vocab.centers = vl_colsubset(descrs, opts.numWords) ;

for t = 1:opts.numKMeansIterations
  % large scale k - means
  model.vocab.tree = vl_kdtreebuild(model.vocab.centers, 'numTrees', 3) ;
  [assign_, dist_] = visualindex_get_words(model, descrs) ;
  ok = dist_ < dist ;
  assign(ok) = assign_(ok) ;
  dist(ok) = dist_(ok) ;
  E(t) = mean(dist) ;

  for b = 1:model.vocab.size
    model.vocab.centers(:, b) = mean(descrs(:, assign == b),2) ;
  end

  figure(1) ; clf ; plot(E,'linewidth', 2) ;
  title(sprintf('k-means energy (%d visual words, %d data points)', ...
                model.vocab.size, size(descrs,2))) ;
  xlim([1 opts.numKMeansIterations]) ; grid on ; drawnow ;

  if t > 3 && (E(t-2) - E(t)) < 1e-2 * E(t), break ; end
end

% --------------------------------------------------------------------
%                                                           Histograms
% --------------------------------------------------------------------
% Compute a visual word histogram for each image, compute TF-IDF
% weights, and then reweight the histograms.

for t = 1:length(model.index.ids)
  words = visualindex_get_words(model, model.index.descrs{t}) ;
  model.index.words{t} = words ;
  model.index.histograms{t} = sparse(double(words),1,...
                                     ones(length(words),1), ...
                                     model.vocab.size,1) ;
end
model.index.histograms = cat(2, model.index.histograms{:}) ;

% compute IDF weights
model.vocab.weights = log((size(model.index.histograms,2)+1) ...
                          ./  (max(sum(model.index.histograms > 0,2),eps))) ;

% weight and normalize histograms
for t = 1:length(model.index.ids)
  h = model.index.histograms(:,t) .*  model.vocab.weights ;
  model.index.histograms(:,t) = h / norm(h) ;
end
