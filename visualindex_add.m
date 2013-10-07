function model = visualindex_add(model, images, ids)
% VISUALINDEX_ADD
%   MODEL = VISUALINDEX_ADD(MODEL, IMAGES, IDS) indexes the specified
%   IMAGES associating to them the given IDS. IMAGES is a cell array
%   of strings containitn path to the images and IDS are unique
%   numeric identifiers (in DOUBLE class).

%% Extract features and histograms from images

frames = cell(1,length(images)) ;
words = cell(1,length(images)) ;
histograms = cell(1,length(images)) ;
parfor i = 1:length(images)
  fprintf('%s: extracting features from %s (%d of %d)\n', ...
          mfilename, images{i}, i, numel(images)) ;
  im = imread(images{i}) ;
  [frames{i}, descrs] = visualindex_get_features(model, im) ;
  frames{i} = single(frames{i}) ;
  words{i} = visualindex_get_words(model, descrs) ;
  histograms{i} = sparse(double(words{i}),1,...
                         ones(length(words{i}),1), ...
                         model.vocab.size,1) ;
end
model.index.ids = cat(2, model.index.ids, ids) ;
model.index.frames = cat(2, model.index.frames, frames) ;
model.index.words = cat(2, model.index.words, words) ;
model.index.histograms = cat(2, model.index.histograms, histograms{:}) ;
model.index.names = cat(2,  model.index.names, images) ;

%% Compute a visual word histogram for each image, compute TF-IDF
% weights, and then reweight the histograms.

numDocuments = max(1, size(model.index.histograms,2)) ;
numDocumentsPerWord = max(1, sum(model.index.histograms > 0,2)) ;
oldWeights = model.vocab.weights ;
model.vocab.weights = log(numDocuments ./ numDocumentsPerWord) ;
reweight = model.vocab.weights ./ oldWeights ;

% reweight and renormalize all histograms
for t = 1:length(model.index.ids)
  h = model.index.histograms(:,t) .* reweight ;
  model.index.histograms(:,t) = h / norm(h) ;
end
