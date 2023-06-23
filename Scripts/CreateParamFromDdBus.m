function CreateParamFromDdBus

%
%   This code is used for control loop 3 in pdiExperiments.slx. It must be
%   run at startup and any time the bus definition is changed to update the
%   Workspace parameters that are used in the model.
%
%   This script needs to be run every time the project starts up and any
%   time the definition of the pdiBus or its components changes.
%
%   This allows strictly typing all parameters within a bus in the data
%   dictionary and allows the Bus Editor to be used to review the structure
%   and is better controlled than the previous solution. It does require
%   parameters in the Base Workspace.
%

scope = Simulink.data.DataDictionary('PdiExperiments.sldd');
pStruct = [];
dims = [1,1];
obj = 'pdiBus';
pdiBusMatLabStruct = Simulink.Bus.createMATLABStruct(obj, pStruct, dims, scope);
pdiParams3 = Simulink.Parameter(pdiBusMatLabStruct);
Simulink.Bus.createObject(pdiBusMatLabStruct);

pdiBus3 = slBus1;
clear slBus1;
pdiParams3.DataType = 'Bus: pdiBus3';
