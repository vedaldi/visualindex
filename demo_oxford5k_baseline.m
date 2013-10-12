function demo_oxford5k_baseline
% DEMO_OXFORD5K_BASELINE  Vanilla matching on Oxford 5k
%   Match images directly, counting inliers to rank them. Slow but
%   accurate.
%
%   Expected mAP: 86.65%.

opts.lite = false ;
opts.imdbPath = 'data/imdb.mat' ;
opts.resultPath = 'data/results-baseline.mat' ;
run vlfeat/toolbox/vl_setup ;

%% Setup the Oxford5k data
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

%% Precompute features for queries
model.rootSift = true ;
parfor q = 1:numel(queries)
  fprintf('ox5k baseline: query %d of %d\n', q, numel(queries)) ;
  path = fullfile(images.dir, [queries(q).imageName '.jpg']) ;
  [fq{q},dq{q}] = visualindex_get_features(model, imread(path)) ;
  ok = fq{q}(1,:) >= queries(q).box(1) & ...
       fq{q}(1,:) <= queries(q).box(3) & ...
       fq{q}(2,:) >= queries(q).box(2) & ...
       fq{q}(2,:) <= queries(q).box(4) ;
  fq{q} = fq{q}(:, ok) ;
  dq{q} = dq{q}(:, ok) ;
end

%% Loop through all the images to compute matches
scores = zeros(numel(queries), numel(images.id)) ;
numQueries = numel(queries) ;
parfor t = 1:numel(images.id)
  fprintf('ox5k baseline: image %d of %d\n', t, numel(images.id)) ;
  path = fullfile(images.dir, images.name{t}) ;
  [f,d] = visualindex_get_features(model, imread(path)) ;

  for q = 1:numQueries
    [matches, H] = matchFeatures(fq{q},dq{q},f,d) ;
    scores(q,t) = size(matches,2) ;
    %plotMatches(imread(fullfile(images.dir, [queries(q).imageName '.jpg'])),imread(path),fq{1},f,matches)
  end
end

%% Evaluate mAP
for q=1:numel(queries)
  labels = 2 * ismember(images.id, [queries(q).good, queries(q).ok]) - 1 ;
  labels(ismember(images.id, queries(q).junk)) = 0 ;

  [rc,pr,info] = vl_pr(labels, scores(q,:)) ;

  results(q).query = queries(q) ;
  results(q).scores = scores(q,:) ;
  results(q).labels = labels ;
  results(q).rc = rc ;
  results(q).pr = pr ;
  results(q).ap = info.ap ;
  fprintf('%35s: %.2f AP\n', queries(q).name, info.ap*100) ;
end
fprintf('%35s: %.2f AP\n', 'mean', mean([results.ap])*100) ;
save(opts.resultPath, 'results');
