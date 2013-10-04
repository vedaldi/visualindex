run vlfeat/toolbox/vl_setup ;

opts.lite = false ;
opts.imdbPath = 'data/imdb.mat' ;
opts.indexPath = 'data/index2.mat' ;
opts.emptyIndexPath = 'data/index-empty2.mat' ;
opts.resultPath = 'data/results2.mat' ;

% Get Oxford5k data
if exist(opts.imdbPath, 'file')
  load(opts.imdbPath, 'images', 'queries') ;
else
  [images, queries] = setupOxford5k('data/oxbuild_images', 'data/oxbuild_gt') ;
  if opts.lite
    queries = queries(2) ;
    queries.good = queries.good(1:2) ;
    queries.ok = queries.ok(1:2) ;
    queries.junk = queries.junk(1:2) ;
    ids = [queries.good, queries.ok, queries.junk] ;
    [~,sel] = ismember(ids, images.id) ;
    images.name = images.name(sel) ;
    images.id = images.id(sel) ;
  end
  save(opts.imdbPath, 'images', 'queries') ;
end

% Build the index
if exist(opts.emptyIndexPath, 'file')
  index = load(opts.emptyIndexPath) ;
else
  paths = cellfun(@(x) fullfile(images.dir, x), images.name, 'UniformOutput', false) ;
  index = visualindex_build(paths,'numWords', 1e5) ;
  save(opts.emptyIndexPath, '-STRUCT', 'index') ;
end

% Populate the index
if exist(opts.indexPath, 'file')
  index = load(opts.indexPath) ;
else  
  index = visualindex_add(index, paths, images.id) ;
  save(opts.indexPath, '-STRUCT', 'index') ;
end

% Evaluate queries
for q = 1:numel(queries)
  path = fullfile(images.dir, [queries(q).imageName '.jpg']) ;
  [ids, scores] = visualindex_query(index, imread(path)) ;
  labels = 2 * ismember(ids, [queries(q).good, queries(q).ok]) - 1 ;
  labels(ismember(ids, queries(q).junk)) = 0 ;

  [rc,pr,info] = vl_pr(labels, scores) ;
  results(q).rc = rc ;
  results(q).pr = pr ;
  results(q).ap = info.ap ;
  fprintf('%35s: %.2f AP\n', queries(q).name, info.ap*100) ;
end

save(opts.resultPath, 'results') ;
