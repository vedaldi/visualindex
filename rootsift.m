function d=rootsift(d)
d = sqrt(d) ;
d = bsxfun(@times, d, 1./sqrt(sum(d.^2))) ;
