function [surf, labels] = imSurfaceAreaEstimate(img, varargin)
% Estimate surface area of a binary 3D structure.
%
%   Usage
%   S = imSurfaceAreaEstimate(IMG)
%   Estimate the surface area of the structure within the image, without
%   measuring surface area of borders.
%   The aim of this function is to be called by the "imSurfaceAreaDensity"
%   function, for providing an estimate of surface area density within a
%   representative volume of interest.
%
%
%   Example
%   imSurfaceAreaEstimate
%
%   See also
%   imSurfaceArea, imSurfaceAreaDensity
%

% ------
% Author: David Legland
% e-mail: david.legland@inrae.fr
% Created: 2010-07-26,    using Matlab 7.9.0.529 (R2009b)
% Copyright 2010 INRAE - Cepia Software Platform.


%% Process input arguments 

% check image dimension
if ndims(img) ~= 3
    error('first argument should be a 3D image');
end

% in case of a label image, return a vector with a set of results
if ~islogical(img)
    labels = unique(img);
    labels(labels==0) = [];
    surf = zeros(length(labels), 1);
    for i = 1:length(labels)
        surf(i) = imSurfaceAreaEstimate(img==labels(i), varargin{:});
    end
    return;
end


%% Process input arguments

% in case of binary image, compute only one label...
labels = 1;

% default number of directions
nDirs = 13;

% default image resolution
delta = [1 1 1];

% Process user input arguments
while ~isempty(varargin)
    var = varargin{1};
    if ~isnumeric(var)
        error('option should be numeric');
    end
    
    % option is either connectivity or resolution
    if isscalar(var)
        nDirs = var;
    else
        delta = var;
    end
    varargin(1) = [];
end


%% Use the LUT to estimate surface area

lut = imSurfaceAreaLut(delta, nDirs);
bch = imBinaryConfigHisto(img);
surf = sum(bch .* lut);
