run vlfeat/toolbox/vl_setup ;

opts.lite = false ;
opts.imdbPath = 'data/imdb.mat' ;
opts.indexPath = 'data/index5.mat' ;
opts.emptyIndexPath = 'data/index-empty5.mat' ;
opts.resultPath = 'data/results5.mat' ;

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

% Populate the index
if exist(opts.indexPath, 'file')
  index = load(opts.indexPath) ;
else
  paths = cellfun(@(x) fullfile(images.dir, x), images.name, 'UniformOutput', false) ;
  if exist(opts.emptyIndexPath, 'file')
    index = load(opts.emptyIndexPath) ;
  else
    index = visualindex_build(paths,'numWords', 1e5) ;
    save(opts.emptyIndexPath, '-STRUCT', 'index') ;
  end
  index = visualindex_add(index, paths, images.id) ;
  save(opts.indexPath, '-STRUCT', 'index') ;
end

index.index.names = cellfun(@(x) fullfile(images.dir, x), images.name, 'UniformOutput', false) ;
for q=1:numel(queries)
  queries(q).imagePath = fullfile(images.dir, [queries(q).imageName '.jpg']) ;
end
index.rerankDepth = 200 ;

% Evaluate queries
for q = 1:numel(queries)
  path = fullfile(images.dir, [queries(q).imageName '.jpg']) ;
  [ids, scores, matches, H, frames] = visualindex_query(index, imread(path), 'box', queries(q).box) ;
  labels = 2 * ismember(ids, [queries(q).good, queries(q).ok]) - 1 ;
  labels(ismember(ids, queries(q).junk)) = 0 ;

  [rc,pr,info] = vl_pr(labels, scores) ;
  results(q).query = queries(q) ;
  results(q).ids = ids ;
  results(q).matches = matches ;
  results(q).queryFrames = frames ;
  results(q).H = H ;
  results(q).scores = scores ;
  results(q).labels = labels ;
  results(q).rc = rc ;
  results(q).pr = pr ;
  results(q).ap = info.ap ;
  fprintf('%35s: %.2f AP\n', queries(q).name, info.ap*100) ;
end

save(opts.resultPath, 'results') ;
