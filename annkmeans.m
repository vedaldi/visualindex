function [centers, tree, en] = annkmeans(X, K, varargin)
% ANNKMEANS  Approximate Nearest Neighbors K-Means
%
%   Example:: To cluster the data X into K parts:
%     [CENTERS, EN] = ANNKMEANS(X, K) ;
%
%   Options are:
%
%   Seed:: 0
%     Random number generation seed (for initialization).
%
%   NumTrees:: 3
%     Number of trees in the kd-tree forest.
%
%   MaxNumComparisons:: 500
%     Maximum number of comparisons when querying the kd-tree.
%
%   MaxNumIterations:: 100
%     Maximum number of k-means iterations.

% Andrea Vedaldi

opts.seed = 0 ;
opts.numTrees = 3 ;
opts.maxNumComparisons = 500 ;
opts.maxNumIterations = 100 ;
opts.verbose = 0 ;
opts = vl_argparse(opts, varargin) ;

% get initial centers
rand('state',opts.seed) ;
centers = vl_colsubset(X, K) ;

if opts.verbose
  fprintf('%s: clustering %d vectors into %d parts\n', ...
          mfilename, size(X,2), K) ;
  fprintf('%s: maxNumComparisons = %d\n', mfilename, opts.maxNumComparisons) ;
  fprintf('%s: maxNumIterations = %d\n', mfilename, opts.maxNumIterations) ;
end

% chunk the data up
numData = size(X,2) ;
numChunks = max(matlabpool('size'), 1) ;
data = Composite() ;
dist = Composite() ;
assign = Composite() ;

for i = 1:numChunks
  chunk = i:numChunks:numData ;
  data{i} = X(:, chunk) ;
  dist{i} = inf(1, numel(chunk), class(X)) ;
  assign{i} = zeros(1, numel(chunk)) ;
end
%clear X ;

E = [] ;

for t = 1:opts.maxNumIterations
  % compute kd-tree
  tree = vl_kdtreebuild(centers, 'numTrees', opts.numTrees) ;

  % get the updated cluster assignments and partial centers
  spmd
    [centers_, mass_, en_, assign, dist] = update(opts, ...
                                                  data,K,centers,tree,...
                                                  assign,dist) ;
  end

  % compute the new cluster centers
  centers = zeros(size(centers),class(centers)) ;
  mass = zeros(1,K);
  en = 0 ;
  for i = 1:length(centers_)
    centers = centers + centers_{i} ;
    mass = mass + mass_{i} ;
    en = en + en_{i} ;
  end
  centers = bsxfun(@times, centers, 1./max(mass,eps)) ;
  E(t) = en ;

  % re-initialize any center with no mass
  rei = find(mass == 0) ;
  centers(:, rei) = vl_colsubset(X, length(rei)) ;

  if opts.verbose
    figure(1) ; clf ;
    plot(E,'linewidth', 2) ;
    xlim([1 opts.maxNumIterations]) ;
    title(sprintf('%s: iteration %d', mfilename, t)) ;
    xlabel('iterations') ;
    ylabel('energy') ;
    grid on ; drawnow ;
    fprintf('%s: %d: energy = %g, reinitialized = %d\n', mfilename,t,E(t),length(rei)) ;
  end

  if t > 1 && E(t) > 0.999 * E(t-1), break ; end
end

% prepare final resutls
en = E(end) ;

% --------------------------------------------------------------------
function [centers, mass, en, assign, dist] = ...
      update(opts,X,K,centers,tree,assign,dist)
% --------------------------------------------------------------------

[assign_, dist_] = vl_kdtreequery(tree, centers, X, ...
                                  'maxComparisons', opts.maxNumComparisons) ;
ok = dist_ < dist ;
assign(ok) = assign_(ok) ;
dist(ok) = dist_(ok) ;

for b = 1:K
  centers(:, b) = sum(X(:, assign == b),2) ;
  mass(b) = sum(assign == b) ;
end
en = sum(dist) ;
