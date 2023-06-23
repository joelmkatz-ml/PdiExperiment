function CreatePdiBusParameter
%
%   This code is used to open the Design Data portion of a data dictionary 
%   and add a new Simulink Parameter that was derived from a structure that
%   was created based off of the pdiBus in the data dictionary.
%
%   Everything needed to access parameters from the data dictionary can be
%   found in the data dictionary. 
%
%   This script needs to be run any time that the pdiBus or one of its
%   components is changed to update the MatLab Structure and the data
%   dictionary. It does not need to be run every time the project starts.
%

scope = Simulink.data.DataDictionary('PdiExperiment.sldd');
pStruct = [];
dims = [1,1];
obj = 'pdiBus';
pdiBusMatLabStruct = Simulink.Bus.createMATLABStruct(obj, pStruct, dims, scope);

%
%   Create a SimulinkParameter from the structure. 
%   Set the type to the pdiBus that the structure was generated from.
%   Make the Storage Class Exported Global and the c name of the structure
%   be gPdiParams.
%

pdiParams = Simulink.Parameter(pdiBusMatLabStruct);
pdiParams.DataType = 'Bus: pdiBus';

pdiParams.CoderInfo.StorageClass = 'ExportedGlobal';
pdiParams.CoderInfo.Identifier = 'gPdiParams';

%
% Put the new pdiParams in the data dictionary replacing any value that
% might have previously been there.
%

dictObj = Simulink.data.dictionary.open('PdiExperiment.sldd');
replaceEntry(dictObj, 'pdiBusMatLabStruct', pdiBusMatLabStruct);
replaceEntry(dictObj, 'pdiParams', pdiParams);

%
%   Save the data dictionary.
%

dictObj.saveChanges();

clear pdiBusMatLabStruct pdiParams;


function replaceEntry(dictObj, entryName, entryValue)
%
%  Locate the Data Dictionary member entryName in a specified data 
%  dictionary section, dataSectionObj, and remove it if it is present. 
%  Then, add in the new member specified by entryName and entryValue.
%
%  dataSectionObj - an object pointing at the section of the data
%  dictObj - the dictionary object to search for the data
%  dictionary to look in to find a specified member.
%  entryName - the name of the data dictionary member to look for.
%  entryValue - the value to place in the data dictionary.
%

dataSectionObj = getSection(dictObj, 'Design Data');

try
pdiFound = getEntry(dataSectionObj, entryName);
catch
    fprintf ("Unable to find %s in data dictionary\n", entryName);
end

if exist('pdiFound', 'var')
    % fprintf("Parameter %s is in data dictionary\n", entryName);
    deleteEntry(pdiFound);
% else
%     fprintf("%s is not in Data Dictionary\n", entryName);
end

addEntry(dataSectionObj, entryName, entryValue);
