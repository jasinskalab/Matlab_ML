classdef NMLstartup
    %NMLSTARTUP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        classificationName;
        inputData;
        trialSpec;
        dataLocation;
        
        
    end
    properties(Constant)
        %
        %
        %
        %
        %
        
        NVPairNames = ["RSPS","LNL","LNL-PSP","LNL-RS","LNL-PSS","PS-PS"];
    end
    
    methods
        % Input will be name value pair of trial types, data location and classification
        % problem.
        
        %flags
        % --
        % 
        % '-s' Use subject-wise analysis DEFAULT is filewise
        % '-f' Input Data is a folder of files
        function obj = NMLstartup(varargin)
            %Initially parse input Varargin
            p = inputParser;
            nameValidation = @(x) (ischar(x) || isstring(x));
            p.addRequired("Name",nameValidation);
            
            trialSpecValidation = @(x)any(strcmp(x,obj.NVPairNames));
            p.addRequired("trialSpec",trialSpecValidation);
            
            inputDataValidation = (@(x)(exist(x,'folder'))||(@(x)isa(x,'table')));
            p.addRequired("input",inputDataValidation);
            
            p.addParameter("ChannelDownsampleFactor",1,@(x)isnumeric(x));
            p.addParameter("SubjectDownsampleFactor",1,@(x)isnumeric(x));
            
            p.addParameter("flag","",@isstring);
            
            parse(p,varargin{:});
            
            pVals = @p.Results;
            obj.trialSpec = p.Results.trialSpec;
            obj.ClassificationName = p.Results.Name;
            
            if(contains(p.Results.flags,'s'))
               obj.dataLocation = p.Results.inputData; 
            end
            
            
            
            %id the flags given
            
            
            %Process Outline
            
            %INIT
            
            
            
            
            
            
            data = [];
            if((contains(p.Results.flags,'s'))||(~isa(p.Results.inputData,'table')&&exist(p.Results.inputData,7)))
                for i =1:size(p.Results.inputData)
                    %GenerateSubjectData
                    tData = NMLstartup.generateSubjectData(p.Results.inputData,trialSpec,p.Results.ChannelDownsampleFactor);
                    data = [data tData];
                    
                end
            else
                
            
            end
            %Remove all empty data
            randData = randData(~cellfun(@isempty,{randData.oxyData}));
            
            randData = NMLstartup.generateLiteracyScore(randData);
            
            %ConvertNirsText
            %Extract
            %Randomize and clean
            
            
            
            %NMLSTARTUP Construct an instance of this class
            %   Detailed explanation goes here
            
            
            
            
            
            
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
        
    end
    methods(Static)
        %TODO:: Extract each block of PS data to individual blocks for
        %passing to model.
        %
        
        
        function [blockChannelInfo] = extractBlockData(channelInfo)
            
            
            a = find(logical(channelInfo.Task));
            a=a(:)-1;%to account for first index being time 0;
            
            blockChannelInfo = [];
            for i = 2:length(a)-1
                blockChannelInfo = [blockChannelInfo ;channelInfo(ceil(a(i)+15/.1350):ceil(a(i)+30/.1350),:)];
            end
            
            
        end
        function [oxyHb,deoxyHb,channelInfo] = ConvertNirsTextToInputFormat(filename,resampleRate)
            
            
            matrixInput = readtable(filename,'HeaderLines',34);
            names = matrixInput.Properties.VariableNames;
            matrixInput = NMLstartup.extractBlockData(matrixInput);
            if(isempty(matrixInput))
                oxyHb = [];
                deoxyHb = [];
                channelInfo = [];
                return
            end
            toberemoved = [names(contains(names(:), 'External')) names(contains(names(:), 'total')) names(contains(names(:), 'Var'))];
            channelInfo = removevars(matrixInput,toberemoved);
            varNames = channelInfo.Properties.VariableNames;
            % Removing channels to allow for even completion of 5x9
            
            channelInfo = removevars(channelInfo,[varNames(contains(varNames(:), 'Hb_10')) varNames(contains(varNames(:), 'Hb_29'))]);
            
            if(nargin>1)
                % Smooth with flat kernel of ~1/2 sec (BZ 7/24/2019)
                channelInfo{:,5:end} = filter2(ones(4,1),channelInfo{:,5:end});
                % Ben changed the beginning from 1 to 220 (about 30 sec
                % into the measurement) and only taking the first minute
                % after that (sample #665 or end of file) 7/25/19
                % channelInfo{:,5:end} = channelInfo{220:resampleRate:(min([1105 size(channelInfo,1)])),5:end};
                channelInfo{:,5:end} = channelInfo{1:resampleRate:end,5:end};
            else
                channelInfo = channelInfo(1:2:end,:);
            end
            
            %Constructing 5x9xT matrix.
            
            
            oxyHb = reshape(table2array(channelInfo(:,5:2:end)),size(table2array(channelInfo(:,5:2:end)),1),9,5);
            deoxyHb = reshape(table2array(channelInfo(:,6:2:end)),size(table2array(channelInfo(:,6:2:end)),1),9,5);
            
            
            
            
            
            
            
        end
        
        
        
        function [nn,info] = initLSTMData(resampleRate,subjectResample)
            %NMLstartup Construct an instance of this class
            %   Detailed explanation goes here
            
            %% We want to store the subject data that will be fed to the ML model into a central 2D array.
            
            %%
            
            if(nargin<1)
                resampleRate = 1;
                subjectResample = 1;
            elseif(nargin<2)
                subjectResample = 1;
            end
            
            
            
            if((exist('randomData.mat','file'))~=2)
                spData = NMLstartup.generateSubjectData('/Volumes/data/Data/ben_IC/Wave1-Adzope/NIRS_sorted/','SP',resampleRate);
                %rsData = NMLstartup.generateSubjectData('/Volumes/data/Data/ben_IC/Wave1-Adzope/NIRS_sorted/','R',resampleRate);
                %catData = [spData rsData];
                
                struct2table(spData);
                randData = spData;
                clearvars('-except','randData');
                
                randData = randData(~cellfun(@isempty,{randData.oxyData}));
                randData = NMLstartup.generateLiteracyScore(randData);
                %randData = NMLstartup.concatSubjectData(randData);
                
                randData = randData(randperm(size(randData,2)));
                save('randomData');
            else
                s = load('randomData.mat');
                randData = s.randData;
            end
            
            
            
            
            %mode = mode(cellfun(@length,{randData.oxyData}))
            
            
            %randData = randData(1:subjectResample:end);
            [nn,info] = LSTMmodel.trainNN(randData);
        end
        
        
        
        function collatedSubjectData = generateSubjectData(NirsSortedFolder,trialSpec,resampleRate)
            
            txtFiles = dir([NirsSortedFolder filesep '*' filesep [trialSpec '*'] filesep '*.txt']);
            randOrderTxtFiles = txtFiles(randperm(length(txtFiles)));
            if(nargin<4)
                resampleRate = 1;
            end
            
            
            tic
            i=1;
            while i<=length(txtFiles)
                warning('off','all');
                collatedSubjectData(i).name = randOrderTxtFiles(i).name; %#ok<*AGROW>
                collatedSubjectData(i).TrialSpec = trialSpec;
                try
                    [collatedSubjectData(i).oxyData,collatedSubjectData(i).deoxyData] =...
                        NMLstartup.ConvertNirsTextToInputFormat(fullfile(randOrderTxtFiles(i).folder,randOrderTxtFiles(i).name),resampleRate);
                    
                catch ME
                    disp(ME);
                    if(i>=length(txtFiles))
                        break
                    end
                    randOrderTxtFiles(i) = [];
                    txtFiles(i) = [];
                    collatedSubjectData(i) = [];
                    i=i-1;
                    
                    disp(i);
                    
                end
                
                i=i+1;
                warning('on','all');
            end
            toc
            for i = 1:length(collatedSubjectData)
                collatedSubjectData(i).oxyData = permute(collatedSubjectData(i).oxyData,[3 2 1]);
                collatedSubjectData(i).deoxyData = permute(collatedSubjectData(i).deoxyData,[3 2 1]);
            end
            
            
        end
        
        function data = generateLiteracyScore(subjectData,literacyCutoff)
            fulldata = readtable('/Volumes/data/Data/ben_IC/MattesonWorking/data/FullDataApril242019.csv');
            fulldata = fulldata(~cellfun(@isempty,fulldata.NIRSCODE),:);
            
            
            [start stop] = cellfun(@(x) regexp(x,'^\d+_\d+_\d+'),{subjectData.name});
            
            for i = 1:size(subjectData,2)
                name = subjectData(i).name;
                name = (sprintf('%2.0f_%2.0f_%2.0f',cellfun(@str2num,strsplit(name(1:stop(i)),'_'))));
                name = name(find(~isspace(name)));
                subjectData(i).NirsID = name;
            end
            x = 0;
            for i = 1:size(subjectData,2)
                log = contains(fulldata.NIRSCODE,subjectData(i).NirsID);
                if(any(log))
                    if(fulldata.TotalWordReading(find(log))<=6)
                        subjectData(i).literacy = "NonLiterate";
                    else
                        subjectData(i).literacy = "Literate";
                    end
                else
                    disp(subjectData(i).name);
                    x = x+1;
                    disp(x);
                end
            end
            data = subjectData;
        end
        
        
        
        
        function newData = concatSubjectData(randData)
            newData = randData(1);
            newData(1).name = '';
            newData(1).oxyData = [];
            newData(1).deoxyData = [];
            newData(1).NirsID = '';
            newData(1).literacy = '';
            
            
            uData = unique({randData.NirsID});
            for i=1:length(uData)
                index = find(strcmp({randData.NirsID},uData(i)));
                for j = 1:length(index)
                    if(j==1)
                        newData(i).NirsID = randData(index(j)).NirsID;
                        newData(i).name = randData(index(j)).name;
                        newData(i).literacy = randData(index(j)).literacy;
                        newData(i).TrialSpec = randData(index(j)).TrialSpec;
                    end
                    newData(i).oxyData = cat(3,newData(i).oxyData, randData(index(j)).oxyData);
                    newData(i).deoxyData = cat(3,newData(i).deoxyData, randData(index(j)).deoxyData);
                end
                
            end
            
            
        end
    end
end



