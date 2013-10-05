function [ids, scores, matches, H, frames] = visualindex_query(model, im, varargin)
% VISUALINDEX_QUERY  Search index for matching images
%   [IDS, SCORES, MATCHES] = VISUALINDEX_QUERY(MODEL, IM) searches the
%   index MODEL for images matching the query image IM. It returns
%   a list of imge IDS and SCORES by descending confidence.
%
%   The function first matches images based on the visual words
%   histograms and then geometrically verifies the top
%   MODEL.RERANKDEPTH results, reranking those.  The function also
%   returns MATCHES, an array of structures with the geometric
%   verification `certificates' for these top matches.

% Author: Andrea Vedaldi

opts.box = [] ;
opts = vl_argparse(opts, varargin) ;

% reranking depth cannot be larger than the number of indexed images
depth = min(model.rerankDepth, numel(model.index.ids)) ;

% extract the features, visual words, and histogram for the query images
[frames, descrs] = visualindex_get_features(model, im) ;
words = visualindex_get_words(model, descrs) ;

% cropb box if any
if ~isempty(opts.box)
  ok = frames(1,:) >= opts.box(1) & ...
       frames(1,:) <= opts.box(3) & ...
       frames(2,:) >= opts.box(2) & ...
       frames(2,:) <= opts.box(4) ;
  frames = frames(:, ok) ;
  words = words(ok) ;
end

% get histogram
histogram = visualindex_get_histogram(model, words) ;

% compute histogram-based score
scores = histogram' * model.index.histograms ;

% update top scores using geometric verification
[scores, perm] = sort(scores, 'descend') ;
ids = model.index.ids(perm) ;

H = cell(1,depth) ;
matches = cell(1,depth) ;
words2 = model.index.words(perm(1:depth)) ;
frames2 = model.index.frames(perm(1:depth)) ;

parfor t = 1:depth
  % find the features that are mapped to the same visual words
  [drop,m1,m2] = intersect(words,words2{t}) ;
  matches{t} = [m1(:)';m2(:)'] ;

  %im2=imread(model.index.names{perm(t)});
  %figure(101) ; clf ; plotMatches(im,im2,frames,frames2,matches{t}) ;

  [inliers, H{t}] = geometricVerification2(frames, frames2{t}, matches{t}) ;

  if numel(inliers) >= 6
    scores(t) = scores(t) + numel(inliers) ;
  end
  matches{t} = matches{t}(:, inliers) ;
end

% rerank
[scores(1:depth), perm] = sort(scores(1:depth), 'descend') ;
ids(1:depth) = ids(perm) ;
matches = matches(perm) ;
H = H(perm) ;
