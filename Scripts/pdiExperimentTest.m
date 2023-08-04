
function tests = pdiExperimentTest
    tests = functiontests(localfunctions);
end

% Before running the tests, save the original values that were in the
% dictionary so we can reset the dictionary after runnning each test
function setupOnce(testCase)
    [~, dataSectionObj, ~, ~] = getPdiParamsValues()
    dataNames = {dataSectionObj.find.Name};
    for i = 1:length(dataNames)
        eval(['def',dataNames{i},'= getValue(getEntry(dataSectionObj,dataNames{i}));'])
    end
    save('originalValues.mat','def*');
end

% After each test, replace the values that are in the SLDD with the
% original valeus and delete any that were not originally there
function teardown(testCase)
    % Get the post-test entry objects for each item
    [~, dataSectionObj, ~, ~] = getPdiParamsValues()
    currentPdiBus = getEntry(dataSectionObj, 'pdiBus');
    currentPdiParams = getEntry(dataSectionObj, 'pdiParams');
    currentPdiBusStruct = getEntry(dataSectionObj, 'pdiBusMatLabStruct');
    currentPidControlParams = getEntry(dataSectionObj, 'pidControlParamBus');

    % Replace them with the original versions in preparation for next test
    load('originalValues.mat')
    deleteEntry(currentPdiBus);
    deleteEntry(currentPdiParams);
    deleteEntry(currentPdiBusStruct);
    deleteEntry(currentPidControlParams);
    vars = who;
    defVars = regexp(vars,'def\w+','match');
    logLookup = ~cellfun(@isempty,defVars);
    indexLookup = find(logLookup);
    for i = 1:sum(logLookup)
        defVarsString = char(defVars{indexLookup(i)});
        addEntry(dataSectionObj,defVarsString(4:end),eval(defVarsString));
    end

    % Delete items that were not in the original SLDD, if any. This will
    % only apply to tests for deeply nested buses.
    if exist(dataSectionObj, 'added1')
        deleteEntry(getEntry(dataSectionObj, 'added1'));
        deleteEntry(getEntry(dataSectionObj, 'added2'));
        deleteEntry(getEntry(dataSectionObj, 'added3'));
        deleteEntry(getEntry(dataSectionObj, 'added4'));
        deleteEntry(getEntry(dataSectionObj, 'added5'));
        deleteEntry(getEntry(dataSectionObj, 'added6'));
        deleteEntry(getEntry(dataSectionObj, 'added7'));
        deleteEntry(getEntry(dataSectionObj, 'added8'));
    end
end


%% TEST CASES

function testReassignTopLevelValue(testCase)
    % edit the struct pdiParams so we can construct an expected solution
    [dictObj, ~, dictEntry, value] = getPdiParamsValues();
    newValue = value;
    newValue.Value.version = 5;
    setValue(dictEntry,newValue);
    expSolution = getValue(dictEntry);
    close(dictObj);

    % call our function
    CreatePdiBusParameter();
    
    % get the actual solution (the new value of the struct pdiParams) and
    % check if it is correct
    [~, ~, ~, value] = getPdiParamsValues();
    actualSolution = value.Value;
    verifyEqual(testCase,actualSolution,expSolution.Value);
end


function testReassignNestedValue(testCase)
    % edit the struct pdiParams so we can construct an expected solution
    [dictObj, ~, dictEntry, value] = getPdiParamsValues();
    newValue = value;
    newValue.Value.altitude.kp = 56;
    setValue(dictEntry,newValue);
    expSolution = getValue(dictEntry);
    close(dictObj);

    % call our function
    CreatePdiBusParameter();

    % get the actual solution (the new value of the struct pdiParams) and
    % check if it is correct
    [~, ~, ~, value] = getPdiParamsValues();
    actualSolution = value.Value;
    verifyEqual(testCase,actualSolution,expSolution.Value);
end


function testReassignDeeplyNestedValue(testCase)
    % edit the struct pdiParams so we can construct an expected solution
    [dictObj, ~, dictEntry, value] = getPdiParamsValues();
    newValue = value;
    newValue.Value.content0.content1.content2.content3.content4.content5.content6.content7.content8 = 53;
    setValue(dictEntry,newValue);
    expSolution = getValue(dictEntry);

    % add nesting to the pdiBus, reassign value in pdiParams struct, then
    % call function
    addDeepNesting();
    newValue.Value.content0.content1.content2.content3.content4.content5.content6.content7.content8 = 53;
    close(dictObj);
    CreatePdiBusParameter();

    % get the actual solution (the new value of the struct pdiParams) and
    % check if it is correct
    [~, ~, ~, value] = getPdiParamsValues();
    actualSolution = value.Value;
    verifyEqual(testCase,actualSolution,expSolution.Value);
end


