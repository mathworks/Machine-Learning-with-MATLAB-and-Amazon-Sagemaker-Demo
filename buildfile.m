function plan = buildfile
import matlab.buildtool.tasks.*;

plan = buildplan(localfunctions);

plan("clean") = CleanTask;

plan("markdown").Inputs = "**/*.mlx";
plan("markdown").Outputs = replace(plan("markdown").Inputs, ".mlx",".md");
plan("markdown").Outputs(end+1) = replace(plan("markdown").Inputs, ".mlx","_media");
plan("markdown").Outputs(end+1) = "mdOutputs.txt";

plan("jupyter").Inputs = "**/*.mlx";
plan("jupyter").Outputs = replace(plan("jupyter").Inputs, ".mlx",".ipynb");

end

function markdownTask(ctx)
% Generate markdown from all mlx files

mlxFiles = ctx.Task.Inputs.paths;
mdFiles = ctx.Task.Outputs(1).paths;
for idx = 1:numel(mlxFiles) 
    disp("Building markdown file from " + mlxFiles(idx))
    export(mlxFiles(idx), mdFiles(idx), Run=false, EmbedImages=false);
end

writelines(ctx.Task.Outputs.paths,"mdOutputs.txt");
end

function jupyterTask(ctx)
% Generate jupyer notebooks from all mlx files

mlxFiles = ctx.Task.Inputs.paths;
ipynbFiles = ctx.Task.Outputs.paths;
for idx = 1:numel(mlxFiles) 
    disp("Building jupyter notebook from " + mlxFiles(idx))
    export(mlxFiles(idx), ipynbFiles(idx), Run=false);
end
end