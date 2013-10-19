function [inliers, H] = geometricVerification(f1, f2, matches, varargin)
% GEOMETRICVERIFICATION  Verify feature matches based on geometry
%   [INLIERS, H] = GEOMETRICVERIFICATION(F1, F2, MATCHES) checks for
%   geometric consistency the matches MATCHES between feature frames
%   F1 and F2 (see PLOTMATCHES() for the format of these
%   parameters). INLIERS is a list of indexes of matches that are
%   inliers to the geometric model. H is the homography matrix of the
%   estimated transformation.

% Author: Andrea Vedaldi

  opts.tolerance1 = 35 ;
  opts.tolerance2 = 30 ;
  opts.tolerance3 = 25 ;
  opts = vl_argparse(opts, varargin) ;

  numMatches = size(matches,2) ;
  inliers = cell(1, numMatches) ;
  H = cell(1, numMatches) ;

  x1 = double(f1(1:2, matches(1,:))) ;
  x2 = double(f2(1:2, matches(2,:))) ;

  x1hom = x1 ;
  x2hom = x2 ;
  x1hom(end+1,:) = 1 ;
  x2hom(end+1,:) = 1 ;

  % bad set of candidate inliers will produce a bad model, but
  % this will be discared
  warning('off','MATLAB:rankDeficientMatrix') ;

  f1e = vl_frame2oell(f1(:,matches(1,:))) ;
  f2e = vl_frame2oell(f2(:,matches(2,:))) ;

  scores = zeros(1,numMatches) ;
  inliers = cell(1,numMatches) ;
  H21 = cell(1,numMatches) ;
  A1 = eye(3) ;
  A2 = eye(3) ;
  for m = 1:numMatches
    A1([7 8 1 2 4 5]) = f1e(:,m) ;
    A2([7 8 1 2 4 5]) = f2e(:,m) ;
    H21{m} = A2 / A1 ;
    x1p = H21{m}(1:2,:) * x1hom ;
    dist2 = sum((x2 - x1p).^2,1) ;
    inliers{m} = find(dist2 < opts.tolerance1^2) ;
    scores(m) = numel(inliers{m}) ;
  end

  % affinity
  [score,m] = max(scores) ;
  inliers = inliers{m} ;
  H21 = H21{m} ;

  if numel(inliers) > 8
    H21 = x2(:,inliers) / x1hom(:,inliers) ;
    x1p = H21(1:2,:) * x1hom ;
    H21(3,:) = [0 0 1] ;
    dist2 = sum((x2 - x1p).^2,1) ;
    inliers = find(dist2 < opts.tolerance2^2) ;
  end

  % homography
  for t = 1:1
    if numel(inliers) < 10, break ; end
    if t == 1
        S1 = centering(x1hom) ;
        S2 = centering(x2hom) ;
        x1c = S1 * x1hom ;
        x2c = S2 * x2hom ;
    end
    x1cin = x1c(:,inliers) ;
    x2cin = x2c(:,inliers) ;

    M = [x1cin, zeros(size(x1cin)) ;
      zeros(size(x1cin)), x1cin ;
      bsxfun(@times, x1cin,  -x2cin(1,:)), bsxfun(@times, x1cin,  -x2cin(2,:))] ;
    [H21,D] = svd(M,'econ') ;
    H21 = reshape(H21(:,end),3,3)' ;
    H21 = inv(S2) * H21 * S1 ;
    H21 = H21 ./ H21(end) ;

    x1phom = H21 * x1hom ;
    x1p = [x1phom(1,:) ./ x1phom(3,:) ; x1phom(2,:) ./ x1phom(3,:)] ;

    dist2 = sum((x2 - x1p).^2,1) ;
    inliers = find(dist2 < opts.tolerance3^2) ;
  end

  if numel(inliers) > 8
    H = inv(H21 + 1e-8 * eye(3)) ;
  end
end

% --------------------------------------------------------------------
function C = centering(x)
% --------------------------------------------------------------------
  mu = mean(x(1:2,:),2) ;
  T = [eye(2), - mu ; 0 0 1] ;
  x = T * x ;
  sigma = sqrt(mean(x(1:2,:).^2,2)) ;

  % at least one pixel apart to avoid numerical problems
  sigma = max(sigma,1) ;

  S = [1/sigma(1) 0 0 ;
       0 1/sigma(2) 0 ;
       0 0          1] ;
  C = S * T ;
end
