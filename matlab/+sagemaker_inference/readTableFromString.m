function tbl = readTableFromString(inputstr, varargin)
% readTableFromString

% Copyright 2023 The MathWorks, Inc.
    tmpfile = tempname;
    fid = fopen(tmpfile, 'wt');
    fc = onCleanup(@()fclose(fid));
    fd = onCleanup(@()delete(tmpfile));
    fprintf(fid, "%s", inputstr);
    tbl = readtable(tmpfile, varargin{:});
end