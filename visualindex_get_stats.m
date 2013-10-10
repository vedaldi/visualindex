function stats = visualindex_get_stats(model)
% VISUALINDEX_GET_STATS

info = whos('model') ;
nw = sum(model.index.histograms > 0) ;

stats.size = info.bytes ;
stats.numWordsPerImage = full(nw) ;
stats.numImages = numel(model.index.ids) ;

if nargout == 0
  fprintf('%s: size: %.2f GB\n', mfilename, stats.size / 1024^3) ;
  fprintf('%s: avg. num. words per image: %.1f (%.1f %% dense)\n', mfilename, ...
    mean(stats.numWordsPerImage), mean(stats.numWordsPerImage) / model.vocab.size * 100) ;
  fprintf('%s: min, max, std, num. words per image: %.1f, %.1f, %.1f\n', mfilename, ...
    min(stats.numWordsPerImage), max(stats.numWordsPerImage), std(stats.numWordsPerImage)) ;
  fprintf('%s: num. images: %d\n', mfilename, stats.numImages) ;
end

  