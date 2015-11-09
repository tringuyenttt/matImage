function varargout = imRAG(img, varargin)
%IMRAG Region adjacency graph of a labeled image
%
%   Usage:
%   ADJ = imRAG(IMG);
%   [NODES, ADJ] = imRAG(IMG);
%   [NODES, ADJ, BNDINDS] = imRAG(IMG);
%
%   ADJ = imRAG(IMG);
%   computes region adjacencies graph of labeled 2D or 3D image IMG. 
%   The result is a N-by-2 array, containing 2 indices for each couple of
%   neighbor regions. Two regions are considered as neighbor if they are
%   separated by a black (i. e. with color 0) pixel in the horizontal or
%   vertical direction.
%   ADJ has the format [LBL1 LBL2], LBL1 and LBL2 being vertical arrays the
%   same size.
%
%   LBL1 is given in ascending order, LBL2 is given in ascending order for
%   each LBL1. Ex:
%   [1 2]
%   [1 3]
%   [1 4]
%   [2 3]
%   [2 5]
%   [3 4]
%
%   [NODES, ADJ] = imRAG(IMG);
%   Return two arrays: the first one is a [N*2] array containing centroids
%   of the N labeled region, and ADJ is the adjacency previously described.
%   For 3D images, the nodes array is [N*3].
%   
%   [NODES, ADJ, BNDINDS] = imRAG(IMG);
%   Also returns for each pair of adjacent regions the linear indices of
%   the boundary pixels or voxels (located in between the two regions).
%   BNDINDS is a cell array with as many cells as the number of rows of the
%   ADJ result.
%
%   
%   Example  (requires image processing toolbox)
%     % read and display an image with several objects
%     img = imread('coins.png');
%     figure(1); clf;
%     imshow(img); hold on; 
%     % compute the Skeleton by influence zones using watershed
%     bin = imfill(img>100, 'holes');
%     dist = bwdist(bin);
%     wat = watershed(dist, 4);
%     % compute overlay image for display
%     tmp = uint8(double(img).*(wat>0));
%     ovr = uint8(cat(3, max(img, uint8(255*(wat==0))), tmp, tmp));
%     imshow(ovr);
%     % show the resulting graph
%     [n, e] = imRAG(wat);
%     for i = 1:size(e, 1)
%         plot(n(e(i,:), 1), n(e(i,:), 2), 'linewidth', 4, 'color', 'g');
%     end
%     plot(n(:,1), n(:,2), 'bo', 'markerfacecolor', 'b');
%
%
%   % Create a basic 3D image with labels, and compute RAG
%     germs = [50 50 50;...
%         20 20 20;80 20 20;20 80 20;80 80 20; ...
%         20 20 80;80 20 80;20 80 80;80 80 80];
%     img = zeros([100 100 100]);
%     for i = 1:size(germs, 1)
%         img(germs(i,1), germs(i,2), germs(i,3)) = 1;
%     end
%     wat = watershed(bwdist(img), 6);
%     [n, e] = imRAG(wat);
%     figure; drawGraph(n, e);
%     view(3);
%

% ------
% Author: David Legland
% e-mail: david.legland@nantes.inra.fr
% Created: 2004-02-20,  
% Copyright 2007 INRA - BIA PV Nantes - MIAJ Jouy-en-Josas.

%   History
%   2007-10-12 update doc
%   2007-10-17 add example
%   2010-03-08 replace calls to regionprops by local centroid computation
%   2010-07-29 update doc
%   2012-07-20 remove the use of "diff", using less memory

%% Initialisations

% size of image
dim = size(img);

% number of dimensions
nd = length(dim);

% Number of background pixels or voxels between two regions
% gap = 0 -> regions are contiguous
% gap = 1 -> there is a 1-pixel large line or surface between two adjacent
% 	pixels, for example the result of a watershed
gap = 1;
if ~isempty(varargin) && isnumeric(varargin{1})
    gap = varargin{1};
end
shift = gap + 1;

% flag indicating whether edge indices should be computed
computeEdgeInds = nargout > 2;
if computeEdgeInds && gap ~= 1
    error('imRAG:wrongGapValue', ...
        'Edge indices can only be computed for gap equal to 1');
end


