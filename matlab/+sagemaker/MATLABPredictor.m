classdef MATLABPredictor
% MATLABPredictor 

% Copyright 2023 The MathWorks, Inc.
    properties(Access=private)
        SageMakerPredictor
    end
    properties(Dependent)
        EndpointName string
    end    
    methods
        function obj = MATLABPredictor(endpointName, session)
            arguments
                endpointName string
                session = sagemaker.Session()
            end
            s = py.sagemaker.serializers.IdentitySerializer(content_type='text/csv');
            d = py.sagemaker.deserializers.StringDeserializer(accept='text/csv');

            obj.SageMakerPredictor = py.sagemaker.predictor.Predictor(endpointName, ...
                sagemaker_session=session.SageMakerSession, ...
                serializer=s, deserializer=d);
        end

        function name = get.EndpointName(obj)
            name = string(obj.SageMakerPredictor.endpoint_name);
        end
        
        function out = predict(obj, in)
            in = writeTableToString(in);
            out = string(obj.SageMakerPredictor.predict(in));
            out = readTableFromString(out);
        end

        function deleteEndpoint(obj, deleteCfg)
            arguments
                obj
                deleteCfg = true
            end
            obj.SageMakerPredictor.delete_endpoint(delete_endpoint_config=deleteCfg);            
        end        

        function deleteModel(obj)
            arguments
                obj
            end
            obj.SageMakerPredictor.delete_model();
        end
    end
end

function tbl = readTableFromString(inputstr, varargin)
    tmpfile = tempname;
    fid = fopen(tmpfile, 'wt');
    fc = onCleanup(@()fclose(fid));
    fd = onCleanup(@()delete(tmpfile));
    fprintf(fid, "%s", inputstr);
    tbl = readtable(tmpfile, varargin{:});
end

function outputstr = writeTableToString(tbl, varargin)
    tmpfile = [tempname, '.txt'];
    writetable(tbl, tmpfile, varargin{:});
    fid = fopen(tmpfile, 'rt');
    fc = onCleanup(@()fclose(fid));
    fd = onCleanup(@()delete(tmpfile));
    outputstr = string(fscanf(fid, "%c"));
end