function testRemoveTopLevelElement(testCase)
    % edit the struct pdiParams so we can construct an expected solution
    [dictObj, ~, dictEntry, value] = getPdiParamsValues();
    newValue = value;
    newValue.Value = rmfield(newValue.Value,'version');
    setValue(dictEntry,newValue);
    expSolution = getValue(dictEntry);

    % remove the element from its bus and call the function
    removeNestedBusElement('pdiBus', 1);
    close(dictObj);
    CreatePdiBusParameter();

    % get the actual solution (the new value of the struct pdiParams) and
    % check if it is correct
    [~, ~, ~, value] = getPdiParamsValues();
    actualSolution = value.Value;
    verifyEqual(testCase,actualSolution,expSolution.Value);
end


function testRemoveNestedElement(testCase)
    % edit the struct pdiParams so we can construct an expected solution
    [dictObj, ~, dictEntry, value] = getPdiParamsValues();
    newValue = value;
    newValue.Value.verticalSpeed = rmfield(newValue.Value.verticalSpeed,'feedforward');
    newValue.Value.altitude = rmfield(newValue.Value.altitude,'feedforward');
    newValue.Value.pathFollower = rmfield(newValue.Value.pathFollower,'feedforward');
    newValue.Value.pitchControl = rmfield(newValue.Value.pitchControl,'feedforward');
    setValue(dictEntry,newValue);
    expSolution = getValue(dictEntry);
    
    % remove the nested element from its bus and call the function
    removeNestedBusElement('pidControlParamBus',1);
    close(dictObj);
    CreatePdiBusParameter();

    % get the actual solution (the new value of the struct pdiParams) and
    % check if it is correct
    [~, ~, ~, value] = getPdiParamsValues();
    actualSolution = value.Value;
    verifyEqual(testCase,actualSolution,expSolution.Value);
end


function testRemoveDeeplyNestedElement(testCase)
    % edit the struct pdiParams so we can construct an expected solution
    [dictObj, ~, dictEntry, value] = getPdiParamsValues();
    newValue = value;
    newValue.Value.content0.content1.content2.content3.content4.content5.content6.content7.content8 = 0;
    setValue(dictEntry,newValue);
    expSolution = getValue(dictEntry);

    % remove bus element and call the function
    addDeepNesting();
    addNestedBusElement('added7', 'toDelete', ['false' 'none']);
    CreatePdiBusParameter()
    removeNestedBusElement('added7', 2);
    close(dictObj);
    CreatePdiBusParameter();

    % get the actual solution (the new value of the struct pdiParams) and
    % check if it is correct
    [~, ~, ~, value] = getPdiParamsValues();
    actualSolution = value.Value;
    verifyEqual(testCase,actualSolution,expSolution.Value);
end


function testAddTopLevelElement(testCase)
    % edit the struct pdiParams so we can construct an expected solution
    [dictObj, ~, dictEntry, value] = getPdiParamsValues();
    newValue = value;
    newValue.Value.added = 0;
    setValue(dictEntry,newValue);
    expSolution = getValue(dictEntry);

    % add bus element and call the function
    addNestedBusElement('pdiBus', 'added', ['false' 'none']);
    close(dictObj);
    CreatePdiBusParameter();

    % get the actual solution (the new value of the struct pdiParams) and
    % check if it is correct
    [~, ~, ~, value] = getPdiParamsValues();
    actualSolution = value.Value;
    verifyEqual(testCase,actualSolution,expSolution.Value);
end


function testAddNestedElement(testCase)
    % edit the struct pdiParams so we can construct an expected solution
    [dictObj, ~, dictEntry, value] = getPdiParamsValues();
    newValue = value;
    newValue.Value.verticalSpeed.added = 0;
    newValue.Value.altitude.added = 0;
    newValue.Value.pathFollower.added = 0;
    newValue.Value.pitchControl.added = 0;
    setValue(dictEntry,newValue);
    expSolution = getValue(dictEntry);

    % add bus element and call the function
    addNestedBusElement('pidControlParamBus', 'added', ['false' 'none']);
    close(dictObj);
    CreatePdiBusParameter();

    % get the actual solution (the new value of the struct pdiParams) and
    % check if it is correct
    [~, ~, ~, value] = getPdiParamsValues();
    actualSolution = value.Value;
    verifyEqual(testCase,actualSolution,expSolution.Value);
end


function testAddDeeplyNestedElement(testCase)
    % edit the struct pdiParams so we can construct an expected solution
    [dictObj, ~, dictEntry, value] = getPdiParamsValues();
    newValue = value;
    newValue.Value.content0.content1.content2.content3.content4.content5.content6.content7.content8 = 0;
    newValue.Value.content0.content1.content2.content3.content4.content5.content6.content7.testValue = 0;
    setValue(dictEntry,newValue);
    expSolution = getValue(dictEntry);

    % add bus element and call the function
    addDeepNesting();
    addNestedBusElement('added8', 'testValue', ['false' 'none']);
    close(dictObj);
    CreatePdiBusParameter();

    % get the actual solution (the new value of the struct pdiParams) and
    % check if it is correct
    [~, ~, ~, value] = getPdiParamsValues();
    actualSolution = value.Value;
    verifyEqual(testCase,actualSolution,expSolution.Value);
