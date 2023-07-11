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
%   Open the data dictionary
%

dictObj = Simulink.data.dictionary.open('PdiExperiment.sldd');

%
%   Grab the current pdiParams from the data dictionary so we can
%   Copy the PDI parameter values that have already been set from the
%   previous version of the bus to the new version of the bus.
%

dataSectionObj = getSection(dictObj, 'Design Data');
try
    origPdiParamRef = getEntry(dataSectionObj, 'pdiParams');
    origPdiParams = getValue(origPdiParamRef);

    %
    % Copy the parameters in the old parameter object to the new
    % parameter object.
    %

    pdiParams.Value = CopyParams(pdiParams.Value, origPdiParams.Value);
catch
    fprintf ("Unable to find pdiParams in data dictionary\n");
end

%
% Put the new pdiParams in the data dictionary replacing any value that
% might have previously been there.
%

replaceEntry(dictObj, 'pdiBusMatLabStruct', pdiBusMatLabStruct);
replaceEntry(dictObj, 'pdiParams', pdiParams);

%
%   Save and close the data dictionary.
%

dictObj.saveChanges();
close(dictObj);

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


function structNew = CopyParams(structNew, structOld)
%
% Copy Params takes two Simulink Parameters that are a duality of busses
% and structures and copies all of the common parameter values from the
% old bus/structure to the new bus/structure.
%
% structOld is a Simulink Parameter that consists of a structure that
% overlays a bus. The values of the fields of this structure need to be
% copied into the new structure.
% structNew is a new Simulink Parameter that consists of a structure that
% overlays a bus. Any fields that are common to structOld and structNew
% should be copied from structOld to structNew.
%
% returns - structNew, the new structure that has had the old parameter
% values copied to it.
%

% If the structOld is a structure that contains 'DataType' vairable, then
% obtain the fieldnames nested within 'Value' of both structOld and
% structNew. Otherwise obtain the fieldnames of the input structOld and
% structNew.
%
fieldNamesOld = fieldnames(structOld);
fieldNamesNew = fieldnames(structNew);

%
% Find the field names that are common to both structures.
%
commonFields = intersect(fieldNamesOld, fieldNamesNew);

%
% Loop through the common field names and copy the old values to the new
% parameter. If there is a nested structure then call CopyParams for the
% nest structure(s).
%
if size(commonFields, 1) > 0
    for currField = commonFields(:)'
        forOldField = getfield(structOld, currField{:});
        forNewField = getfield(structNew, currField{:});
        if ~isstruct(forOldField)
            structNew = setfield(structNew, ...
                currField{:}, forOldField);
        else
            structNew.(currField{:}) = CopyParams(...
                forNewField, forOldField);
        end
    end
end
