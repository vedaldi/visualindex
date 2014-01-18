function d=normal(d)
d = bsxfun(@times, d, 1./sqrt(sum(d.^2))) ;