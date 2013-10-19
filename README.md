VisualIndex - A simple image indexing engine in MATLAB
======================================================

v0.9, Andrea Vedaldi, University of Oxford.


VisualIndex is a MATLAB and VLFeat-based program to index and query
visually a collection of images. This system obtains near
state-of-the-art performance on the Oxford 5k benchmark. Specifically:

- `demo_oxford5k` - TF-IDF + spatial verification index with 83.9%
  mAP.
- `demo_oxford5k_baseline` - Direct image matching (no index) with
  87.7% mAP.

This implementation is very compact and simple, useful for education
and research.

## DOWNLOAD

The home of this package is on GitHub
(https://github.com/vedaldi/visualindex). The code requires MATLAB
2009B onwards and requires installing the VLFeat library in the
vlfeat/ subfolder.

## USING THE CODE

Using the code is simple. Given a cell array of paths to images
`images`, start by initializing the index structure:

    index = visualindex_build(images) ;

This will estimate a visual word vocabulary, but will not add the
images to the index yet. Use options such as 'numWords', to specify
how many visual words to use in the creation of the index (see the
inline help for details). To add images to the index use:

    visualindex_add(index, images, ids) ;

where `ids` is a vector of numeric image IDs (used as a convenience
instead of image names to refer to images later). To query the index
use

    [ids, scores] = visualindex_query(index, image)

where `image` is either an ID of one of the images added to the index,
a new image, or a path to a new image. Use options such as
`geometricVerification` to control aspects of the query process. Use
the `box` option to restrict the search to a box. The function returns
a list of image ids and matching scores by decreasing confidence.

To visualize the top matches use:

    [ids, scores, result] = visualindex_query(index, image, path) ;
    visualindex_show(index, result) ;

## RUNNING THE BENCHMARKS

To run the demo, make sure that VLFeat is contained in a subfolder of
the VisualIndex package directory and that it is compiled. Then, run
MATLAB and issue

    > demo_oxford5k

to automatically download the Oxford 5k building dataset and start
running demo queries. The indexing process takes a while, but can
accelerated significantly by distributing the work on multiple cores or
computers by opening a matlabpool (see MATLABPOOL()).

## CHANGES

- 0.9 - Significant performance improvements
- 0.1 - Initial release
