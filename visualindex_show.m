function visualindex_show(model, result, varargin)
% VISUALINDEX_SHOW  Displays search results
%   PLOTRETRIEVEDIMAGES(IMDB, SCORES) displays the images in the
%   database IMDB that have largest SCORES. SCORES is a row vector of
%   size equal to the number of images in IMDB.

% Author: Andrea Vedaldi and Mireca Cimpoi

opts.num = 16 ;
opts = vl_argparse(opts, varargin) ;

clf reset ;
for rank = 1:opts.num
  vl_tightsubplot(opts.num, rank) ;
  index = find(result.ids(rank) == model.index.ids) ;
  im0 = imread(model.index.names{index}) ;

  data.h(rank) = imagesc(im0) ;
  axis image off ; hold on ;

  if isfield(result, 'labels')
    switch result.labels(rank)
      case 0, cl = 'y' ;
      case 1, cl = 'g' ;
      case -1, cl = 'r' ;
    end
  else
    cl = 'c' ;
  end

  text(0,0,...
    sprintf('%d: score:%.3g', rank, full(result.scores(rank))), ...
    'background', cl, ...
    'verticalalignment', 'top') ;

  set(data.h(rank), 'ButtonDownFcn', @zoomIn) ;
end

% for interactive plots
data.result = result ;
data.model = model ;
guidata(gcf, data) ;

% --------------------------------------------------------------------
function zoomIn(h, event, data)
% --------------------------------------------------------------------
data = guidata(h) ;
if ~isstruct(data.result), return ; end

rank = find(h == data.h) ;
ii = find(data.result.ids(rank) == data.model.index.ids) ;
im1 = imread(data.result.query.imagePath) ;
im2 = imread(data.model.index.names{ii}) ;
frames1 = data.result.queryFrames ;
frames2 = data.model.index.frames{ii} ;
matches12 = data.result.matches{rank} ;
H12 = data.result.H{rank} ;

figure ; clf ;
plotMatches(im1,im2,frames1,frames2,matches12,'homography',H12) ;
