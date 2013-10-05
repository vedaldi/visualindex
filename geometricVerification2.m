function [inliers, H] = geometricVerification2(f1, f2, matches, varargin)
% GEOMETRICVERIFICATION  Verify feature matches based on geometry
%   OK = GEOMETRICVERIFICATION(F1, F2, MATCHES) check for geometric
%   consistency the matches MATCHES between feature frames F1 and F2
%   (see PLOTMATCHES() for the format). INLIERS is a list of indexes
%   of matches that are inliers to the geometric model.

% Author: Andrea Vedaldi

  opts.tolerance1 = 20 ;
  opts.tolerance2 = 15 ;
  opts.tolerance3 = 8 ;
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

  scores = zeros(1,numMatches) ;
  inliers = cell(1,numMatches) ;
  for m = 1:numMatches
    A1 = toAffinity(f1(:,matches(1,m))) ;
    A2 = toAffinity(f2(:,matches(2,m))) ;
    H21 = A2 * inv(A1) ;
    x1p = H21(1:2,:) * x1hom ;
    dist2 = sum((x2 - x1p).^2,1) ;
    inliers{m} = find(dist2 < opts.tolerance1^2) ;
    scores(m) = numel(inliers{m}) ;
  end

  % affinity
  [score,m] = max(scores) ;
  inliers = inliers{m} ;

  if numel(inliers) > 8
    H21 = x2(:,inliers) / x1hom(:,inliers) ;
    x1p = H21(1:2,:) * x1hom ;
    H21(3,:) = [0 0 1] ;
    dist2 = sum((x2 - x1p).^2,1) ;
    inliers = find(dist2 < opts.tolerance2^2) ;
  end

  for t = 1:2
    if numel(inliers) < 10, break ; end
    % homography
    x1in = x1hom(:,inliers) ;
    x2in = x2hom(:,inliers) ;

    S1 = centering(x1in) ;
    S2 = centering(x2in) ;
    x1c = S1 * x1in ;
    x2c = S2 * x2in ;

    M = [x1c, zeros(size(x1c)) ;
      zeros(size(x1c)), x1c ;
      bsxfun(@times, x1c,  -x2c(1,:)), bsxfun(@times, x1c,  -x2c(2,:))] ;
    [H21,D] = svd(M,'econ') ;
    H21 = reshape(H21(:,end),3,3)' ;
    H21 = inv(S2) * H21 * S1 ;
    H21 = H21 ./ H21(end) ;

    x1phom = H21 * x1hom ;
    x1p = [x1phom(1,:) ./ x1phom(3,:) ; x1phom(2,:) ./ x1phom(3,:)] ;

    dist2 = sum((x2 - x1p).^2,1) ;
    inliers = find(dist2 < opts.tolerance3^2) ;
  end

  H = inv(H21) ;
end

% --------------------------------------------------------------------
function C = centering(x)
% --------------------------------------------------------------------
  T = [eye(2), - mean(x(1:2,:),2) ; 0 0 1] ;
  x = T * x ;
  std1 = std(x(1,:)) ;
  std2 = std(x(2,:)) ;

  % at least one pixel apart to avoid numerical problems
  std1 = max(std1, 1) ;
  std2 = max(std2, 1) ;

  S = [1/std1 0 0 ;
       0 1/std2 0 ;
       0 0      1] ;
  C = S * T ;
end

% --------------------------------------------------------------------
function A = toAffinity(f)
% --------------------------------------------------------------------
  switch size(f,1)
    case 3 % discs
      T = f(1:2) ;
      s = f(3) ;
      th = 0 ;
      A = [s*[cos(th) -sin(th) ; sin(th) cos(th)], T ; 0 0 1] ;
    case 4 % oriented discs
      T = f(1:2) ;
      s = f(3) ;
      th = f(4) ;
      A = [s*[cos(th) -sin(th) ; sin(th) cos(th)], T ; 0 0 1] ;
    case 5 % ellipses
      T = f(1:2) ;
      A = [mapFromS(f(3:5)), T ; 0 0 1] ;
    case 6 % oriented ellipses
      T = f(1:2) ;
      A = [f(3:4), f(5:6), T ; 0 0 1] ;
    otherwise
      assert(false) ;
  end
end

% --------------------------------------------------------------------
function A = mapFromS(S)
% --------------------------------------------------------------------
% Returns the (stacking of the) 2x2 matrix A that maps the unit circle
% into the ellipses satisfying the equation x' inv(S) x = 1. Here S
% is a stacked covariance matrix, with elements S11, S12 and S22.

  tmp = sqrt(S(3,:)) + eps ;
  A(1,1) = sqrt(S(1,:).*S(3,:) - S(2,:).^2) ./ tmp ;
  A(2,1) = zeros(1,length(tmp));
  A(1,2) = S(2,:) ./ tmp ;
  A(2,2) = tmp ;
end