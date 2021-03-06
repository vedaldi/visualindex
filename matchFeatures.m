function [matches, H] = matchFeatures(f1,d1,f2,d2,varargin)
% MATCHFEATURES  Match two sets of features
%  [INLIERS, H] = MATCHFEATURES(F1,D1,F2,D2) matches feature frames
%  F1 and F2 with descriptors D1 and D2 using first the descriptor
%  appearance, and then geometric verification.

opts.exact = false ;
opts.innerProduct = false;
opts = vl_argparse(opts, varargin) ;

n1 = size(f1,2) ;
n2 = size(f2,2) ;

if n2 >= 1

  if opts.innerProduct
    [score, best] = max(d2'*d1) ;
  else
    if ~opts.exact
      % use a KD-tree to find nearest neighbours
      tree = vl_kdtreebuild(d2,'numTrees',3) ;
      [best, dist2] = vl_kdtreequery(tree,d2,d1,'maxNumComparisons',512) ;
    else
      [dist2, best] = min(vl_alldist2(d2, d1),[],1) ;
    end
  end
  matches = [1:n1 ; best] ;

  % discard matches that converge too many times to the same point
  arity = vl_binsum(zeros(1,n2), 1, matches(2,:)) ;
  ok = ismember(matches(2,:), find(arity <= 2)) ;
  matches = matches(:,ok) ;

  if size(matches,2) <= 4
    H = zeros(3) ;
    return ;
  end

  % do geometric verification
  [inliers, H] = geometricVerification(f1,f2,matches) ;
  matches = matches(:, inliers) ;
else
  matches = zeros(2,0) ;
  H = zeros(3) ;
end


