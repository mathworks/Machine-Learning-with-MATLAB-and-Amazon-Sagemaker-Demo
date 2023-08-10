function outputstr = writeTableToString(tbl, varargin)
% writeTableToString

% Copyright 2023 The MathWorks, Inc.
    tmpfile = [tempname, '.txt'];
    writetable(tbl, tmpfile, varargin{:});
    fid = fopen(tmpfile, 'rt');
    fc = onCleanup(@()fclose(fid));
    fd = onCleanup(@()delete(tmpfile));
    outputstr = string(fscanf(fid, "%c"));
end