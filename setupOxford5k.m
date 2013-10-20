function [images queries] = setupOxford5k(imagesDir, gtDir, varargin)
% SETUPOXFORD5K  Setup Oxford5k data

  opts.autoDownload = true ;
  opts = vl_argparse(opts, varargin) ;

  %% Autodownload data if needed
  if opts.autoDownload
    if ~exist(gtDir, 'dir')
      fprintf('Downloading and unpacking Oxford building datset gt to %s\n', gtDir) ;
      vl_xmkdir(gtDir) ;
      untar('http://www.robots.ox.ac.uk/~vgg/data/oxbuildings/gt_files_170407.tgz',gtDir) ;
    end
    if ~exist(imagesDir, 'dir')
      fprintf('Downloading and unpacking Oxford building datset images to %s\n', imagesDir) ;
      vl_xmkdir(imagesDir) ;
      untar('http://www.robots.ox.ac.uk/~vgg/data/oxbuildings/oxbuild_images.tgz',imagesDir) ;
    end
  end

  %% Get the list of all images
  names = dir(fullfile(imagesDir, '*.jpg')) ;
  numImages = numel(names);
  images.id = 1:numImages ;
  images.name = {names.name} ;
  images.dir = imagesDir ;

  %% Source all the queries
  postfixless = cell(numImages,1);
  for i = 1:numImages
    [ans,postfixless{i}] = fileparts(images.name{i}) ;
  end

  function i = toindex(x)
    [ok,i] = ismember(x,postfixless) ;
    i = i(ok) ;
  end

  names = dir(fullfile(gtDir,'*_query.txt'));
  names = {names.name} ;
  for i = 1:numel(names)
    fprintf('%s: sourcing query %s\n', mfilename, names{i}) ;
    [imageName,x0,y0,x1,y1] = textread(fullfile(gtDir, names{i}), ...
                                       '%s %f %f %f %f') ;
    name = names{i} ;
    name = name(1:end-10) ;
    imageName = cell2mat(imageName) ;
    imageName = imageName(6:end) ;
    queries(i).name = name ;
    queries(i).imageName = imageName ;
    queries(i).imageId = toindex(imageName) ;
    queries(i).box = [x0;y0;x1;y1] ;
    queries(i).good = ...
        toindex(textread(fullfile(gtDir, sprintf('%s_good.txt',name)), '%s'))' ;
    queries(i).ok = ...
        toindex(textread(fullfile(gtDir, sprintf('%s_ok.txt',name)), '%s'))' ;
    queries(i).junk = ...
        toindex(textread(fullfile(gtDir, sprintf('%s_junk.txt',name)), '%s'))' ;
  end
end
