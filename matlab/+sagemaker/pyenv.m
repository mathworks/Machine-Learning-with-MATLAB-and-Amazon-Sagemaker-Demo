function out = pyenv(envFolder)
% pyenv

% Copyright 2023 The MathWorks, Inc.
arguments
    envFolder string = fileparts(mfilename('fullpath'));
end

venvname = 'sagemaker-env';
venv = fullfile(envFolder, venvname);

if ~exist(venv, 'dir')
    disp("Creating venv - " + venv)
    [s, msg] = system("python3 -m venv " + venvname);
    assert(s==0, msg);
end

thisFolder = fileparts(mfilename('fullpath'));
requirements = fullfile(thisFolder, '+internal', 'requirements.txt');
[s, msg] = system("source " + fullfile(venv, 'bin', 'activate') + " && python3 -m pip install -r " + requirements);
assert(s==0, msg);

terminate(pyenv);

out = pyenv('Version', fullfile(venv, 'bin', 'python3'), ...
    'ExecutionMode', 'OutOfProcess');
end
