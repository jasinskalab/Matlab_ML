classdef LSTMmodel
    %LSTMMMODEL Summary of this class goes here
    %   Detailed explanation goes here
    properties(Constant)
        inputSize = [5 9 2];
        filterSize = [2 2 2];
        classes = 2;
        numHiddenUnits =128;
        miniBatchSize =10;
        CNNFilterSize=[2,2];
    end
    properties
        SubjectMat % subject ID matrix
        randSubjectMat % randomized subject ID Matrix to perform N Fold.
        trainingData;
        ValidationData;
    end
    methods
        
    end
    methods(Static)
        %TO DO
        %Adjust Func inputs to be NIRSfolder and pipe all functions into
        %one continous execution
        
        %%
        function [nn,info] = trainNN(data,lgraph)
            
            inputSize = [5 9 2];
            filterSize = [2 2 2];
            classes = 2;
            numHiddenUnits =128;
            miniBatchSize =10;
            CNNFilterSize=[2,2];
            %Formatting input to 1xN array of channel data and 1xN array of
            %classifiers
            if(isa(data,'table'))
                data = table2struct(data);
            end
            for i= 1:length(data)
                S(i).channelData = permute(cat(4,data(i).oxyData,data(i).deoxyData),[1 2 4 3]);
                S(i).classifier = data(i).literacy;
            end
            input = struct2table(S);
            
            obj = LSTMmodel();
            
            input.classifier = categorical(input.classifier);
            
            
            
           
            
            info = crossval(@(XTRAIN, YTRAIN, XTEST, YTEST)( LSTMmodel.fun(XTRAIN, YTRAIN, XTEST, YTEST)),input.channelData,input.classifier,'kfold',47);
            
            
            
            %[nn,info] = trainNetwork(input.channelData,input.classifier,lgraph,options);
            
        end
        function lgraph = generateNN()
            
            lgraph = layerGraph();
            
            %%
            miniBatchSize = 20;
            
            tempLayers = [
                sequenceInputLayer([5 9 2],"Name","InputNIRS","Normalization","zerocenter")
                sequenceFoldingLayer("Name","Fold")];
            lgraph = addLayers(lgraph,tempLayers);
            
            tempLayers = [
                convolution2dLayer(2,96,"Name","ConvA2d")
                maxPooling2dLayer(2,"Name","maxpoolA2d","Stride",1)
                convolution2dLayer(2,96,"Name","ConvB2d")
                maxPooling2dLayer(2,"Name","maxpoolB2d","Stride",1)];
            lgraph = addLayers(lgraph,tempLayers);
            
            tempLayers = [
                sequenceUnfoldingLayer("Name","Unfold")
                flattenLayer("Name","flattenForLSTM")
                lstmLayer(512,"Name","LSTM","OutputMode","last")
                fullyConnectedLayer(2,"Name","DenseFCALayer")
                dropoutLayer(0.25,"Name","DenseDropoutLayer")
                fullyConnectedLayer(2,"Name","DenseFCBLayer")
                softmaxLayer("Name","softmaxLayer")
                classificationLayer("Name","BinaryClassifier")];
            lgraph = addLayers(lgraph,tempLayers);
            %%
            lgraph = connectLayers(lgraph,"Fold/out","ConvA2d");
            lgraph = connectLayers(lgraph,"Fold/miniBatchSize","Unfold/miniBatchSize");
            lgraph = connectLayers(lgraph,"maxpoolB2d","Unfold/in");
            
        end
        function info = fun(XTRAIN, YTRAIN, XTEST, YTEST)
             options = trainingOptions('adam', ...
                'MaxEpochs',100,...
                'InitialLearnRate',2e-3, ...
                'Verbose',false, ...
                'MiniBatchSize',10,...
                'Plots','training-progress');
            net = LSTMmodel.generateNN();
            nn = trainNetwork(XTRAIN,YTRAIN,net,options);
            
            % slashes collide with file path conventions. changed datetime
            % format to ISO8601: yyyymmddTHHMMSS
            %modelName = ['MODEL_' datestr(datetime('now'),2) '_' datestr(datetime('now'),13) ];
            modelName = ['MODEL_' datestr(datetime('now'),30) ];

            [YPred,info] = nn.classify(XTEST);
            accuracy = sum(YPred == YTEST)/numel(YTEST);
            disp(accuracy);
            
            save(modelName);
            %yNet = net(XTEST');
            %'// find which output (of the three dummy variables) has the highest probability
            %[~,classNet] = max(yNet',[],2);
            
            %// convert YTEST into a format that can be compared with classNet
            %[~,classTest] = find(YTEST);
            
            
            %'// Check the success of the classifier
            %cp = classperf(classTest, classNet);
            %testval = cp.CorrectRate; %// replace this with your preferred metric
        end
    end
end