if nd == 2
    %% First direction of 2D image
    
    % identify transitions
    [i1, i2] = find(img(1:end-shift,:) ~= img((shift+1):end, :));
    
	% get values of consecutive changes
	val1 = img(sub2ind(dim, i1, i2));
	val2 = img(sub2ind(dim, i1+shift, i2));

    % keep only changes not involving background, ordered such that n1 < n2
    inds = val1 ~= 0 & val2 ~= 0 & val1 ~= val2;
    edges = sort([val1(inds) val2(inds)], 2);

    % keep array of positions as linear indices
    if computeEdgeInds
        posD1 = sub2ind(dim, i1(inds)+1, i2(inds));
    end
    
    
    %% Second direction of 2D image
    
    % identify transitions
    [i1, i2] = find(img(:, 1:end-shift) ~= img(:, (shift+1):end));
    
	% get values of consecutive changes
	val1 = img(sub2ind(dim, i1, i2));
	val2 = img(sub2ind(dim, i1, i2+shift));
    
    % keep only changes not involving background, ordered such that n1 < n2
    inds = val1 ~= 0 & val2 ~= 0 & val1 ~= val2;
    edges = [edges ; sort([val1(inds) val2(inds)], 2)];
    
    if computeEdgeInds
        % keep array of positions as linear indices
        posD2 = sub2ind(dim, i1(inds), i2(inds)+1);
        posList = [posD1 ; posD2];
    end
    
elseif nd == 3
    %% First direction of 3D image
    
    % identify transitions
    [i1, i2, i3] = ind2sub(dim-[shift 0 0], ...
        find(img(1:end-shift,:,:) ~= img((shift+1):end,:,:)));
	
	% get values of consecutive changes
	val1 = img(sub2ind(dim, i1, i2, i3));
	val2 = img(sub2ind(dim, i1+shift, i2, i3));

    % keep only changes not involving background
    inds = val1 ~= 0 & val2 ~= 0 & val1 ~= val2;
    edges = unique([val1(inds) val2(inds)], 'rows');
	
    if computeEdgeInds
        % keep array of positions as linear indices
        posD1 = sub2ind(dim, i1(inds)+1, i2(inds), i3(inds));
    end
    
    
    %% Second direction of 3D image
    
    % identify transitions
    [i1, i2, i3] = ind2sub(dim-[0 shift 0], ...
        find(img(:,1:end-shift,:) ~= img(:,(shift+1):end,:)));
	
	% get values of consecutive changes
	val1 = img(sub2ind(dim, i1, i2, i3));
	val2 = img(sub2ind(dim, i1, i2+shift, i3));

    % keep only changes not involving background
    inds = val1 ~= 0 & val2 ~= 0 & val1 ~= val2;
    edges = [edges; unique([val1(inds) val2(inds)], 'rows')];

    if computeEdgeInds
        % keep array of positions as linear indices
        posD2 = sub2ind(dim, i1(inds), i2(inds)+1, i3(inds));
    end
    
    %% Third direction of 3D image
    
    % identify transitions
    [i1, i2, i3] = ind2sub(dim-[0 0 shift], ...
        find(img(:,:,1:end-shift) ~= img(:,:,(shift+1):end)));
	
	% get values of consecutive changes
	val1 = img(sub2ind(dim, i1, i2, i3));
    val2 = img(sub2ind(dim, i1, i2, i3+shift));
    
    % keep only changes not involving background
    inds = val1 ~= 0 & val2 ~= 0 & val1 ~= val2;
    edges = [edges; unique([val1(inds) val2(inds)], 'rows')];
    
    if computeEdgeInds
        % keep array of positions as linear indices
        posD3 = sub2ind(dim, i1(inds), i2(inds), i3(inds)+1);
        posList = [posD1 ; posD2 ; posD3];
    end
end


% remove double edges, keeping in indsC indices of merged edge for each
% original edge
[edges, indsA, indsC] = unique(edges, 'rows'); %#ok<ASGLU>

if computeEdgeInds
    nEdges = size(edges, 1);
    edgeInds = cell(nEdges, 1);
    for iEdge = 1:nEdges
        inds = indsC == iEdge;
        edgeInds{iEdge} = unique(posList(inds));
    end
end

%% Output processing

if nargout == 1
    varargout{1} = edges;
    
elseif nargout >= 2
    % Also compute region centroids
    N = max(img(:));
    points = zeros(N, nd);
    labels = unique(img);
    labels(labels==0) = [];
    
    if nd == 2
        % compute 2D centroids
        for i = 1:length(labels)
            label = labels(i);
            [iy, ix] = ind2sub(dim, find(img==label));
            points(label, 1) = mean(ix);
            points(label, 2) = mean(iy);
        end
    else
        % compute 3D centroids
        for i = 1:length(labels)
            label = labels(i);
            [iy, ix, iz] = ind2sub(dim, find(img==label));
            points(label, 1) = mean(ix);
            points(label, 2) = mean(iy);
            points(label, 3) = mean(iz);
        end
    end
    
    % setup output arguments
    varargout{1} = points;
    varargout{2} = edges;
    
    if nargout > 2
        varargout{3} = edgeInds;
    end
end


