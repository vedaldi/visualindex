function [ids, scores, matches] = visualindex_query(model, im)
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

% reranking depth cannot be larger than the number of indexed images
depth = min(model.rerankDepth, numel(model.index.ids)) ;

% extract the features, visual words, and histogram for the query images
[frames, descrs] = visualindex_get_features(model, im) ;
words = visualindex_get_words(model, descrs) ;
histogram = visualindex_get_histogram(model, words) ;

% compute histogram-based score
scores = histogram' * model.index.histograms ;

% apply geometric verification to the top matches
[scores, perm] = sort(scores, 'descend') ;
for t = 1:depth
  words0 = model.index.words{perm(t)} ;
  frames0 = model.index.frames{perm(t)} ;
  [scores(t), matches{t}] = verify(frames0, words0, ...
                                   frames, words, ...
                                   size(im)) ;
end
[scores(1:depth), reperm] = sort(scores(1:depth), 'descend') ;
matches = matches(reperm) ;
perm(1:depth) = perm(reperm) ;
ids = model.index.ids(perm) ;

% --------------------------------------------------------------------
function [score, matches] = verify(f1,w1,f2,w2,s2)
% --------------------------------------------------------------------
% The geometric verfication is a simple RANSAC affine matcher. It can
% be significantly improved.

[drop,m1,m2] = intersect(w1,w2) ;
numMatches = length(drop) ;

X1 = f1(1:2, m1) ;
X2 = f2(1:2, m2) ;
X1(3,:) = 1 ;
X2(3,:) = 1 ;

thresh = max(max(s2)*0.02, 10) ;

% RANSAC iterations
randn('state',0) ;
rand('state',0) ;
for t = 1:1000
  subset = vl_colsubset(1:numMatches, 3) ;
  u1 = X1(1:2,subset(3)) ;
  u2 = X2(1:2,subset(3)) ;
  A{t} = (X2(1:2,subset(1:2)) - [u2 u2]) / ...
         (X1(1:2,subset(1:2)) - [u1 u1]) ;
  T{t} = u2 - A{t} * u1 ;

  X2_ = [A{t} T{t} ; 0 0 1] * X1 ;
  delta = X2_ - X2 ;
  ok{t} = sum(delta.*delta,1) < thresh^2 ;
  score(t) = sum(ok{t}) ;
end

[score, best] = max(score) ;
matches.A = A{best} ;
matches.ok = ok{best} ;
matches.f1 = f1(:, m1(matches.ok)) ;
matches.f2 = f2(:, m2(matches.ok)) ;
