run vlfeat/toolbox/vl_setup ;

opts.lite = false ;
opts.imdbPath = 'data/imdb.mat' ;
opts.indexPath = 'data/index5.mat' ;
opts.emptyIndexPath = 'data/index-empty5.mat' ;
opts.resultPath = 'data/results5.mat' ;
opts.geometricVerification = false ;

load(opts.imdbPath, 'images', 'queries') ;
index = load(opts.emptyIndexPath);

randn('state',0) ;
rand('state',0) ;

rng = randperm(numel(images.name)) ;
clear f d ;
for t=1:3
  im = imread(fullfile(images.dir, images.name{rng(t)})) ;
  [f{t},d{t}] = visualindex_get_features(index, im) ;
end

x = index.vocab.centers ;
d = cat(2, d{:}) ;
d = vl_colsubset(d, 500, 'uniform') ;

% exact
tic
dist2=pdist2(x',d')  ;
[d2,words] = sort(dist2,1) ;
toc

figure(1) ; clf ;
for nt=1:8
  % KD
  tree = vl_kdtreebuild(x,'numTrees',nt) ;
  tic
  [words_,d2_] = vl_kdtreequery(tree, x, d, 'maxNumComparisons', 2000) ;
  toc
  
  % rank
  [~,rank]=max(bsxfun(@eq, words, words_),[],1) ;
  
  h=histc(rank,0.5:30.5);
  
  
  vl_tightsubplot(8,nt,'box','outer');
  bar([1:30 31],h/sum(h)) ;
  ylim([0 1]) ;
  grid on ;
  drawnow ;
end