end




%% HELPER FUNCTIONS DEFINED BELOW


function removeNestedBusElement(enclosingBusName, position)
    dictObj = Simulink.data.dictionary.open('PdiExperiment.sldd');
    dataSectionObj = getSection(dictObj, 'Design Data');
    origBusRef = getEntry(dataSectionObj,enclosingBusName);
    origBus = getValue(origBusRef);
  
    elems = origBus.Elements;
    elems(position) = [];
    origBus.Elements = elems;
    deleteEntry(origBusRef);
    addEntry(dataSectionObj,enclosingBusName,origBus);
end


% name should be a string
% busInfo is an array with two values: [isBus busDataType]
function addNestedBusElement(enclosingBusName, name, busInfo)
    dictObj = Simulink.data.dictionary.open('PdiExperiment.sldd');
    dataSectionObj = getSection(dictObj, 'Design Data');
    origBusRef = getEntry(dataSectionObj, enclosingBusName);
    origBus = getValue(origBusRef);

    elems = origBus.Elements;
    index = length(elems) + 1;
    elems(index) = Simulink.BusElement;
    elems(index).Name = name;
    if busInfo(1) == 'true'
        elems(index).DataType = busInfo(2);
    end    
    origBus.Elements = elems;
    deleteEntry(origBusRef);
    addEntry(dataSectionObj,enclosingBusName,origBus);    
end


function [dictObj, dataSectionObj, dictEntry, value] = getPdiParamsValues()
    dictObj = Simulink.data.dictionary.open('PdiExperiment.sldd');
    dataSectionObj = getSection(dictObj, 'Design Data');
    dictEntry = getEntry(dataSectionObj, 'pdiParams');
    value = getValue(dictEntry);
end


% This function adds eight nested layers to the pdiBus so that we can test
% CreatePdiBusParameter on deeply nested buses
function addDeepNesting()
    dictObj = Simulink.data.dictionary.open('PdiExperiment.sldd');
    dataSectionObj = getSection(dictObj, 'Design Data');
    origBusRef = getEntry(dataSectionObj, 'pdiBus');
    origBus = getValue(origBusRef);

    elems8(1) = Simulink.BusElement;
    elems8(1).Name = 'content8';
    added8bus = Simulink.Bus;
    added8bus.Elements = elems8;
    addEntry(dataSectionObj, 'added8', added8bus);

    elems7(1) = Simulink.BusElement;
    elems7(1).Name = 'content7';
    elems7(1).DataType = 'Bus: added8';
    added7bus = Simulink.Bus;
    added7bus.Elements = elems7;
    addEntry(dataSectionObj, 'added7', added7bus);

    elems6(1) = Simulink.BusElement;
    elems6(1).Name = 'content6';
    elems6(1).DataType = 'Bus: added7';
    added6bus = Simulink.Bus;
    added6bus.Elements = elems6;
    addEntry(dataSectionObj, 'added6', added6bus);

    elems5(1) = Simulink.BusElement;
    elems5(1).Name = 'content5';
    elems5(1).DataType = 'Bus: added6';
    added5bus = Simulink.Bus;
    added5bus.Elements = elems5;
    addEntry(dataSectionObj, 'added5', added5bus);

    elems4(1) = Simulink.BusElement;
    elems4(1).Name = 'content4';
    elems4(1).DataType = 'Bus: added5';
    added4bus = Simulink.Bus;
    added4bus.Elements = elems4;
    addEntry(dataSectionObj, 'added4', added4bus);

    elems3(1) = Simulink.BusElement;
    elems3(1).Name = 'content3';
    elems3(1).DataType = 'Bus: added4';
    added3bus = Simulink.Bus;
    added3bus.Elements = elems3;
    addEntry(dataSectionObj, 'added3', added3bus);

    elems2(1) = Simulink.BusElement;
    elems2(1).Name = 'content2';
    elems2(1).DataType = 'Bus: added3';
    added2bus = Simulink.Bus;
    added2bus.Elements = elems2;
    addEntry(dataSectionObj, 'added2', added2bus);

    elems1(1) = Simulink.BusElement;
    elems1(1).Name = 'content1';
    elems1(1).DataType = 'Bus: added2';
    added1bus = Simulink.Bus;
    added1bus.Elements = elems1;
    addEntry(dataSectionObj, 'added1', added1bus);

    index = length(origBus.Elements) + 1;
    origBus.Elements(index) = Simulink.BusElement;
    origBus.Elements(index).Name = 'content0';
    origBus.Elements(index).DataType = 'Bus: added1';

    deleteEntry(origBusRef);
    addEntry(dataSectionObj,'pdiBus',origBus);
    CreatePdiBusParameter();
end



