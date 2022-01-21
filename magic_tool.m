%magic_tool: runs a GUI for a tool to turn preprocessed 4D flow data into
%quantitative output.

% Syntax: 
% optional: cd to your subject directory for ease of file access
% required: add matlab_nu to path
% then type magic_tool

% Inputs: 
%mag_struct - magnitude mrStruct
%vel_struct - velocity mrStruct
%something to use as segemntation - may be DICOM set (PCMRA), Mimics output
%optional: additional masks, saved branchStruct or planeStruct, normal
%control data

% Outputs: 
%flowdata.xlsx - time-averaged planewise data
%flowdata_transient.xlsx - time-resolved planewise data
%flow_parameters.xlsx - vesselwise data
%graphProperties.mat - flow distribution network graph

% Authors:% Last revision: dateoflastrevision
%Alireza Vali
%Maria Aristova - maria.aristova@gmail.com
%Yue Ma
%Susanne Schnell
%Patrick Winter

% Developer Notes:
%Bugs: 
%fnder cannot be used with structs in r2020?
%Machine Learning segmentation not available off-network

%To-do: make networkDialog standalone, allow initializing project with
%mrStruct mask,allow initializing with branch or plane struct
%------------- BEGIN CODE --------------

function varargout = magic_tool(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @magic_tool_OpeningFcn, ...
                   'gui_OutputFcn',  @magic_tool_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before magic_tool is made visible.
function magic_tool_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
handles.coord = [];
guidata(hObject, handles);
set(handles.axes1,'XTick',[], 'XTickLabel',[]);
set(handles.axes1,'YTick',[], 'YTickLabel',[]);
set(handles.axes2,'XTick',[], 'XTickLabel',[]);
set(handles.axes2,'YTick',[], 'YTickLabel',[]);
set(handles.axes3,'XTick',[], 'XTickLabel',[]);
set(handles.axes3,'YTick',[], 'YTickLabel',[]);
set(handles.axes4,'XTick',[], 'XTickLabel',[]);
set(handles.axes4,'YTick',[], 'YTickLabel',[]);
set(handles.axes2D,'XTick',[], 'XTickLabel',[]);
set(handles.axes2D,'YTick',[], 'YTickLabel',[]);
set(handles.axes3D,'XTick',[], 'XTickLabel',[]);
set(handles.axes3D,'YTick',[], 'YTickLabel',[]);
initializeGUI(handles);
set(handles.tab2Panel, 'Position', get(handles.tab1Panel, 'Position'));
set(handles.tab3Panel, 'Position', get(handles.tab1Panel, 'Position'));
set(handles.plotPanel,'Position', get(handles.cutPlanePanel, 'Position'));
set(handles.segThreshPanel, 'Visible', 'off');
set(handles.segROIPanel, 'Visible', 'off');
set(handles.segRGPanel, 'Visible', 'off');
set(handles.seg_Selection, 'Visible', 'off');
set(handles.cropPanel, 'Visible', 'off');
handles.segROIPanel.Position(1:2) = handles.segThreshPanel.Position(1:2)+ ...
    (handles.segThreshPanel.Position(3:4) - handles.segROIPanel.Position(3:4));
handles.segRGPanel.Position(1:2) =  handles.segThreshPanel.Position(1:2)+ ...
    (handles.segThreshPanel.Position(3:4) - handles.segRGPanel.Position(3:4));
handles.cropPanel.Position(1:2) =  handles.segThreshPanel.Position(1:2)+ ...
    (handles.segThreshPanel.Position(3:4) - handles.cropPanel.Position(3:4));
handles.registerPanel.Position(1:2) =  handles.segThreshPanel.Position(1:2)+ ...
    (handles.segThreshPanel.Position(3:4) - handles.registerPanel.Position(3:4));
set(handles.isoSurfaceMenu, 'min', 0, 'max', 2);
set(handles.isoSurfaceMenu, 'Value', []);


function output = initializeGUI(handles)
global coord;
output = 1;
if isappdata(0, 'project') && ~isempty(getappdata(0, 'project'))
    answer = questdlg('The current project is not saved do you wish to save it?', '', 'Yes', 'No', 'Cancel', 'Yes');
    switch answer
        case 'Yes'
            output = 0;
            %This option should just save the segmentation and branch or
            %planestruct
            return;
        case 'No'
            prj = getappdata(0,'project');
            prj.remove();
            setappdata(0, 'project', []);
        case 'Cancel'
            output = 0;
            return;
    end
end
cla(handles.axes1);
cla(handles.axes2);
cla(handles.axes3);
cla(handles.axes4);
cla(handles.axes2D);
cla(handles.axes3D);

hold(handles.axes4, 'all');
coord = [quiver3(handles.axes4,0,0,0,1,0,0,'r'), ...
         quiver3(handles.axes4,0,0,0,0,1,0,'b'), ...
         quiver3(handles.axes4,0,0,0,0,0,1,'g')];
hold(handles.axes4, 'off');

set(coord, 'Visible', 'off', 'LineWidth', 1.5, 'MaxHeadSize', 0.75);
axis off equal;

if isappdata(0, 'selectedVessels')
    rmappdata(0, 'selectedVessels');
end

set(findobj(handles.fileMenu.Children), 'Enable', 'off');
set(findobj(handles.toolsMenu.Children), 'Enable', 'off');
set(findobj(handles.analysisMenu.Children), 'Enable', 'off');
set(findobj(handles.resultMenu.Children), 'Enable', 'off');
set(handles.DispItem, 'Enable', 'off', 'Value', 1);
set(handles.copyVolumeBut, 'Enable', 'off');
set(handles.deleteVolumeBut, 'Enable', 'off');
set(handles.dispBox, 'Visible', 'off', 'Value', 0);
set(handles.DispSlices, 'Visible', 'off', 'Value', 0);
set(handles.Disp3D, 'Visible', 'off', 'Value', 0);
set(handles.isoSurfacePanel, 'Visible', 'off');
set(handles.TransSlider, 'Visible', 'off');
set(handles.TransText, 'Visible', 'off');
set(handles.seg_ImageSeries, 'String', []);
set(handles.seg_Masks, 'String', {'m1', 'm2'}, 'Value', 1);
set(handles.BaseVolumeMenu, 'String', {'', ''}, 'Value', 1);
set(handles.tab2Panel, 'Visible', 'off');
set(handles.tab3Panel, 'Visible', 'off');
set(handles.tab1Panel, 'Visible', 'on');
set(handles.EditVesselBut, 'Enable', 'off');
set(handles.plotBut, 'Enable', 'off');
set(handles.DispCP, 'Visible', 'off', 'Value', 0);
set(handles.DispLabels, 'Visible', 'off', 'Value', 0);
set(handles.DispCL, 'Visible', 'off', 'Value', 0);
set(handles.dispCutPlaneBut, 'Visible', 'off');
set(handles.cutplanePanel, 'Visible', 'off');
set(handles.dispCutPlane, 'Enable', 'off');
set(handles.dispCutPlane, 'Visible', 'off');
set(handles.cutPlanePanel, 'Visible', 'off');
set(handles.dispPointCloud, 'Visible', 'off');
set(handles.plotPanel, 'Visible', 'off');
set(handles.DispCutPlot, 'Value', 0);
set(handles.cPlaneLen, 'String', '20.0');
set(handles.cPlaneWid, 'String', '20.0');
set(handles.cPlaneRes, 'String', '0.25');
set(handles.cPlaneDist, 'String', '1.0');
set(handles.NameEdit, 'Visible','off');

% labels = {  'LACA'; 'RACA'; 'LMCA'; 'RMCA'; 'LICA'; 'RICA'; 'LPCA'; ...
%             'RPCA'; 'BA'; 'LTS'; 'RTS'; 'SSS'; 'STR'; 'LPCOM'; ...
%             'RPCOM'; 'LPPCA'; 'RPPCA'; 'LSCA'; 'RSCA'; 'LVA'; 'RVA'};

labels = {  'LACA'; 'RACA'; 'LMCA'; 'RMCA'; 'LICA'; 'RICA'; 'LPCA'; 'RPCA'; 'BA'; ...
            'LMCA-M1'; 'LMCA-M2'; 'LMCA-M3'; 'LMCA-M4'; ...
            'RMCA-M1'; 'RMCA-M2'; 'RMCA-M3'; 'RMCA-M4'; ...
            'LICA-C1'; 'LICA-C2-C4'; 'LICA-C5-C7'; ...
            'RICA-C1'; 'RICA-C2-C4'; 'RICA-C5-C7'; ...
            'LTS'; 'RTS'; 'SSS'; 'STR'; ...
            'LPCOM'; 'RPCOM'; 'LPPCA'; 'RPPCA'; 'LSCA'; 'RSCA'; ...
            'LVA'; 'RVA'};

set(handles.nameMenu, 'String', labels);
set(handles.bodyPartMenu, 'Value', 1);
set(handles.RRCheckBox, 'Value', 0);
set(handles.RRValue, 'Visible', 'off');
set(handles.RRValue, 'String', '');
set(handles.msUnitTxt, 'Visible', 'off');            
cellfun(@(x) set(findobj(handles.fileMenu.Children, 'Tag', x), 'Enable', 'on'), ...
    {'newProjectAction', 'loadProjectAction'});

function setup_GUI(handles, cProject)
global coord;
setappdata(0, 'view_lim', [ -1, cProject.imageSeries{1}.fov(2,2); ...
                            -1, cProject.imageSeries{1}.fov(1,2); ...
                            -1, cProject.imageSeries{1}.fov(3,2)]);
set(handles.thresholdSlider, 'Value', 3);
set(handles.thresholdSlider, 'min', 0.1);
set(handles.ThresholdDisplay, 'String', handles.thresholdSlider.Value);
set(handles.thresholdValueTxt, 'String', handles.thresholdSlider.Value);
sliderstepmultiplier = 0.25;
set(handles.thresholdSlider, 'SliderStep', [sliderstepmultiplier/(get(handles.thresholdSlider, 'max')-1), ...
    sliderstepmultiplier/(get(handles.thresholdSlider, 'max')-1) ]);

currentImageSize = size(cProject.cImage.data); 
set(handles.slider1, 'max', currentImageSize(2));
set(handles.slider2, 'max', currentImageSize(1));
set(handles.slider3, 'max', currentImageSize(3));

set(handles.slider1, 'SliderStep', [1/get(handles.slider1, 'max'),0.075]);
set(handles.slider2, 'SliderStep', [1/get(handles.slider2, 'max'),0.075]);
set(handles.slider3, 'SliderStep', [1/get(handles.slider3, 'max'),0.075]);

set(handles.TransSlider, 'value', 1);


magic_tool_update(handles,'image','axes1', ...
    squeeze(cProject.cImage.data(:,floor(currentImageSize(2)/2),:)));

magic_tool_update(handles,'image','axes2', ...
    imrotate(squeeze(cProject.cImage.data(floor(currentImageSize(1)/2),:,:)),90));

magic_tool_update(handles,'image','axes3', ...
    squeeze(cProject.cImage.data(:,:,floor(currentImageSize(3)/2))));

set(handles.X_cord, 'String', num2str(floor(currentImageSize(2)/2)));
set(handles.Y_cord, 'String', num2str(floor(currentImageSize(1)/2)));
set(handles.Z_cord, 'String', num2str(floor(currentImageSize(3)/2)));

set(handles.slider1, 'Value', floor(currentImageSize(2)/2));
set(handles.slider2, 'Value', floor(currentImageSize(1)/2));
set(handles.slider3, 'Value', floor(currentImageSize(3)/2));

update_volumeLists(handles, cProject);
set(handles.DispItem, 'Enable', 'on');
set(handles.copyVolumeBut, 'Enable', 'on');
set(handles.deleteVolumeBut, 'Enable', 'on');
set(handles.dispBox, 'Visible', 'on');
set(handles.DispSlices, 'Visible', 'on');
set(handles.Disp3D, 'Visible', 'on', 'Value', 1);
set(handles.isoSurfacePanel, 'Visible', 'on');
set(handles.isoSurfaceMenu, 'Value', 1);

magic_tool_update(handles, 'isosurface');
set(coord, 'Visible', 'on', 'AutoScaleFactor', max(cProject.cImage.fov(:,2))/12);

set(findobj(handles.fileMenu.Children), 'Enable', 'on');
cellfun(@(x) set(findobj(handles.fileMenu.Children, 'Tag', x), 'Enable', 'off'), ...
    {'exportCenterlineFileAction', 'exportBranchFileAction', 'exportPlaneFileAction', ...
    'importBranchFileAction', 'importPlaneFileAction'});
set(findobj(handles.toolsMenu.Children), 'Enable', 'on');
set(findobj(handles.analysisMenu.Children, 'Tag', 'extractCPAction'), 'Enable', 'on');
set(findobj(handles.visualizationAction.Children, 'Tag', 'flowDirectionAction'), 'Enable', 'off');


% Helper function to set up the list of images and masks
function update_volumeLists(handles, cProject, fresh)
set(handles.DispItem, 'String', cProject.volumeList());
set(handles.seg_Masks, 'String', cProject.maskList());
set(handles.isoSurfaceMenu, 'String', cProject.maskList());
set(handles.BaseVolumeMenu, 'String', [{''}, cProject.imageList()]);
set(handles.seg_Masks, 'String', [{''}, cProject.maskList()]);
set(handles.maskROIMenu, 'String', [{''}, cProject.maskList()]);
set(handles.seg_Masks, 'Value', 1);
set(handles.seg_ImageSeries, 'String', []);

if isequal(handles.roiDetectionSelect.SelectedObject.Tag, handles.segmentDetection.Tag)
    set(handles.maskROIMenu, 'String', [{''}, cProject.imageList()]);
else
    set(handles.maskROIMenu, 'String', [{''}, cProject.maskList()]);    
end
set(handles.maskROIMenu, 'Value', 1);
if exist('fresh', 'var') && fresh==1
    set(handles.DispItem, 'Value', fresh);
    set(handles.seg_Masks, 'Value', fresh);
end

% --- Outputs from this function are returned to the command line.
function varargout = magic_tool_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

% --------------------------------------------------------------------
function fileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to fileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function newProjectAction_Callback(hObject, eventdata, handles) %runs loadDialog.m
if initializeGUI(handles)
    Data = loadData(); %Makes input arguments to Project constructor as varargout
    if Data{1}
        h = busydlg(' ', 'Creating new project...');
        try
            cProject = Project(Data{:});
            setappdata(0, 'project', cProject);
            setup_GUI(handles, cProject);
        catch ME
            errordlg({'The project creation failed!', 'Error message:', ME.message});
            for i=1:length(Data)
                if isa(Data{i}, 'handle')
                    Data{i}.remove();
                end
            end            
        end        
        close(h);
    end
    %Set a flag in appdata
    setappdata(0, 'quickLoad', 0); %MA20200327
end

% --------------------------------------------------------------------
function loadProjectAction_Callback(hObject, eventdata, handles) %MA20200327
%loadData as before
if initializeGUI(handles)
    Data = loadData(); %Makes input arguments to Project constructor as varargout
    if Data{1}
        h = busydlg(' ', 'Creating new project...');
        try
            cProject = Project(Data{:});
            setappdata(0, 'project', cProject);
            setup_GUI(handles, cProject);
        catch ME
            errordlg({'The project creation failed!', 'Error message:', ME.message});
            for i=1:length(Data)
                if isa(Data{i}, 'handle')
                    Data{i}.remove();
                end
            end            
        end        
        close(h);
    end
    %Set a flag in appdata
    quickLoad = 1;
    setappdata(0, 'quickLoad', quickLoad);
    
    %Extract center points without smoothing for whatever segmentation is first
    extractCPAction_Callback(hObject, eventdata, handles) 
    
    %Find vessels with spur length 6
    findVesselsAction_Callback(hObject, eventdata, handles)
    
    %Import branch or plane file
    %Ask
    answer = questdlg('What do you want to load?', 'input file type', 'branchStruct', 'planeStruct', 'Cancel', 'planeStruct');
    %Import
    switch answer
        case 'branchStruct'
            %Load branchStruct
            importBranchFileAction_Callback(hObject, eventdata, handles)

        case 'planeStruct'
            %Load planeStruct
            importPlaneFileAction_Callback(hObject, eventdata, handles)
    end

    %Reset flag in appdata because quickload is done
    quickLoad = 0;
    setappdata(0, 'quickLoad', quickLoad);
    
    %Maybe one day there will be an efficient save function for entire projects
    %and then we can replace with this
    % loadedData = load(fullfile(filePath, fileName));
    % prj = loadedData.prj;
    % setappdata(0, 'project', prj);
    % setup_GUI(handles, prj);
end

% --------------------------------------------------------------------
function saveProjectAction_Callback(hObject, eventdata, handles)
prj = getappdata(0, 'project');
h = waitbar(0.5, 'saving project ...');
save(fullfile(prj.workingDirectory, prj.name), 'prj');
waitbar(1, h, 'saving project ...');
close(h);

% --------------------------------------------------------------------
function saveProjectAsAction_Callback(hObject, eventdata, handles)
cProject = getappdata(0, 'project');
[fileName, filePath] = uiputfile('*.mat', 'save project as', ...
    fullfile(cProject.workingDirectory, cProject.name));
if ~isequal(fileName, 0) && ~isequal(filePath, 0)
    h = waitbar(0.5, 'saving project ...');
    save(fullfile(filePath, fileName), 'prj');
    waitbar(1, h, 'saving project ...');
    close(h);
end

% --------------------------------------------------------------------
function importImageSeriesAction_Callback(hObject, eventdata, handles)
prj = getappdata(0, 'project');

%keyboard
[imgStruct, DICOMFile, dataName] = importImageDialog();

if ~isempty(DICOMFile) && ~isempty(dataName)
    i = find(DICOMFile == '\', 1, 'last');
    [newDICOM_data, newDICOM_box, newDICOM_res] = readDicomSeries(DICOMFile(i+1:end), DICOMFile(1:i));
    
    %%%% newDICOM_data = flip(newDICOM_data,3); % this is here because TOFs
    %%%% were coming in upside down. Leaving only if uncomment desired
    prj.add_imageSeries (dataName, newDICOM_data, newDICOM_box, newDICOM_res, 1, 'dicom');
    update_volumeLists(handles, prj);
    msgbox('Data Imported!');

elseif ~isempty(imgStruct) && ~isempty(dataName)
    importedData = matfile(imgStruct);
    importedData = importedData.mrStruct;
    if isequal(importedData.dim11, 'unused')
        FOV = [zeros(3,1), (importedData.vox(1:3).*size(importedData.dataAy))'];
    else
        %keyboard
        
        %pwinter am 09.12.21
        mystrsplit = @(str,delim) regexp(str,regexptranslate('escape',delim),'split');
        FOV = reshape(cellfun(@str2double, mystrsplit(importedData.dim11, ',')), 3, 2);
        
        %FOV = reshape(cellfun(@str2double, strsplit(importedData.dim11, ',')), 3, 2);
    end
    if isequal(importedData.dim10, 'unused')
        importedData.interpFactor=1;
    else
        importedData.interpFactor=str2double(importedData.dim10);
    end
    prj.add_imageSeries (dataName, importedData.dataAy, FOV, importedData.vox(1:3), ...
        importedData.interpFactor, 'mrStruct');
    update_volumeLists(handles, prj);
    msgbox('Data Imported!');
end

% --------------------------------------------------------------------
function importMaskAction_Callback(hObject, eventdata, handles)
prj = getappdata(0, 'project');
[maskStruct, maskFile, allFile, maskName] = importMaskDialog;

if ~isempty(maskStruct)
    importedMask = matfile(maskStruct);
    f = fields(importedMask);
    importedMask = importedMask.(f{cellfun(@(x) contains(x, 'mrstruct', 'ignoreCase', true), fields(importedMask))});        
elseif ~isempty(maskFile) && ~isempty(allFile)
    [file, path] = uigetfile(prj.workingDirectory, 'Please select mag_struct.mat file');
    if ~isequal(file, 0) && ~isequal(path, 0)
        h = busydlg(' ', 'Importing mask...');
        [~,~,~,importedMask] = mimics_to_mrstruct(allFile,maskFile, ...
            fullfile(path, file), 0,0);
        close(h);
    end
else
    importedMask = [];
end

if ~isempty(importedMask)
    if isequal(importedMask.dim11, 'unused')
        maskFOV = [zeros(3,1), (importedMask.vox(1:3).*size(importedMask.dataAy))'];
    else
        
        
        %Pwinter am 25.11.2021: strsplit seems to not work anymore
        %maskFOV = reshape(cellfun(@str2double, strsplit(importedMask.dim11, ',')), 3, 2);
        mystrsplit = @(str,delim) regexp(str,regexptranslate('escape',delim),'split');
        %Ende von Pwinter am 25.11.2021
        
        maskFOV = reshape(cellfun(@str2double, mystrsplit(importedMask.dim11, ',')), 3, 2);
    end
    if isequal(importedMask.dim10, 'unused')
        importedMask.interpFactor=1;
    else
        importedMask.interpFactor=str2double(importedMask.dim10);
    end
    prj.add_mask(Mask(maskName, 1, [], 'IMPORTED', importedMask.dataAy, ...
            importedMask.vox(1:3), maskFOV, importedMask.edges, importedMask.interpFactor));

    update_volumeLists(handles, prj);
    msgbox('Mask Imported!');
end

% --------------------------------------------------------------------
%Add mask and volume together so that the mask has a parent volume and can
%be the moving mask in registration MA20210815
function importMaskAndVolumeAction_Callback(hObject, eventdata, handles)
prj = getappdata(0, 'project');
[imgStruct, DICOMFile, dataName, maskStruct, maskFile, allFile, maskName] = importMaskImageDialog();

%Import volume first
if ~isempty(DICOMFile) && ~isempty(dataName)
    i = find(DICOMFile == '\', 1, 'last');
    [newDICOM_data, newDICOM_box, newDICOM_res] = readDicomSeries(DICOMFile(i+1:end), DICOMFile(1:i));
    
    prj.add_imageSeries (dataName, newDICOM_data, newDICOM_box, newDICOM_res, 1, 'dicom');
    update_volumeLists(handles, prj);
    msgbox('Volume Imported!');

elseif ~isempty(imgStruct) && ~isempty(dataName)
    importedData = matfile(imgStruct);
    importedData = importedData.mrStruct;
    if isequal(importedData.dim11, 'unused')
        FOV = [zeros(3,1), (importedData.vox(1:3).*size(importedData.dataAy))'];
    else
        FOV = reshape(cellfun(@str2double, strsplit(importedData.dim11, ',')), 3, 2);
    end
    if isequal(importedData.dim10, 'unused')
        importedData.interpFactor=1;
    else
        importedData.interpFactor=str2double(importedData.dim10);
    end
    prj.add_imageSeries (dataName, importedData.dataAy, FOV, importedData.vox(1:3), ...
        importedData.interpFactor, 'mrStruct');
    update_volumeLists(handles, prj);
    msgbox('Volume Imported!');
end

%Try to find mask
if ~isempty(maskStruct)
    importedMask = matfile(maskStruct);
    f = fields(importedMask);
    importedMask = importedMask.(f{cellfun(@(x) contains(x, 'mrstruct', 'ignoreCase', true), fields(importedMask))});        
elseif ~isempty(maskFile) && ~isempty(allFile)
    [file, path] = uigetfile(prj.workingDirectory, 'Please select mag_struct.mat file');
    if ~isequal(file, 0) && ~isequal(path, 0)
        h = busydlg(' ', 'Importing mask...');
        [~,~,~,importedMask] = mimics_to_mrstruct(allFile,maskFile,fullfile(path, file), 0,0);
        close(h);
    end
else
    importedMask = [];
end

%Import mask but pass parent and parentname
if ~isempty(importedMask)
    if isequal(importedMask.dim11, 'unused')
        maskFOV = [zeros(3,1), (importedMask.vox(1:3).*size(importedMask.dataAy))'];
    else
        maskFOV = reshape(cellfun(@str2double, strsplit(importedMask.dim11, ',')), 3, 2);
    end
    if isequal(importedMask.dim10, 'unused')
        importedMask.interpFactor=1;
    else
        importedMask.interpFactor=str2double(importedMask.dim10);
    end
    %Get the associated volume
    parentVol = prj.find_volume(dataName, 'Image');
    %Add mask
    prj.add_mask(Mask(maskName, 1, parentVol, dataName, importedMask.dataAy, ...
            importedMask.vox(1:3), maskFOV, importedMask.edges, importedMask.interpFactor));

    update_volumeLists(handles, prj);
    msgbox('Mask Imported!');
end

% --------------------------------------------------------------------
function importMatrixAction_Callback(hObject, eventdata, handles)
%Get source file
prj = getappdata(0, 'project');
[rotMatFile, rotMatPath] = uigetfile(fullfile(prj.workingDirectory, ['rotationMatrix.mat']) , 'Save rotation matrix as');
rotMatFile = fullfile(rotMatPath, rotMatFile);
tempStruct = load(rotMatFile);
worldmat = tempStruct.worldmat;
%Get a name for the matrix
prompt = {'Enter matrix name:'};
dlgtitle = 'Rotation matrix';
dims = [1 35];
definput = {'rotationMatrix'};
rotMatName = inputdlg(prompt,dlgtitle,dims,definput);
%Add to project
prj.add_rotationMatrix(rotMatName{1}, worldmat);

% --------------------------------------------------------------------
function importBranchFileAction_Callback(hObject, eventdata, handles)
prj = getappdata(0, 'project');
quickLoad = getappdata(0, 'quickLoad'); %MA20200327
%Get file location
[file, path] = uigetfile('*.mat', 'Select the branch struct file', prj.workingDirectory);
if ~isequal(path, 0) && ~isequal(file, 0)
    savedfile = fullfile(path,file); 
    BSFile = matfile(savedfile);
    branchStruct = BSFile.branchStruct;
    
    if isequal(get(branchStruct(1).lineHandle, 'Tag'),'') || ~isfield(branchStruct, 'visibility')
        answer = questdlg(['The branch file has been created with the old version of this program and cannot be used. ' ...
            'Do you like to update it to the new version?'], 'Old Version Branch File','Yes', 'No', 'Yes');
        if strcmp(answer, 'Yes')
            for i=1:length(branchStruct)
                set(branchStruct(i).lineHandle, 'Tag', sprintf('ID_%d_CL', branchStruct(i).id));
                branchStruct(i).visibility = 'on';
            end
            save(fullfile(path,file),'branchStruct');
        else
            return;
        end
    end
    m = length(branchStruct);
    
    %Option to replace or add
    if quickLoad == 0 %Normal operation
        answer = questdlg('Replace current or add on?','','Replace', 'Add','Replace');    
    else
        answer = 'Replace'; %Always replace with quickLoad
    end
    
    switch answer
    case 'Replace'
        prj.removeBranch('All'); % remove the old ones
        for i = 1:m
            prj.branches{i} =               Branch();
            prj.branches{i}.id =            branchStruct(i).id;
            prj.branches{i}.name =          branchStruct(i).name;
            prj.branches{i}.pList =         branchStruct(i).pList;
            prj.branches{i}.pInd =          branchStruct(i).pInd;
            prj.branches{i}.fitLine =       branchStruct(i).fitLine;
            prj.branches{i}.lineHandle =    branchStruct(i).lineHandle;
            prj.branches{i}.visibility =    branchStruct(i).visibility;
        end
    case 'Add'        
        n = length(prj.branches);
        newBranch = 0;
        for i = 1:m %Go through all elements of new branchStruct
            if ~isempty(branchStruct(i).name) && ...
               ~any(cellfun(@(x) isequal(x.pInd, branchStruct(i).pInd), prj.branches)) %make sure the branch is not empty
                newBranch = newBranch+1;
                prj.branches{newBranch+n} =               Branch();
                prj.branches{newBranch+n}.id =            newBranch+n;
                prj.branches{newBranch+n}.name =          branchStruct(i).name;
                prj.branches{newBranch+n}.pList =         branchStruct(i).pList;
                prj.branches{newBranch+n}.pInd =          branchStruct(i).pInd;
                prj.branches{newBranch+n}.fitLine =       branchStruct(i).fitLine;
                prj.branches{newBranch+n}.lineHandle =    branchStruct(i).lineHandle;
                prj.branches{newBranch+n}.visibility =    branchStruct(i).visibility;
            end
        end
    end
    
    magic_tool_update(handles, 'centerline', 0);
    magic_tool_update(handles,'label');
    updatelist(handles);
    
    if strcmp(handles.cutplanePanel.Visible, 'on')
        set(handles.cutplanePanel, 'Visible', 'off');
        handles.DispCutPlot.Value = 0;
        set(handles.dispCutPlaneBut, 'Visible', 'off');
        handles.dispPointCloud.Value = 0;
        set(handles.dispPointCloud, 'Visible', 'off');
        handles.dispCutPlane.Value = 0;
        set(handles.dispCutPlane, 'Visible', 'off');
        set(handles.cutPlanePanel, 'Visible', 'off');
        delete(findobj(handles.axes4.Children, 'Tag', 'pointcloud'));
        delete(findobj(handles.axes4.Children, '-regexp','Tag','_p'));
        set(handles.plotBut, 'Enable', 'off');
        set(handles.tab3Panel, 'Visible', 'off');
        set(handles.tab2Panel, 'Visible', 'on');
    end
    
end


% --------------------------------------------------------------------
function importPlaneFileAction_Callback(hObject, eventdata, handles)
prj = getappdata(0, 'project');
quickLoad = getappdata(0, 'quickLoad'); %MA20200327
[file, path] = uigetfile('*.mat', 'Select the plane struct file', prj.workingDirectory);
if ~isequal(path, 0) && ~isequal(file, 0)
    savedfile = fullfile(path,file); 
    PSFile = matfile(savedfile);
    %This is the new planestruct, get some properties
    planeStruct = PSFile.planeStruct;
    m = length(planeStruct); 
    %Individual plane tags
    if ~isfield(planeStruct, 'cPlaneTags') 
        newTags = 1;
    else
        newTags = 0;
    end
    %Try to get RR interval from user
    switch questdlg('Use R-R interval?','','Yes', 'No', 'Yes')        
        case 'Yes'
            set(handles.RRCheckBox, 'Value', 1);
            magic_tool('RRCheckBox_Callback',hObject,eventdata,guidata(hObject));
    end
    
    %Option to replace or add
    if quickLoad == 0 %Normal operation
        answer = questdlg('Replace current or add on?','','Replace', 'Add','Replace');    
    else
        answer = 'Replace'; %Always replace with quickLoad
    end
    
    switch answer      
    case 'Replace'
        prj.removeBranch('All'); % remove the old ones
        
        for i = 1:m
            newindex = i;
            prj.branches{newindex} =               Branch();
            prj.branches{newindex}.id =            planeStruct(i).id;
            prj.branches{newindex}.name =          planeStruct(i).name;
            prj.branches{newindex}.pList =         planeStruct(i).pList;
            prj.branches{newindex}.pInd =          planeStruct(i).pInd;
            prj.branches{newindex}.fitLine =       planeStruct(i).fitLine;
            prj.branches{newindex}.lineHandle =    planeStruct(i).lineHandle;
            prj.branches{newindex}.visibility =    planeStruct(i).visibility;
            prj.branches{newindex}.cPoints =       planeStruct(i).cPoints;
            prj.branches{newindex}.planeDim =      planeStruct(i).planeDim;
            prj.branches{newindex}.planeRes =      planeStruct(i).planeRes;
            prj.branches{newindex}.cRotate =       planeStruct(i).cRotate;
            prj.branches{newindex}.cNormal =       planeStruct(i).cNormal;
            prj.branches{newindex}.cPlane =        cell(size(prj.branches{newindex}.cPoints, 1), 5);
            if newTags == 1
                %make tags if they are not provided
                prj.branches{newindex}.cPlaneTags = repmat([1 0], size(prj.branches{newindex}.cPoints, 1), 1); %includeData = 1; savePlaneData = 0
            elseif newTags == 0
                %copy tags if they are provided
                prj.branches{newindex}.cPlaneTags = planeStruct(i).cPlaneTags; 
            end
            for j=1:size(prj.branches{newindex}.cPoints, 1)
                %copy plane information
                prj.branches{newindex}.cPlane{j,1} = planeStruct(i).cPlane{j}; %coordinates
                prj.branches{newindex}.cPlane{j,2} = zeros(size(planeStruct(i).polyPoints{j},1), 5);
                prj.branches{newindex}.cPlane{j,2}(:,[4,5]) = planeStruct(i).polyPoints{j};
                prj.branches{newindex}.cPlane{j,5} = zeros(size(planeStruct(i).breakPoints{j},1), 5);
                prj.branches{newindex}.cPlane{j,5}(:,[4,5]) = planeStruct(i).breakPoints{j};
            end
        end
    case 'Add'        
        n = length(prj.branches); %this is the old planestruct
        newBranch = 0;
        for i = 1:m %Go through all elements of new branchStruct
            if ~isempty(planeStruct(i).name) && ~any(cellfun(@(x) isequal(x.pInd, planeStruct(i).pInd), prj.branches)) %make sure the branch is not empty, not redundant
                newBranch = newBranch+1;
                newindex = newBranch+n;
                prj.branches{newindex} =               Branch();
                prj.branches{newindex}.id =            newBranch+n;
                prj.branches{newindex}.name =          planeStruct(i).name;
                prj.branches{newindex}.pList =         planeStruct(i).pList;
                prj.branches{newindex}.pInd =          planeStruct(i).pInd;
                prj.branches{newindex}.fitLine =       planeStruct(i).fitLine;
                prj.branches{newindex}.lineHandle =    planeStruct(i).lineHandle;
                prj.branches{newindex}.visibility =    planeStruct(i).visibility;
                prj.branches{newindex}.cPoints =       planeStruct(i).cPoints;
                prj.branches{newindex}.planeDim =      planeStruct(i).planeDim;
                prj.branches{newindex}.planeRes =      planeStruct(i).planeRes;
                prj.branches{newindex}.cRotate =       planeStruct(i).cRotate;
                prj.branches{newindex}.cNormal =       planeStruct(i).cNormal;
                prj.branches{newindex}.cPlane =        cell(size(prj.branches{newBranch+n}.cPoints, 1), 5);
                if newTags == 1
                    %make tags if they are not provided
                    prj.branches{newindex}.cPlaneTags = repmat([1 0], size(prj.branches{newindex}.cPoints, 1), 1); %includeData = 1; savePlaneData = 0
                elseif newTags == 0
                    %copy tags if they are provided
                    prj.branches{newindex}.cPlaneTags = planeStruct(i).cPlaneTags; 
                end
                for j=1:size(prj.branches{newindex}.cPoints, 1)
                    %copy plane information
                    prj.branches{newindex}.cPlane{j,1} = planeStruct(i).cPlane{j}; %coordinates
                    prj.branches{newindex}.cPlane{j,2} = zeros(size(planeStruct(i).polyPoints{j},1), 5);
                    prj.branches{newindex}.cPlane{j,2}(:,[4,5]) = planeStruct(i).polyPoints{j};
                    prj.branches{newindex}.cPlane{j,5} = zeros(size(planeStruct(i).breakPoints{j},1), 5);
                    prj.branches{newindex}.cPlane{j,5}(:,[4,5]) = planeStruct(i).breakPoints{j};
                end
            end
        end
    end

    magic_tool_update(handles, 'centerline', 0);
    magic_tool_update(handles,'label');
    updatelist(handles);  
    try
        prj.update_dataSets(handles.DispItem.String);
        dataList = datadlg();
        if ~isempty(dataList)        
            prj.update_dataSets(dataList);
            isImported = 1;
            clusterMode = 1;
            tagsMode = 1; %Include tags when importing (this will not be used in import pathway)
            roiOrigin = [];
            magic_tool_update(handles, 'cutplane', roiOrigin, isImported, clusterMode, tagsMode);
            prj.backup_clear();
            set(handles.undoBut, 'Enable', 'off');
            set(handles.dispCutPlaneBut, 'Visible', 'on');
            set(handles.cutplanePanel, 'Visible', 'on');
            set(handles.dispCutPlane, 'Visible', 'on');
            set(handles.dispPointCloud, 'Visible', 'on');
            set(handles.dispCutPlane, 'Enable', 'off');
            set(handles.dispCutPlane, 'Value', 0);
            set(handles.dispPointCloud, 'Value', 0);
            availOperationTable(handles);
            set(handles.plotBut, 'Enable', 'on');
            set(findobj(handles.resultMenu.Children), 'Enable', 'on');
            set(findobj(handles.fileMenu.Children, 'Tag', 'exportPlaneFileAction'), 'Enable', 'on');
        end
        
    catch ME
        delete(findobj(handles.axes4.Children, 'Visible', 'on', '-and', 'Type', 'Surface', '-and', ...
            '-regexp','Tag','_p'));
        uiwait(errordlg({'Importing plane files failed!', ' ', 'Error Message: ', ME.message}));
    end
end

% --------------------------------------------------------------------
function applyMatrixAction_Callback(hObject, eventdata, handles)
%Get a rotation matrix
prj = getappdata(0, 'project');
list = prj.rotationMatrixList;
[indx,~] = listdlg('PromptString',{'Choose a rotation matrix'}, 'SelectionMode','single', 'ListString', list);
matrixName = list{indx};
worldmat = prj.find_rotationMatrix(matrixName);

%Decide whether a planeStruct already exists
doPlaneStruct = 0;
if ~isempty(prj.branches{1}.cPoints) && ~isempty(prj.branches{1}.cNormal) && ~isempty(prj.branches{1}.cRotate)
    doPlaneStruct = 1;
    delta_t = str2double(handles.cPlaneDist.String);    % interval between two successive cutplanes
end

for i=1:length(prj.branches)
    %pList - list of points in the line
    yxz_coord = prj.branches{i}.pList(:, 1:3);
    yxz_coord(:,4) = 1;
    yxz_coord_new = worldmat \ yxz_coord'; %new coords * worldmat = original coords of moving mask x = A\B if Ax = B
    prj.branches{i}.pList(:, 1:3) = (yxz_coord_new(1:3, :))';
    
    %Only do this if a planeStruct already exists
    if(doPlaneStruct)
        %cPoints - list of points with cutplanes
        t = prj.branches{i}.pList(2,4):delta_t:max(prj.branches{i}.pList(:,4));
        prj.branches{i}.cPoints = [ (ppval(prj.branches{i}.fitLine(1),t)); (ppval(prj.branches{i}.fitLine(2),t)); (ppval(prj.branches{i}.fitLine(3),t))]';
        prj.branches{i}.cPoints(:,4) = cumsum([0;sqrt(diff(prj.branches{i}.cPoints(:,1)).^2 + diff(prj.branches{i}.cPoints(:,2)).^2 + diff(prj.branches{i}.cPoints(:,3)).^2)]);
        %Recalculate orientation of cutplanes
        n = normrTwin([ (ppval(fnder(prj.branches{i}.fitLine(1)),t)); (ppval(fnder(prj.branches{i}.fitLine(2)),t)); (ppval(fnder(prj.branches{i}.fitLine(3)),t))]');
        prj.branches{i}.cNormal = n;
        ncell = mat2cell(n,ones(1,size(n,1)),3);
        prj.branches{i}.cRotate = zeros(size(prj.branches{i}.cPoints,1),4);
        prj.branches{i}.cRotate(:,1:3) = cell2mat(cellfun(@(x) cross([0 0 1],x), ncell,'UniformOutput', false));
        prj.branches{i}.cRotate(:,4) = cellfun(@(x) acos(dot([0 0 1],x)), ncell);
    end
end  

%Update everything else
magic_tool_update(handles, 'centerline', 0);
magic_tool_update(handles,'label');
updatelist(handles);  
isImported = 1;
clusterMode = 1;
tagsMode = 1; %Include tags when importing (this will not be used in import pathway)
roiOrigin = [];
magic_tool_update(handles, 'cutplane', roiOrigin, isImported, clusterMode, tagsMode);

% --------------------------------------------------------------------
function exportImageSeriesAction_Callback(hObject, eventdata, handles)
%keyboard
selectedVolume = handles.DispItem.String{handles.DispItem.Value};
prj = getappdata(0, 'project');
imageVolume = prj.find_volume(selectedVolume, 'Image');
if ~isempty(imageVolume)
    [imageFile, imagePath] = uiputfile(fullfile(prj.workingDirectory, ...
        [selectedVolume '_struct.mat']) , 'Save image series as');
    if ~isequal(imageFile, 0) && ~isequal(imagePath, 0)
        refStruct = prj.vel;
        refStruct.vox = imageVolume.vox;
        refStruct.edges = imageVolume.edges;
        position = num2cell(imageVolume.fov);

        mrstruct_imageVolume = mrstruct_init('series3D',imageVolume.data,refStruct);
        mrstruct_imageVolume.dim10 = num2str(imageVolume.interpFactor);
        mrstruct_imageVolume.dim11 = sprintf('%.4f,%.4f,%.4f,%.4f,%.4f,%.4f', position{:});

        mrstruct_write(mrstruct_imageVolume, fullfile(imagePath,imageFile));
    end
else
    msgbox('Please select an image volume not a mask');
end

% --------------------------------------------------------------------
function exportMaskAction_Callback(hObject, eventdata, handles)
prj = getappdata(0, 'project');
[mrStruct, EnSight, STL, selectedMask] = exportMaskDialog(prj.maskList());
Mask = prj.find_volume(selectedMask, 'Mask');
refStruct = rmfield(prj.mag, {'shape', 'nFrames', 'sys'});

if mrStruct || EnSight || STL  
    msgString = 'Mask files were saved: ';
    if mrStruct
        [maskFile, maskPath] = uiputfile(fullfile(prj.workingDirectory, [selectedMask '_struct.mat']) , 'Save image series as');
        if ~isequal(maskFile,0)
            refStruct.vox = Mask.vox;
            refStruct.edges = Mask.edges;
            position = num2cell(Mask.fov);
            mrstruct_mask = mrstruct_init('series3D',Mask.data,refStruct);
            mrstruct_mask.dim10 = num2str(Mask.interpFactor);
            mrstruct_mask.dim11 = sprintf('%.4f,%.4f,%.4f,%.4f,%.4f,%.4f', position{:});        
            mrstruct_write(mrstruct_mask,fullfile(maskPath,maskFile));
            msgString = [msgString ' ' fullfile(maskPath,maskFile)];
        end
    end
    if EnSight
        [caseFile,casePath] = uigetfile('*.case','Select EnSight case',prj.workingDirectory);
        if ~isequal(caseFile,0)
            if Mask.interpFactor > 1
                % downSampling if needed:
                [xq,yq,zq] = meshgrid(1:2:size( Mask.data,2), 1:2:size( Mask.data,1),1:2:size( Mask.data,3));
                segment = interp3(Mask.data, xq, yq, zq);
                refStruct.vox = Mask.interpFactor*Mask.vox;
            else
                segment = Mask.data;
            end
            mrstruct_mask = mrstruct_init('series3D',segment,refStruct);        
            append_data_ensight(mrstruct_mask, refStruct, caseFile, casePath, '', 'mask', '.mask');
            msgString = [msgString ' ' fullfile(casePath,caseFile)];
        end
    end
    if STL %MA 20191121 - add this for exporting to mimics
        [maskFile, maskPath] = uigetfile(fullfile(prj.workingDirectory, [selectedMask '_struct.mat']) , 'Select mrStruct to export as stl');
        if ~isequal(maskFile,0)
            flipflag = 0;
            stlpath = mask_to_stl(fullfile(maskPath, maskFile),flipflag);
            msgString = [msgString ' ' stlpath];
        end
    end
    uiwait(msgbox(msgString));
end

% --------------------------------------------------------------------
function exportMatrixAction_Callback(hObject, eventdata, handles)% --------------------------------------------------------------------
%Get a rotation matrix
prj = getappdata(0, 'project');
list = prj.rotationMatrixList;
[indx,~] = listdlg('PromptString','Choose a rotation matrix', 'SelectionMode','single', 'ListString', list);
matrixName = list{indx};
worldmat = prj.find_rotationMatrix(matrixName);

%Get a place to put it
[rotMatFile, rotMatPath] = uiputfile(fullfile(prj.workingDirectory, ['rotationMatrix.mat']) , 'Save rotation matrix as');

%Always save under the same variable name for ease of import
save(fullfile(rotMatPath, rotMatFile), 'worldmat');

% --------------------------------------------------------------------
function exportBranchFileAction_Callback(hObject, eventdata, handles)
prj = getappdata(0, 'project');
[branchstructfile, path] = uiputfile([prj.workingDirectory 'branchStruct.mat'], 'Save branchStruct as');
branchStruct = struct(  'id', [], 'name', [], 'pList', [], 'pInd', [], ...
                        'fitLine', [], 'lineHandle', [], 'visibility', []);
if ~isequal(branchstructfile,0) && ~isequal(path,0)
    for i=1:length(prj.branches)
        branchStruct(i).id = prj.branches{i}.id;
        branchStruct(i).name = prj.branches{i}.name;
        branchStruct(i).pList = prj.branches{i}.pList;
        branchStruct(i).pInd = prj.branches{i}.pInd;
        branchStruct(i).fitLine = prj.branches{i}.fitLine;
        branchStruct(i).lineHandle = prj.branches{i}.lineHandle;
        branchStruct(i).visibility = prj.branches{i}.visibility;
    end
    save(fullfile(path,branchstructfile),'branchStruct');
end

% --------------------------------------------------------------------
function exportCenterlineFileAction_Callback(hObject, eventdata, handles)
vessels = getappdata(0, 'selectedVessels');
if isempty(vessels)
    errordlg('Please select at least one branch from the list');
else
    exportCenterlineDialog(handles.VesselTable.Data(vessels,1));
end

% --------------------------------------------------------------------
function exportPlaneFileAction_Callback(hObject, eventdata, handles)
prj = getappdata(0, 'project');
[planefile, path] = uiputfile([prj.workingDirectory 'planeStruct.mat'], 'Save planeStruct as');
fieldList = {'id', 'name', 'pList', 'pInd', 'fitLine', 'lineHandle', 'visibility', ...
    'cPoints', 'planeDim', 'planeRes', 'cRotate', 'cNormal', 'cPlane', ...
    'polyPoints', 'breakPoints'};
zip = reshape([fieldList; cell(size(fieldList))], 1, []);
planeStruct = struct(zip{:});
if ~isequal(planefile,0) && ~isequal(path,0)
    for i=1:length(prj.branches)
        planeStruct(i).id = prj.branches{i}.id;
        planeStruct(i).name = prj.branches{i}.name;
        planeStruct(i).pList = prj.branches{i}.pList;
        planeStruct(i).pInd = prj.branches{i}.pInd;
        planeStruct(i).fitLine = prj.branches{i}.fitLine;
        planeStruct(i).lineHandle = prj.branches{i}.lineHandle;
        planeStruct(i).visibility = prj.branches{i}.visibility;
        planeStruct(i).cPoints = prj.branches{i}.cPoints;
        planeStruct(i).planeDim = prj.branches{i}.planeDim;
        planeStruct(i).planeRes = prj.branches{i}.planeRes;
        planeStruct(i).cRotate = prj.branches{i}.cRotate;
        planeStruct(i).cNormal = prj.branches{i}.cNormal;
        planeStruct(i).cPlane = cellfun(@(x) x(:,[1,2,3]), prj.branches{i}.cPlane(:,1), 'UniformOutput', false);
        planeStruct(i).polyPoints = cellfun(@(x) x(:,[4,5]), prj.branches{i}.cPlane(:,2), 'UniformOutput', false);
        planeStruct(i).breakPoints = cellfun(@(x) x(:,[4,5]), prj.branches{i}.cPlane(:,5), 'UniformOutput', false);
        planeStruct(i).cPlaneTags = prj.branches{i}.cPlaneTags;
    end
    save(fullfile(path,planefile),'planeStruct');
end

% --- Executes on button press in dispBox.
function dispBox_Callback(hObject, eventdata, handles)
prj = getappdata(0, 'project');
magic_tool_update(handles, 'box', prj.find_volume(handles.DispItem.String{handles.DispItem.Value}));

function DispSlices_Callback(hObject, eventdata, handles)
prj = getappdata(0, 'project');
magic_tool_update(handles, 'dispSlices', prj.find_volume(handles.DispItem.String{handles.DispItem.Value}));

function slider1_Callback(hObject, eventdata, handles)
prj = getappdata(0, 'project');
set(handles.X_cord, 'string', num2str(floor(handles.slider1.Value)));
activeVolume = prj.find_volume(handles.DispItem.String{handles.DispItem.Value});
magic_tool_update(handles,'image','axes1', ...
    squeeze(activeVolume.data(:,str2double(handles.X_cord.String),:)));
magic_tool_update(handles, 'sliceSlider', activeVolume, 'Sagittal');

function slider2_Callback(hObject, eventdata, handles)
prj = getappdata(0, 'project');
set(handles.Y_cord, 'string', num2str(floor(handles.slider2.Value)));
activeVolume = prj.find_volume(handles.DispItem.String{handles.DispItem.Value});
magic_tool_update(handles,'image','axes2', ...
    imrotate(squeeze(activeVolume.data(str2double(handles.Y_cord.String),:,:)),90));
magic_tool_update(handles, 'sliceSlider', activeVolume, 'Coronal');

function slider3_Callback(hObject, eventdata, handles)
prj = getappdata(0, 'project');
set(handles.Z_cord, 'string', num2str(floor(handles.slider3.Value)));
activeVolume = prj.find_volume(handles.DispItem.String{handles.DispItem.Value});
magic_tool_update(handles,'image','axes3', ...
    squeeze(activeVolume.data(:,:,str2double(handles.Z_cord.String))));
magic_tool_update(handles, 'sliceSlider', activeVolume, 'Axial');


function Disp3D_Callback(hObject, eventdata, handles)
if handles.Disp3D.Value
    magic_tool_update(handles, 'isosurface');
    set(handles.isoSurfacePanel, 'Visible', 'on');
else
    delete(findobj(handles.axes4.Children,'Type','Patch'));
    delete(findobj(handles.axes4.Children,'Type','Light'));
    set(handles.TransSlider, 'Visible', 'off');
    set(handles.TransText, 'Visible', 'off');
    set(handles.isoSurfacePanel, 'Visible', 'off');    
end

% --- Executes on button press in updateIsosurfaceBut.
function updateIsosurfaceBut_Callback(hObject, eventdata, handles)
magic_tool_update(handles, 'isosurface');

% --------------------------------------------------------------------
function analysisMenu_Callback(hObject, eventdata, handles)
% hObject    handle to analysisMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function extractCPAction_Callback(hObject, eventdata, handles)
cProject = getappdata(0, 'project');
quickLoad = getappdata(0, 'quickLoad'); %MA20200327
if quickLoad == 0 %Normal operation
    [answer, smoothing, level] = extractCPDialog(cProject.maskList());
else
    %Hard-code these for now
    answer = cProject.maskList{1};
    smoothing = 0;
    level = 0;
end
if ~isempty(answer)
    %This part is a wrapper for magic_tool_update
    h = busydlg(' ', 'Extracting CenterPoints...');
    if ~isempty(cProject.centerPoints)
        cProject.centerPoints.remove();
        cProject.centerPoints=[];
    end

    cProject.centerPoints = copy(cProject.find_volume(answer, 'Mask'));
    cProject.centerPoints.name = 'CenterPoints';

    if min(cProject.centerPoints.vox) > 0.4
        if smoothing
            switch level
                case 0
                    st = 2;
                    kernel = 3;
                case 1
                    st = 5;
                    kernel = 5;
                case 2
                    st = 7;
                    kernel = 7;
                case 3
                    st = 9;
                    kernel = 9;
            end
            se = strel('cube',st);
            skel = Skeleton3D(smooth3(imclose(imopen(cProject.centerPoints.data, se),se),'gaussian',kernel)>0.5);
        else
            skel = Skeleton3D(cProject.centerPoints.data > 0.5);
        end
    else
        se = strel('cube',3);
        skel = Skeleton3D(smooth3(imclose(imopen(cProject.centerPoints.data, se), se),'gaussian',5)>0.5);
    end

    cProject.centerPoints.data = 2*skel; % every point initially is a middle/branch point  
    set(handles.DispCP, 'Visible', 'on', 'Value', 1);
    magic_tool_update(handles, 'centerpoint');

    close(h);
    if quickLoad == 0 %Don't show messages while quickLoading
        uiwait(msgbox('Center points extraction finished!'));
    end
    set(findobj(handles.analysisMenu.Children, 'Tag', 'findVesselsAction'), 'Enable', 'on');
end

% --------------------------------------------------------------------
function findVesselsAction_Callback(hObject, eventdata, handles)
quickLoad = getappdata(0, 'quickLoad'); %MA20200327
if quickLoad == 0 %Normal operation
answer = questdlg('Select the threshold for spur length (use higher value to remove small features)', ...
    'Vessel construction', '6 voxels', '8 voxels', 'Cancel', '6 voxels');
else %quickLoad
    answer = '6 voxels';
end
if contains(answer, 'voxel')
    prj = getappdata(0, 'project');
    h = busydlg(' ', 'Finding Centerlines...');

    sortingCriteria = 3; % either 2 or 3
    spurLength = str2double(answer(1));
    branchList = centerline(prj.vMean, spurLength, sortingCriteria, prj.centerPoints);

    %------- making branchStruct
    if ~isempty(prj.branches)
        prj.removeBranch('All');
    end

    prj.backup_init();

    labels = unique(branchList(:,4));

    for i=1:length(labels)
        prj.branches{i} = Branch();
        prj.branches{i}.id = labels(i);
        prj.branches{i}.name = 'unknown';
        pointList = branchList(branchList(:,4) == prj.branches{i}.id, :);
        prj.branches{i}.pInd = pointList(:,1:3);
        ind = mat2cell(num2cell(prj.branches{i}.pInd), ones(1, length(prj.branches{i}.pInd)), 3);

        prj.branches{i}.pList = [   cellfun(@(x) prj.centerPoints.y_coord(x{:}), ind), ...
                                    cellfun(@(x) prj.centerPoints.x_coord(x{:}), ind), ...
                                    cellfun(@(x) prj.centerPoints.z_coord(x{:}), ind)   ];

        prj.branches{i}.visibility = 'on';
    end

    i = 1;
    while i <= length(prj.branches)
        if length(prj.branches{i}.pList) < 4
            prj.removeBranch(i);
        else
            i = i+1;
        end
    end

    close(h);
    if quickLoad == 0 %Normal operation with comments
        uiwait(msgbox('Vessel identification finished!'));
    end
    magic_tool_update(handles, 'centerpoint');
    set(handles.mainGUI, 'pointer', 'arrow');
    drawnow;

    set(handles.DispLabels, 'Visible', 'on');
    set(handles.DispCL, 'Visible', 'on');
    set(handles.DispCL, 'Value', 1);
    set(handles.DispLabels, 'Value', 1);

    magic_tool_update(handles, 'centerline', 1);
    magic_tool_update(handles,'label');
    updatelist(handles);
    set(handles.EditVesselBut, 'Enable', 'on');
    set(findobj(handles.analysisMenu.Children, 'Tag', 'editVesselsAction'), 'Enable', 'on');
    cellfun(@(x) set(findobj(handles.fileMenu.Children, 'Tag', x), 'Enable', 'on'), ...
        {'exportBranchFileAction', 'importBranchFileAction', ...
        'importPlaneFileAction', 'exportCenterlineFileAction'});
    handles.maxRange.String = 'max';
    handles.minRange.String = 'min';
    prj.backup_init();
    set(handles.undoBut, 'Enable', 'off');
    set(findobj(handles.visualizationAction.Children, 'Tag', 'flowDirectionAction'), 'Enable', 'on');
end

% --------------------------------------------------------------------
function editVesselsAction_Callback(hObject, eventdata, handles)
set(handles.tab1Panel, 'Visible', 'off');
set(handles.tab2Panel, 'Visible', 'on');
set(handles.tab3Panel, 'Visible', 'off');

function TransSlider_Callback(hObject, eventdata, handles)
set(findobj(handles.axes4.Children, 'Type', 'Patch'),'FaceAlpha',handles.TransSlider.Value);

function DispItem_Callback(hObject, eventdata, handles)
prj = getappdata(0, 'project');
selectedVolume = prj.find_volume(handles.DispItem.String{handles.DispItem.Value});
if isa(selectedVolume, 'Mask')
    prj.cMask = selectedVolume;
    cSize = size(prj.cMask.data);
else
    prj.cImage = selectedVolume;
    cSize = size(prj.cImage.data);
end
adjustSliders(handles, cSize);
magic_tool_update(handles, 'slice', selectedVolume);
if handles.dispBox.Value
    magic_tool_update(handles, 'box', selectedVolume);
end

function adjustSliders(handles, cSize)
set(handles.slider1, 'max', cSize(2));
if str2double(handles.X_cord.String) > cSize(2)
    handles.slider1.Value = cSize(2)-1;
    handles.X_cord.String = num2str(cSize(2)-1);
end
set(handles.slider1, 'SliderStep', [1/get(handles.slider1, 'max'),0.075]);

set(handles.slider2, 'max', cSize(1));
if str2double(handles.Y_cord.String) > cSize(1)
    handles.slider2.Value = cSize(1)-1;
    handles.Y_cord.String = num2str(cSize(1)-1);
end
set(handles.slider2, 'SliderStep', [1/get(handles.slider2, 'max'),0.075]);

set(handles.slider3, 'max', cSize(3));
if str2double(handles.Z_cord.String) > cSize(3)
    handles.slider3.Value = cSize(3)-1;
    handles.Z_cord.String = num2str(cSize(3)-1);
end
set(handles.slider3, 'SliderStep', [1/get(handles.slider3, 'max'),0.075]);

function DispCL_Callback(hObject, eventdata, handles)
if handles.DispCL.Value
    magic_tool_update(handles, 'centerline', 0);
else
    delete(findobj(handles.axes4.Children, 'Type', 'Line','-and', '-regexp','Tag','_CL'));
end

function DispLabels_Callback(hObject, eventdata, handles)
if handles.DispLabels.Value
    magic_tool_update(handles, 'label');
else
    delete(findobj(handles.axes4.Children, 'Type', 'Text'));
end

function DispCP_Callback(hObject, eventdata, handles)

if handles.DispCP.Value    
    magic_tool_update(handles, 'centerpoint');
else
    delete(findobj(handles.axes4.Children, 'Type', 'Scatter', ...
                '-regexp','Tag', '_center'));
end

function SliceBut_Callback(hObject, eventdata, handles)
set(handles.tab1Panel, 'Visible', 'on');
set(handles.tab2Panel, 'Visible', 'off');
set(handles.tab3Panel, 'Visible', 'off');

function EditVesselBut_Callback(hObject, eventdata, handles)
set(handles.tab1Panel, 'Visible', 'off');
set(handles.tab2Panel, 'Visible', 'on');
set(handles.tab3Panel, 'Visible', 'off');

function availOperationTable(handles)
selectedVessels = getappdata(0, 'selectedVessels');
if isequal(length(selectedVessels),1) 
    currentItem = handles.VesselTable.Data{selectedVessels,:};
    set(handles.branchID, 'String', currentItem(1:find(currentItem == '-')-2));
    set(handles.branchName, 'String' , currentItem(find(currentItem == '-')+2:end));
    set(handles.nameBut, 'Enable', 'on');
    set(handles.divideBut, 'Enable', 'on');
    
    if strcmp(handles.cutplanePanel.Visible, 'on')
        set(handles.planeSlider, 'Enable', 'on');
        set(handles.DispCutPlot, 'Enable', 'on');
        prj = getappdata(0, 'project');
        set(handles.planeSlider, 'max', max(2,length(prj.branches{str2double(get(handles.branchID, 'String'))}.cPoints)));
        set(handles.planeSlider, 'Value', get(handles.planeSlider, 'min'));
        set(handles.planeSlider, 'SliderStep', [1/(get(handles.planeSlider, 'max')-1), ...
            1/(get(handles.planeSlider, 'max')-1) ]);
    end
else
    set(handles.nameBut, 'Enable', 'off');
    set(handles.divideBut, 'Enable', 'off');
    
    if handles.planeSlider.Visible
        set(handles.planeSlider, 'Enable', 'off');
        set(handles.DispCutPlot, 'Enable', 'off');
    end
end

if isequal(length(selectedVessels),2)
    set(handles.joinBut, 'Enable', 'on');
else
   set(handles.joinBut, 'Enable', 'off');
end

if isempty(selectedVessels)
    set(handles.deleteBut, 'Enable', 'off');
    set(handles.invertBut, 'Enable', 'off');
    set(handles.dispCutPlaneBut, 'Enable', 'off');
else
    set(handles.deleteBut, 'Enable', 'on');
    set(handles.invertBut, 'Enable', 'on');
    set(handles.dispCutPlaneBut, 'Enable', 'on');
end

function nameBut_Callback(hObject, eventdata, handles)
set(handles.NameEdit, 'Visible','on');

function joinBut_Callback(hObject, eventdata, handles)
vessels = getappdata(0, 'selectedVessels');
if length(vessels) ~= 2 
    errordlg('Please select two vessels for join operation');
else

    prj = getappdata(0, 'project');
    ids = cellfun(@(x) x.id, prj.branches);

    b1 = handles.VesselTable.Data{vessels(1),1};
    b2 = handles.VesselTable.Data{vessels(2),1};

    index(1) = find(ids == str2double(b1(1:find(b1 == '-')-2)));
    index(2) = find(ids == str2double(b2(1:find(b2 == '-')-2)));

    e1 = prj.branches{index(2)}.pList(2,1:3) - prj.branches{index(1)}.pList(end,1:3);
    e2 = prj.branches{index(1)}.pList(2,1:3) - prj.branches{index(2)}.pList(end,1:3);

    v1 = squeeze(prj.vMean.data(prj.branches{index(1)}.pInd(end,1), ...
        prj.branches{index(1)}.pInd(end,2), prj.branches{index(1)}.pInd(end,3),:))';
    
    v2 = squeeze(prj.vMean.data(prj.branches{index(2)}.pInd(end,1), ...
        prj.branches{index(2)}.pInd(end,2), prj.branches{index(2)}.pInd(end,3),:))';

    if dot(v2/norm(v2),e2/norm(e2)) < dot(v1/norm(v1),e1/norm(e1))
        index = index([2,1]);
    end

    dist(1) = norm(prj.branches{index(2)}.pList(1,1:3) - prj.branches{index(1)}.pList(end,1:3));
    dist(2) = norm(prj.branches{index(1)}.pList(1,1:3) - prj.branches{index(2)}.pList(end,1:3));

    if(dist(1) < dist(2))
        first = index(1); second = index(2);
    else
        first = index(2); second = index(1);
    end
    tempPointList = [prj.branches{first}.pList; prj.branches{second}.pList];
    tempPointList(:,4) = cumsum([0; sqrt(diff(tempPointList(:,1)).^2 + ...
        diff(tempPointList(:,2)).^2 + diff(tempPointList(:,3)).^2)]);

    knots = min(max(floor(0.1*size(tempPointList,1)), 2),16);
    temp = [splinefit(tempPointList(:,4) ,tempPointList(:,1),knots), ...
            splinefit(tempPointList(:,4) ,tempPointList(:,2),knots), ...
            splinefit(tempPointList(:,4) ,tempPointList(:,3),knots)];
	 
    ss = linspace(0,max(tempPointList(:,4)),min(size(tempPointList, 1), 40));
    axes(handles.axes4);
    set(prj.branches{index(1)}.lineHandle, 'Visible', 'off');
    set(prj.branches{index(2)}.lineHandle, 'Visible', 'off');

    hold on;          
    h = plot3(ppval(temp(2),ss), ppval(temp(1),ss), ppval(temp(3),ss), ...
        '--r','LineWidth',2.5);
    hold off             

    if isequal(questdlg('Are you sure, you want to join the selected vessels?'), 'Yes')
        
        prj.backup_push();  % first make a backup
        if ~isempty(prj.backup)
            set(handles.undoBut, 'Enable', 'on');
        end
        prj.branches{first}.pList = [prj.branches{first}.pList;prj.branches{second}.pList];
        prj.branches{first}.pInd = [prj.branches{first}.pInd;prj.branches{second}.pInd];
        prj.branches{first}.pList(:,4) = cumsum([0;sqrt(diff(prj.branches{first}.pList(:,1)).^2 + ...
            diff(prj.branches{first}.pList(:,2)).^2 + diff(prj.branches{first}.pList(:,3)).^2)]);
        prj.removeBranch(second);
        
        %If there are cPlaneTags already and the user re-calculates
        %planes with keep tags option, there will be the wrong number
        %of tags, so clear them and notify user
        prj.branches{first}.cPlaneTags = [];
        msgbox(['Cutplane tags have been deleted for branch ' num2str(first)]);
    end

    delete(h);
    updatelist(handles);
    magic_tool_update(handles, 'centerline', 0);
    magic_tool_update(handles,'label');
end

function deleteBut_Callback(hObject, eventdata, handles)
vessels = getappdata(0, 'selectedVessels');
if isempty(vessels)
    errordlg('Please select at least one vessel to be deleted');
else    
    if strcmp(questdlg('Do you want to delete the selected vessel(s)?'), 'Yes')
        prj = getappdata(0,'project');

        prj.backup_push();  % first make a backup
        if ~isempty(prj.backup)
            set(handles.undoBut, 'Enable', 'on');
        end
        

        branchNames = handles.VesselTable.Data(vessels,1); 
        prj.removeBranch(cellfun(@(x) str2double(x(1:find(x == '-')-2)), branchNames));
       
        updatelist(handles);
        magic_tool_update(handles, 'centerline', 0);
        magic_tool_update(handles,'label');
    end
end
availOperationTable(handles);

function divideBut_Callback(hObject, eventdata, handles)
prj = getappdata(0, 'project');
ids = cellfun(@(x) x.id, prj.branches);
selectedVessel = handles.VesselTable.Data{getappdata(0, 'selectedVessels'),1};
index = find(ids == str2double(selectedVessel(1:find(selectedVessel == '-')-2)));
h = msgbox('Please pick a point on the selected vessel for split operation and then press Enter');
uiwait(h);
while true
    dcm_obj = datacursormode;
    set(dcm_obj,'DisplayStyle','datatip',...
        'SnapToDataVertex','on','Enable','on')
    pause
    c_info = getCursorInfo(dcm_obj);
    cutPoint = c_info.Position;
    cutPoint = cutPoint([2,1,3]);
   [ind, dist] = knnsearch(prj.branches{index}.pList(:,1:3), cutPoint);

    if dist < 2.5
        if strcmp(questdlg('Are you sure you want to split the selected vessel?'), 'Yes')
            
            prj.backup_push();  % first make a backup
            if ~isempty(prj.backup)
                set(handles.undoBut, 'Enable', 'on');
            end
            %Copy the entire branch to a new index
            prj.branches = [prj.branches(1:index),{prj.branches{index}.copy()},prj.branches(index+1:end)];
            %Make the first branch contain pre-split points only
            prj.branches{index}.pList = prj.branches{index}.pList(1:ind,:);
            prj.branches{index}.pInd = prj.branches{index}.pInd(1:ind,:);
            %Make the second branch contain post-split points only
            prj.branches{index+1}.pList = prj.branches{index+1}.pList(ind:end,:);
            prj.branches{index+1}.pInd = prj.branches{index+1}.pInd(ind:end,:);
            %If there are cPlaneTags already and the user re-calculates
            %planes with keep tags option, there will be the wrong number
            %of tags, so clear them and notify user
            if ~isempty(prj.branches{index}.cPlaneTags)
                prj.branches{index}.cPlaneTags = [];
                prj.branches{index+1}.cPlaneTags = [];
                msgbox(['Cutplane tags (if any) have been deleted for branches ' num2str(index) ' and ' num2str(index+1)]);
            end

            for i=1:length(prj.branches)
                prj.branches{i}.id = i;
            end
            
            updatelist(handles);
            magic_tool_update(handles, 'centerline', 0);
            magic_tool_update(handles, 'label');
        end
        break;
    else
        answer = questdlg(['The point is not on the selected vessel. If you want to ' ...
            'split the vessel press Yes and pick a new point on the selected vessel ' ...
            'for split operation and then press Enter. If you do not want to ' ...
            'continue with split operation press No']);
        if strcmp(answer, 'No')
            break;
        end
    end    
end

function nameMenu_Callback(hObject, eventdata, handles)
set(handles.branchName, 'String', handles.nameMenu.String{handles.nameMenu.Value});

function renamebut_Callback(hObject, eventdata, handles)
if ~isequal(get(handles.branchID, 'String'), '')

    prj = getappdata(0, 'project');
    for i = 1:length(prj.branches)
        if prj.branches{i}.id == str2double(get(handles.branchID, 'String'))
            prj.backup_push();
            if ~isempty(prj.backup)
                set(handles.undoBut, 'Enable', 'on');
            end
            prj.branches{i}.name = get(handles.branchName, 'String');
            break;
        end
    end

    updatelist(handles);
end

function updatelist(handles)
prj = getappdata(0, 'project');
IDs = cellfun(@(x,y) [num2str(x) ' - ' y], cellfun(@(x) x.id, prj.branches, 'UniformOutput', false), ...
    cellfun(@(x) x.name, prj.branches, 'UniformOutput', false), 'UniformOutput', false);
set(handles.VesselTable, 'Data', [IDs(:),cellfun(@(x) x.visibility, prj.branches, 'UniformOutput', false)']);
setappdata(0, 'selectedVessels', []);
set(handles.nameBut, 'Enable', 'off');
set(handles.invertBut, 'Enable', 'off');
set(handles.divideBut, 'Enable', 'off');
set(handles.joinBut, 'Enable', 'off');
set(handles.deleteBut, 'Enable', 'off');

% --- Executes on button press in undoBut.
function undoBut_Callback(hObject, eventdata, handles)
prj = getappdata(0, 'project');
prj.backup_pop();
if isempty(prj.backup)
    set(handles.undoBut, 'Enable', 'off');
end
temp = handles.VesselTable.Data;
handles.VesselTable.Data = [];
handles.VesselTable.Data = temp;
updatelist(handles);
magic_tool_update(handles, 'centerline', 0);
magic_tool_update(handles,'label');

% --- Executes on button press in invertBut.
function invertBut_Callback(hObject, eventdata, handles)
vessels = getappdata(0, 'selectedVessels');
if isempty(vessels)
    errordlg('Please select at least one vessel to be inverted');
else    
    if strcmp(questdlg('Do you want to flip the flow direction in the selected vessel(s)?'), 'Yes')
        prj = getappdata(0,'project');

        prj.backup_push();  % first make a backup
        if ~isempty(prj.backup)
            set(handles.undoBut, 'Enable', 'on');
        end        

        branchNames = handles.VesselTable.Data(vessels,1); 
        
        for i=cellfun(@(x) str2double(x(1:find(x == '-')-2)), branchNames)'
            prj.branches{i}.pList = flipud(prj.branches{i}.pList);
            prj.branches{i}.pInd = flipud(prj.branches{i}.pInd);
        end
        magic_tool_update(handles, 'centerline', 0);
        updatelist(handles);
        temp = handles.VesselTable.Data;
        handles.VesselTable.Data = [];
        handles.VesselTable.Data = temp;        
    end
end


function deleteROIBut_Callback(hObject, eventdata, handles)
ROI_segment(handles, 0)

function keepROIBut_Callback(hObject, eventdata, handles)
ROI_segment(handles, 1)

function ROI_segment(handles, action)
if ~isequal(handles.seg_Masks.Value, 1)
    prj = getappdata(0, 'project');
    selectedSource = prj.find_volume(handles.DispItem.String{handles.DispItem.Value}, 'Mask');
    cMask = prj.find_volume(handles.seg_Masks.String{handles.seg_Masks.Value}, 'Mask');

    if isempty(selectedSource) || ~isequal(selectedSource.parentName, cMask.parentName)
        errordlg('The source for ROI segmentation must be a mask created from the same image series');
    else
        try
            selectedROI = ones(size(cMask.data));    
            warning('off','MATLAB:callback:PropertyEventError');
            if strcmp(handles.activeAxes.SelectedObject.String, 'Sagittal')
                ax = handles.axes1;
                ind = str2double(get(handles.X_cord, 'String'));    
            elseif strcmp(handles.activeAxes.SelectedObject.String, 'Coronal')
                ax = handles.axes2;
                ind = str2double(get(handles.Y_cord, 'String'));    
            elseif strcmp(handles.activeAxes.SelectedObject.String, 'Axial')
                ax = handles.axes3;
                ind = str2double(get(handles.Z_cord, 'String'));    
            end

            points = [];
            h = impoly(ax);

            if ~isempty(h)
                points = h.getPosition();
            end

            if ~isempty(points)
                image = findobj(ax.Children, 'Type', 'Image');
                [xq,yq] = meshgrid(1:size(image.CData,2), 1:size(image.CData, 1));
                in = inpolygon(xq(:),yq(:), points(:,1),points(:,2));
                if action
                    maskImage = zeros(size(image.CData));
                    maskImage(in) = 1;
                else
                    maskImage = ones(size(image.CData));
                    maskImage(in) = 0;
                end
                maskedImage = maskImage.*image.CData;

                preFig = figure;
                imagesc(maskedImage);
                axis off equal;
                colormap Gray;
                title 'Preview';

                answer = questdlg('do you like to apply the mask on this image only or entire volume?', ...
                    '','Image only', 'Entire volume', 'Cancel','Image only');    
                close(preFig);

                if strcmp(answer, 'Image only')

                    if strcmp(handles.activeAxes.SelectedObject.String, 'Sagittal')        
                        selectedROI(:,ind,:) = selectedROI(:,ind,:) .* permute(maskImage, [1,3,2]);
                    elseif strcmp(handles.activeAxes.SelectedObject.String, 'Coronal')
                        maskImage = imrotate(maskImage,-90);
                        selectedROI(ind,:,:) = selectedROI(ind,:,:) .* permute(maskImage, [3,1,2]);
                    elseif strcmp(handles.activeAxes.SelectedObject.String, 'Axial')
                        selectedROI(:,:,ind) = selectedROI(:,:,ind) .* maskImage;
                    end

                elseif strcmp(answer, 'Entire volume')

                    if strcmp(handles.activeAxes.SelectedObject.String, 'Sagittal')
                        for p = 1:size(selectedROI,2)
                            selectedROI(:,p,:) = selectedROI(:,p,:) .* permute(maskImage, [1,3,2]);
                        end
                    elseif strcmp(handles.activeAxes.SelectedObject.String, 'Coronal')
                        maskImage = imrotate(maskImage,-90);
                        for p = 1:size(selectedROI,1)
                            selectedROI(p,:,:) = selectedROI(p,:,:) .* permute(maskImage, [3,1,2]);
                        end
                    elseif strcmp(handles.activeAxes.SelectedObject.String, 'Axial')
                        for p = 1:size(selectedROI,3)
                            selectedROI(:,:,p) = selectedROI(:,:,p) .* maskImage;
                        end
                    end        
                else
                end

                cMask.edit('ROI', selectedSource, selectedROI);
                magic_tool_update(handles, 'slice', prj.find_volume(handles.DispItem.String{handles.DispItem.Value}));

                if handles.Disp3D.Value && (isequal(handles.isoSurfaceMenu.String, cMask.name) ...
                        || ismember(cMask.name, handles.isoSurfaceMenu.String(handles.isoSurfaceMenu.Value)))
                    magic_tool_update(handles, 'isosurface');
                end
            end
        catch
            msgbox('Please try again');
        end
    end
else
    msgbox('Please select a mask from the current mask menu');
end

% --- Executes on button press in regionGrowingSegment.
function regionGrowingSegment_Callback(hObject, eventdata, handles)
prj = getappdata(0, 'project');
selectedSource = prj.find_volume(handles.DispItem.String{handles.DispItem.Value}, 'Mask');
if isempty(selectedSource)
    errordlg('The source for ROI segmentation must be a mask not image series');
else
    uiwait(msgbox('Please select points on the segmentation images. Make sure the image is activated!'));
    cMask = prj.find_volume(handles.seg_Masks.String{handles.seg_Masks.Value}, 'Mask');
    
    if strcmp(handles.activeAxesRG.SelectedObject.String, 'Sagittal')
        axPoint = handles.axes1;    
        [newX, newY] = getpts(axPoint); 
        initPoint = [str2double(handles.X_cord.String), round(newY(1)) , round(newX(1))];
    elseif strcmp(handles.activeAxesRG.SelectedObject.String, 'Coronal')
        axPoint = handles.axes2;    
        [newX, newY] = getpts(axPoint); 
        initPoint = [round(newX(1)), str2double(handles.Y_cord.String), size(cMask.data,3) - round(newY(1))];
    elseif strcmp(handles.activeAxesRG.SelectedObject.String, 'Axial')
        axPoint = handles.axes3;    
        [newX, newY] = getpts(axPoint);    
        initPoint = [round(newX(1)), round(newY(1)), str2double(handles.Z_cord.String)];
    end

    [~, mask] = regionGrowingGray(100*selectedSource.data, initPoint([2,1,3]), 50, Inf, [], true, false);
    cMask.edit('RegionGrowing', double(mask));
    
    if isequal(handles.DispItem.String{handles.DispItem.Value}, cMask.name)
        magic_tool_update(handles, 'slice', prj.find_volume(handles.DispItem.String{handles.DispItem.Value}));
    end    
    if handles.Disp3D.Value && (isequal(handles.isoSurfaceMenu.String, cMask.name) ...
            || ismember(cMask.name, handles.isoSurfaceMenu.String(handles.isoSurfaceMenu.Value)))
        magic_tool_update(handles, 'isosurface');
    end
end

% --------------------------------------------------------------------
function combineMaskAction_Callback(hObject, eventdata, handles)
if combineMaskDialog
    update_volumeLists(handles, getappdata(0, 'project'));
end

function filterType_Callback(hObject, eventdata, handles)
switch handles.filterType.Value
    case 1
        set(handles.rangePanel, 'Visible', 'off');
        set(handles.namePanel, 'Visible', 'off');
    case 2
        set(handles.rangePanel, 'Visible', 'off');
        set(handles.namePanel, 'Visible', 'on');
    case 3
        set(handles.namePanel, 'Visible', 'off');
        set(handles.rangePanel, 'Visible', 'on');
end

function cutPlaneBut_Callback(hObject, eventdata, handles) %MA20191010
try
    prj = getappdata(0, 'project');
    clusterMode = 1; %Keeps track of clustering used by magic_tool_update
    tagsMode = 0; %Keeps track of tags used in branch struct
    isImported = 0;
    switch handles.roiDetectionSelect.SelectedObject.Tag
        case 'maskDetection'
            if handles.maskROIMenu.Value == 1
                error(['Use mask option was selected but mask was not specified.' ...
                    ' Please select a mask for ROI detection']);
            else
                %Check if mask should be used as-is
                questionList = {'Exact', 'Exact Keep Tags', 'Cluster', 'Cluster Keep Tags'};
                questionPrompt = 'Use exact mask as-is, or add some clustering?';
                questionName = 'Choose cutplane segmentation';
                [indx,tf] = listdlg('Name', questionName, 'PromptString', questionPrompt, 'ListString',questionList, 'InitialValue', 3, 'SelectionMode', 'single');
                if tf == 0 %If user presses cancel
                    return 
                end
                switch indx
                    case 1
                        clusterMode = 0;
                    case 2
                        clusterMode = 0;
                        tagsMode = 1;
                    case 4
                        tagsMode = 1;
                end
                roiOrigin = prj.find_volume(handles.maskROIMenu.String{handles.maskROIMenu.Value}, 'Mask');
            end
        case 'segmentDetection'
            if handles.maskROIMenu.Value == 1
                error(['Segment image option was selected but image was not specified.' ...
                    ' Please select a image volume for ROI detection']);
            else
                roiOrigin = prj.find_volume(handles.maskROIMenu.String{handles.maskROIMenu.Value}, 'Image');
            end
        case 'autoDetection'
            if ~ismember('pcmra', lower(prj.imageList()))
                error('Clustering ROI detection requires PCMRA');
            end
            roiOrigin = [];            
    end
    
    prj.update_dataSets(handles.DispItem.String);
    dataList = datadlg();
    if ~isempty(dataList)        
        prj.update_dataSets(dataList);
        if isempty(roiOrigin) && ~ismember('PCMRA', prj.get_dataSets())
            prj.update_dataSets({'PCMRA'});
        end
        magic_tool_update(handles, 'cutplane', roiOrigin, isImported, clusterMode, tagsMode); %ClusterMode is 1 unless exact mask use is specified, tagsMode is 0 unless user wants to keep tags

        %Reset gui
        prj.backup_clear();
        set(handles.undoBut, 'Enable', 'off');
        set(handles.dispCutPlaneBut, 'Visible', 'on');
        set(handles.cutplanePanel, 'Visible', 'on');
        set(handles.dispCutPlane, 'Visible', 'on');
        set(handles.dispPointCloud, 'Visible', 'on');
        set(handles.dispCutPlane, 'Enable', 'off');
        set(handles.dispCutPlane, 'Value', 0);
        set(handles.dispPointCloud, 'Value', 0);
        availOperationTable(handles);
        set(handles.plotBut, 'Enable', 'on');
        set(findobj(handles.resultMenu.Children), 'Enable', 'on');
        set(findobj(handles.fileMenu.Children, 'Tag', 'exportPlaneFileAction'), 'Enable', 'on');
    end    
    
catch ME
    keyboard
    delete(findobj(handles.axes4.Children, 'Visible', 'on', '-and', 'Type', 'Surface', '-and', ...
        '-regexp','Tag','_p'));
    uiwait(errordlg({'Cutplane extraction failed please try with different settings', ' ', 'Error Message: ', ME.message}));
end


function dispCutPlaneBut_Callback(hObject, eventdata, handles)
set(findobj(handles.axes4.Children, 'Visible', 'on', '-and', 'Type', 'Surface', '-and', ...
        '-regexp','Tag','_p'), 'Visible', 'off');
for i = get(handles.branchListPlot, 'Value')   
    currentItem = handles.branchListPlot.String{i,:};
    b = str2double(currentItem(1:find(currentItem == '-')-2));    
    set(findobj(handles.axes4.Children, 'Type', 'Surface', '-and', '-regexp','Tag',  ...
        ['b' num2str(b) '_p']), 'Visible', 'on');
end
set(handles.dispCutPlane, 'Enable', 'on', 'Value', 1);

function planeSlider_Callback(hObject, eventdata, handles)
currentItem = handles.branchListPlot.String{get(handles.branchListPlot, 'Value'),:};
b = str2double(currentItem(1:find(currentItem == '-')-2));
set(findobj(handles.axes4.Children, 'Visible', 'on', '-and', 'Type', 'Surface', '-and', ...
        '-regexp','Tag',['b' num2str(b) '_p']), 'Visible', 'off');
    
ind = floor(handles.planeSlider.Value);
h1 = findobj(handles.axes4.Children, 'Type', 'Surface', '-and', 'Tag', sprintf('b%d_p%d', b, ind));
set(h1, 'Visible', 'on');

magic_tool_update(handles, 'parameters', b, ind);
magic_tool_update(handles, '2DPlot', b, ind);
magic_tool_update(handles, '3DPlot', b, ind);

set(handles.dispCutPlane, 'Enable', 'on', 'Value', 1);

function DispCutPlot_Callback(hObject, eventdata, handles)
if handles.DispCutPlot.Value
    set(handles.cutPlanePanel, 'Visible', 'on');
    %This plot is made in magic_tool_update: 2DPlot
else
    set(handles.cutPlanePanel, 'Visible', 'off');
end

% --- Executes on button press in closeCutPlotPanel.
function closeCutPlotPanel_Callback(hObject, eventdata, handles)
set(handles.cutPlanePanel, 'Visible', 'off');
set(handles.DispCutPlot, 'Value', 0);


function dispCutPlane_Callback(hObject, eventdata, handles)
if ~handles.dispCutPlane.Value
    set(findobj(handles.axes4.Children, 'Type', 'Surface', '-and', '-regexp','Tag','_p', ...
        '-and', 'Visible', 'on'), 'Visible', 'off');
    set(handles.dispCutPlane, 'Enable', 'off');
end

function plotMenu_Callback(hObject, eventdata, handles)
if ~isempty(handles.branchListPlot.Value)
    currentItem = handles.branchListPlot.String{get(handles.branchListPlot, 'Value'),:};
    b = str2double(currentItem(1:find(currentItem == '-')-2));
    ind = floor(handles.planeSlider.Value);
    magic_tool_update(handles, '2DPlot', b, ind);
else
    msgbox('Please select a vessel from the list');
end

function dispPointCloud_Callback(hObject, eventdata, handles)
if handles.dispPointCloud.Value    
    magic_tool_update(handles, 'pointcloud');
else
    delete(findobj(handles.axes4.Children, 'Tag', 'pointcloud'));
end

function thresholdSlider_Callback(hObject, eventdata, handles)
segment_threshold(handles, 'slider');

function thresholdValueTxt_Callback(hObject, eventdata, handles)
threshold = str2double(handles.thresholdValueTxt.String);
if threshold > handles.thresholdSlider.Max || threshold < handles.thresholdSlider.Min
    msgbox(sprintf('Threshold value must be between %.1f and %.1f', ...
        handles.thresholdSlider.Min, handles.thresholdSlider.Max));
else
    segment_threshold(handles, 'text');
end

function segment_threshold(handles, command)
%keyboard
cProject = getappdata(0, 'project');
activeMask = cProject.find_volume(handles.seg_Masks.String{handles.seg_Masks.Value}, 'Mask');
if isempty(activeMask)
    msgbox('selecte a mask to edit or make a new one');
else
    if ~isempty(activeMask) && isa(activeMask.parent, 'ImageSeries')
        switch command
            case 'slider'
                activeMask.edit('Thresholding', handles.thresholdSlider.Value);
                set(handles.ThresholdDisplay, 'String', handles.thresholdSlider.Value);
                set(handles.thresholdValueTxt, 'String', handles.thresholdSlider.Value);
            case 'text'
                activeMask.edit('Thresholding', str2double(handles.thresholdValueTxt.String));
                set(handles.thresholdSlider, 'Value', str2double(handles.thresholdValueTxt.String));                
        end
        
        if isequal(handles.DispItem.String{handles.DispItem.Value}, activeMask.name)
            magic_tool_update(handles, 'slice', activeMask);    
        end

        if handles.Disp3D.Value && (isequal(handles.isoSurfaceMenu.String, activeMask.name) ...
                || ismember(activeMask.name, handles.isoSurfaceMenu.String))
            magic_tool_update(handles, 'isosurface');
        end
    else
        uiwait(msgbox('The selected mask is not associated with any image volume in the project'));
    end
end

function plotBut_Callback(hObject, eventdata, handles)
set(handles.tab1Panel, 'Visible', 'off');
set(handles.tab2Panel, 'Visible', 'off');
set(handles.tab3Panel, 'Visible', 'on');
set(handles.branchListPlot, 'String', handles.VesselTable.Data(:,1));
set(handles.branchListPlot, 'min', 0, 'max', 2);
set(handles.branchListPlot, 'Value', []);
set(handles.dispCutPlaneBut, 'Enable', 'off');
set(handles.planeSlider, 'Enable', 'off');
set(handles.plotItemMenu, 'Enable', 'off');
set(handles.medianFilterPlot, 'Enable', 'off');
set(handles.parPlotBut, 'Enable', 'off');
set(handles.PDEstimationPanel, 'Visible', 'off');
set(handles.normalVesselMenu, 'Value', 1);
set(handles.FromBut, 'Visible', 'off');
set(handles.SelectToBut, 'String', 'Select');
set(handles.NormalPlaneTxt, 'String', []);
set(handles.StenoticPlaneTxt, 'String', []);
set(handles.PDValueTxt, 'String', []);


function plotItemMenu_Callback(hObject, eventdata, handles)
if handles.plotItemMenu.Value == 5
    set(handles.medianFilterPlot, 'Value', 0);
    set(handles.medianFilterPlot, 'Enable', 'off');
else
    set(handles.medianFilterPlot, 'Enable', 'on');
end

function parPlotBut_Callback(hObject, eventdata, handles)
magic_tool_update(handles, 'parameterPlot');
set(handles.plotPanel, 'Visible', 'on');

function closePlotBut_Callback(hObject, eventdata, handles)
set(handles.plotPanel, 'Visible', 'off');
cla(handles.axesParPlot);

% --------------------------------------------------------------------
function showNetworkAction_Callback(hObject, eventdata, handles)
magic_tool_update([], 'Branch_statistics');
diagramDialog;

% --------------------------------------------------------------------
function showFDNGAction_Callback(hObject, eventdata, handles)
magic_tool_update([], 'Branch_statistics');
networkDialog;

function flowDiagromBut_Callback(hObject, eventdata, handles)
magic_tool_update([], 'Branch_statistics');
diagramDialog;

function flowNetworkBut_Callback(hObject, eventdata, handles)
magic_tool_update([], 'Branch_statistics');
networkDialog;

function mainGUI_CloseRequestFcn(hObject, eventdata, handles)

if isappdata(0,'edges')
    rmappdata(0,'edges');
end

if isappdata(0,'vertices')
    rmappdata(0,'vertices');
end

if isappdata(0,'metric')
    rmappdata(0,'metric');
end

if isappdata(0, 'selectedVessels')
    rmappdata(0, 'selectedVessels');
end

if isappdata(0, 'project')
    currentProject = getappdata(0, 'project');
    if ~isempty(currentProject)
        currentProject.remove();
    end
    rmappdata(0, 'project');
end

delete(hObject);

function bodyPartMenu_Callback(hObject, eventdata, handles)
switch handles.bodyPartMenu.Value
    case 1
        labels = {  'LACA'; 'RACA'; 'LMCA'; 'RMCA'; 'LICA'; 'RICA'; 'LPCA'; 'RPCA'; 'BA'; ...
                    'LMCA-M1'; 'LMCA-M2'; 'LMCA-M3'; 'LMCA-M4'; ...
                    'RMCA-M1'; 'RMCA-M2'; 'RMCA-M3'; 'RMCA-M4'; ...
                    'LICA-C1'; 'LICA-C2-C4'; 'LICA-C5-C7'; ...
                    'RICA-C1'; 'RICA-C2-C4'; 'RICA-C5-C7'; ...
                    'LTS'; 'RTS'; 'SSS'; 'STR'; ...
                    'LPCOM'; 'RPCOM'; 'LPPCA'; 'RPPCA'; 'LSCA'; 'RSCA'; ...
                    'LVA'; 'RVA'};
        set(handles.nameMenu, 'String', labels);
        set(handles.cPlaneLen, 'String', '10.0');
        set(handles.cPlaneWid, 'String', '10.0');
        set(handles.cPlaneRes, 'String', '0.25');
        set(handles.cPlaneDist, 'String', '4.0');
    
    case 2
        labels = {  'LCA'; 'RCA'; 'LICA'; 'RICA'; 'LECA'; 'RECA'  };
        set(handles.nameMenu, 'String', labels);
        set(handles.cPlaneLen, 'String', '15.0');
        set(handles.cPlaneWid, 'String', '15.0');
        set(handles.cPlaneRes, 'String', '0.25');
        set(handles.cPlaneDist, 'String', '4.0');
        
    case 3
        labels = {  'AAO'; 'ARCH'; 'DAO'  };
        set(handles.nameMenu, 'String', labels);
        set(handles.cPlaneLen, 'String', '40.0');
        set(handles.cPlaneWid, 'String', '40.0');
        set(handles.cPlaneRes, 'String', '1');
        set(handles.cPlaneDist, 'String', '4.0');
        
    case 4
        labels = {  'Aorta', 'RHA', 'LHA', 'CHA', 'PHA', 'Celiac', ...
                  'SA', 'GA', 'SMA', 'RHEP', 'LHEP', 'MIDHEP', 'IVC', ...
                  'RPV', 'LPV', 'MPVdist', 'MPVprox', 'Umb', 'Cor', 'SV', 'SMV', 'SRS'};
        set(handles.nameMenu, 'String', labels);
        set(handles.cPlaneLen, 'String', '40.0');
        set(handles.cPlaneWid, 'String', '40.0');
        set(handles.cPlaneRes, 'String', '1');
        set(handles.cPlaneDist, 'String', '4.0');
end

% --------------------------------------------------------------------
function saveAverageResultsAction_Callback(hObject, eventdata, handles)
magic_tool_update(handles, 'Branch_statistics');

prj = getappdata(0, 'project');
[fileName, pathName] = uiputfile('*.xlsx', 'Save data as', fullfile(prj.workingDirectory, 'flowdata.xlsx'));
if ~isequal(pathName, 0) && ~isequal(fileName, 0)
    try
        if exist(fullfile(pathName,fileName), 'file')
            fout = fopen(fullfile(pathName,fileName), 'w');
            if fout == -1
                error([fileName ' is open in another application and cannot be overwritten. Please close the file and try again']);
            else
                fclose(fout);
                delete(fullfile(pathName,fileName));       
            end            
        end
        branchStruct = prj.branches;
        
        h = busydlg('', 'Saving to file...');

        sheets = cellfun(@(x) [num2str(x.id) '-' x.name], branchStruct, 'UniformOutput', false);    
        warning('off','MATLAB:xlswrite:AddSheet'); %Initialize data output
        
        headers = { 'Length(mm)', 'Area(mm^2)', 'Total flow/cycle(ml)', ...
                    'Mean Flowrate (ml/s)', 'Peak Velocity(m/s)', 'Mean Velocity(m/s)', ...
                    'Std Velocity(m/s)', 'Median Velocity(m/s)', 'Interquartile Range(m/s)'};

        title = cell(1, length(headers));
        for b = 1:length(branchStruct)
            title(1,1) = sheets(b);
            planesToSave = (branchStruct{b}.cPlaneTags(:,1)==1);
            data = [title; headers; num2cell(zeros(size(branchStruct{b}.cPoints(planesToSave,4),1),length(headers)))];
            data(3:end,1) = num2cell(branchStruct{b}.cPoints(planesToSave,4));
            data(3:end,2) = cellfun(@(x) x(1),branchStruct{b}.cPlane(planesToSave,4),'UniformOutput', false);
            data(3:end,3) = cellfun(@(x) x(2),branchStruct{b}.cPlane(planesToSave,4),'UniformOutput', false);
            data(3:end,4) = cellfun(@(x) x(3),branchStruct{b}.cPlane(planesToSave,4),'UniformOutput', false);
            data(3:end,5) = cellfun(@(x) x(4),branchStruct{b}.cPlane(planesToSave,4),'UniformOutput', false);
            data(3:end,6) = cellfun(@(x) x(5),branchStruct{b}.cPlane(planesToSave,4),'UniformOutput', false);
            data(3:end,7) = cellfun(@(x) x(6),branchStruct{b}.cPlane(planesToSave,4),'UniformOutput', false);
            data(3:end,8) = cellfun(@(x) x(7),branchStruct{b}.cPlane(planesToSave,4),'UniformOutput', false);
            data(3:end,9) = cellfun(@(x) x(8),branchStruct{b}.cPlane(planesToSave,4),'UniformOutput', false);

            writetable(cell2table(data), fullfile(pathName,fileName), 'Sheet', b, 'WriteVariableNames', false);
        end
        close(h);
        msgbox('File Saved!');
    catch ME
        errordlg(ME.message);
    end
end

% --------------------------------------------------------------------
function saveTransientResultAction_Callback(hObject, eventdata, handles)
magic_tool_update(handles, 'Branch_statistics');

prj = getappdata(0, 'project');
[fileName, pathName] = uiputfile('*.xlsx', 'Save data as', fullfile(prj.workingDirectory, 'transient_flowdata.xlsx'));
if ~isequal(pathName, 0) && ~isequal(fileName, 0)
    try
        if exist(fullfile(pathName,fileName), 'file')
            fout = fopen(fullfile(pathName,fileName), 'w');
            if fout == -1
                error([fileName ' is open in another application and cannot be overwritten. Please close the file and try again']);
            else
                fclose(fout);
                delete(fullfile(pathName,fileName));       
            end            
        end        
        nTimeFrames = size(prj.mag.dataAy, 4);
        branchStruct = prj.branches;
        timeRes = prj.mag.tr;
        timePoints = prj.mag.user.timePoints';
        
        h = busydlg('', 'Saving to file...');

        sheets = cellfun(@(x) [num2str(x.id) '-' x.name], branchStruct, 'UniformOutput', false);    
        warning('off','MATLAB:xlswrite:AddSheet'); %Initialize data output

        times = cellfun(@(x) sprintf('t = %.1f(ms)', x), num2cell(timePoints), 'UniformOutput', false);
        parameters = {'Flowrate', 'Mean Velocity', 'Std Velocity', 'Median Velocity', 'Peak Velocity', '95PercentileVelocity'}; 
        headers = cellfun(@(x) cellfun(@(y) sprintf('%s | %s',x,y),times,'UniformOutput',false), parameters,'UniformOutput',false);
        headers = ['Length(mm)', headers{:}];
        title = cell(1, length(headers));
        for b = 1:length(branchStruct)
            title(1,1) = sheets(b);
            planesToSave = (branchStruct{b}.cPlaneTags(:,1)==1);
            data = [title; headers; num2cell(zeros(size(branchStruct{b}.cPoints(planesToSave,4),1),length(headers)))];
            cellData = cellfun(@num2cell, cellfun(@(x) x{4}(:), branchStruct{b}.cPlane(planesToSave,3), 'UniformOutput', false),'UniformOutput', false);
            data(3:end,1) = num2cell(branchStruct{b}.cPoints(planesToSave,4));
            data(3:end,2:end) = [cellData{:}]';            
            writetable(cell2table(data), fullfile(pathName,fileName), 'Sheet', b, 'WriteVariableNames', false);
        end
        close(h);
        msgbox('File Saved!');
    catch ME
        errordlg(ME.message);
    end
end

%Goes through tagged planes and saves velocity, mask and time vector per plane
function savePlaneDataAction_Callback(hObject, eventdata, handles)
magic_tool_update(handles, 'Branch_statistics');

%Get info from project
cProject = getappdata(0, 'project');
dataList = cProject.get_dataSets();
branchStruct = cProject.branches;
timePoints = cProject.mag.user.timePoints(1:size(cProject.vel.dataAy, 5)); %cProject.mag.user.timePoints has extra points to account for RR interval

%Figure out where to save
filePath = uigetdir(cProject.workingDirectory, 'Save plane data files in directory');
if ~isequal(filePath, 0)
    try
        h = busydlg('', 'Saving to file...');

        %Loop over branches
        for b = 1:length(branchStruct)
            planesToSave = find(branchStruct{b}.cPlaneTags(:,2)==1);
            %If a plane is tagged for saving, save it
            for i = 1:1:length(planesToSave) %Plane index
                ind = planesToSave(i);
                %Get data for this plane
                planedatatitle = ['planedata_', branchStruct{b}.name, '_', num2str(ind), '.mat']; %Default filename to save
                planedataStruct = struct('XVelocity',[], 'YVelocity',[], 'ZVelocity',[], 'Mask',[], 'OtherMasks', [], 'Times',[], 'CoordinateTransform', []);
                planedataStruct.XVelocity = reshape(branchStruct{b}.cPlane{ind,3}{1}, [branchStruct{b}.planeDim length(timePoints)]);%3D location x, location y, time
                planedataStruct.YVelocity = reshape(branchStruct{b}.cPlane{ind,3}{2}, [branchStruct{b}.planeDim length(timePoints)]);
                planedataStruct.ZVelocity = reshape(branchStruct{b}.cPlane{ind,3}{3}, [branchStruct{b}.planeDim length(timePoints)]);
                planedataStruct.Mask = (reshape(branchStruct{b}.cPlane{ind,1}(:,9), branchStruct{b}.planeDim))';%2D binary mask for this plane. Flip X/Y to match velocity
                %Save all other masks %MA20191010
                if length(dataList) > 3
                    for otherMask_i = 1:1:length(dataList) - 3
                        planedataStruct.OtherMasks{otherMask_i, 1} = handles.plotMenu.String{3+otherMask_i, 1};
                        planedataStruct.OtherMasks{otherMask_i, 2} = (reshape(branchStruct{b}.cPlane{ind,1}(:,9+otherMask_i), branchStruct{b}.planeDim))';
                    end
                end
                planedataStruct.Times = timePoints;%Time vector: same for all planes, save here for convenience
                planedataStruct.Resolution = str2double(handles.cPlaneRes.String);
                RotationMatrix = [[vrrotvec2mat(branchStruct{b}.cRotate(ind,:)) branchStruct{b}.cPoints(ind,1:3)']; [0 0 0 1]]; %Transformation matrix
               
                RotationMatrix = RotationMatrix(1:3, 1:3);
                NewCoords = RotationMatrix*[1 0 0; 0 1 0; 0 0 1];
                planedataStruct.CoordinateTransform = NewCoords; %3x3 transformation matrix from global to plane coordinates.

                %Save
                save(fullfile(filePath, planedatatitle), 'planedataStruct');

                %Check: NewCoords(3, :) == branchStruct{b}.cNormal(ind, :)
                %A = zeros(3, size(branchStruct{b}.cPlane{ind,3}{1}, 1), size(branchStruct{b}.cPlane{ind,3}{1}, 2));
                %for dim = 1:1:3
                %    A(dim, :, :) = branchStruct{b}.cPlane{ind,3}{dim};
                %end
                %Find values in new coordinate system
                %ANew = zeros(size(A));
                %for t = 1:1:length(timePoints)
                %    ANew(:, :, t) = NewCoords*squeeze(A(:, :, t));
                %end
            end
        end

        close(h);
        msgbox('Files Saved!');
    catch ME
        errordlg(ME.message);
    end
end

function saveFileBut_Callback(hObject, eventdata, handles)
%removed

%--------------------------------------------------------
%Clears save tag
function ClearTag_Save_Action_Callback(hObject, eventdata, handles)
%Get info from project
cProject = getappdata(0, 'project');
branchStruct = cProject.branches;
%Loop over branches
for b = 1:length(branchStruct)
    branchStruct{b}.cPlaneTags(:,2) = 0; %savePlaneData = 0
end

%Clears exclude tag
function ClearTag_Exclude_Action_Callback(hObject, eventdata, handles)
%Get info from project
cProject = getappdata(0, 'project');
branchStruct = cProject.branches;
%Loop over branches
for b = 1:length(branchStruct)
    branchStruct{b}.cPlaneTags(:,1) = 1; %includeData = 1
end

%--------------------------------------------------------

function medianFilterPlot_Callback(hObject, eventdata, handles)
magic_tool_update(handles, 'parameterPlot');
set(handles.plotPanel, 'Visible', 'on');

function coordRadioBut_Callback(hObject, eventdata, handles)
set(handles.EnSightFormat, 'Visible', 'on');

function IndicesRadioBut_Callback(hObject, eventdata, handles)
set(handles.EnSightFormat, 'Visible', 'off');
set(handles.EnSightFormat, 'Value', 0);

% --- Executes on button press in RRCheckBox.
function RRCheckBox_Callback(hObject, eventdata, handles)
prj = getappdata(0, 'project');
if handles.RRCheckBox.Value
    RR = 0; %Initialize to 0
    if isfield(prj.mag.user, 'nominal_interval')
        RR = prj.mag.user.nominal_interval;
    end
    if RR == 0 %If RR wasn't changed by mrstruct data
        answer = inputdlg('Enter R-R interval length in ms');
        if ~isempty(answer) % >>> more error checking is required here
            RR = str2double(answer{1});
        end
    end
    %Store
    prj.mag.user.RR = RR;
    if RR ~= 0 %If some kind of value was input display it
        set(handles.RRValue, 'String', num2str(RR));
        set(handles.RRValue, 'Visible', 'on');
        set(handles.msUnitTxt, 'Visible', 'on');
    else
        set(handles.RRCheckBox, 'Value', 0);
    end
else
    set(handles.RRValue, 'String', '');
    set(handles.RRValue, 'Visible', 'off');
    set(handles.msUnitTxt, 'Visible', 'off');
    prj.mag.user.RR = 0;
end


% --------------------------------------------------------------------
function createVesselAction_Callback(hObject, eventdata, handles)
% hObject    handle to createVesselAction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function importMenu_Callback(hObject, eventdata, handles)
% hObject    handle to importMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function exportMenu_Callback(hObject, eventdata, handles)
% hObject    handle to exportMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function toolsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to toolsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function cropVolumeAction_Callback(hObject, eventdata, handles)
prj = getappdata(0, 'project');
set(handles.segThreshPanel, 'Visible', 'off');
set(handles.segROIPanel, 'Visible', 'off');
set(handles.segRGPanel, 'Visible', 'off');
set(handles.cropPanel, 'Visible', 'on');
set(handles.seg_Selection, 'Visible', 'off');
set(handles.registerPanel, 'Visible', 'off');
set(handles.applyCropBut, 'Enable', 'off');
set(handles.cropVolumePreviewBut, 'Enable', 'off');
set(handles.cancelCropBut, 'Enable', 'off');
set(handles.BaseVolumeMenu, 'String', [{''}, prj.imageList()]);


function show_preview(handles)
prj = getappdata(0, 'project');
selectedVolume = prj.find_volume(handles.BaseVolumeMenu.String{handles.BaseVolumeMenu.Value}, 'Image');
if strcmp(handles.activeAxesCrop.SelectedObject.String, 'Sagittal')
    ax_name = 'axes1';   
elseif strcmp(handles.activeAxesCrop.SelectedObject.String, 'Coronal')
    ax_name = 'axes2';
elseif strcmp(handles.activeAxesCrop.SelectedObject.String, 'Axial')
    ax_name = 'axes3';
end
h = findobj(handles.(ax_name).Children, 'Tag', 'cropRect');
lines = findobj(h.Children, 'Type', 'Line');

box = zeros(17,3);
firstCorner = findobj(lines, 'Tag', 'minx miny corner marker');
firstCorner = round([firstCorner.XData ; firstCorner.YData]);
secondCorner = findobj(lines, 'Tag', 'maxx maxy corner marker');
secondCorner = round([secondCorner.XData ; secondCorner.YData]);

switch handles.activeAxesCrop.SelectedObject.String
    case 'Sagittal'
        cropRange = [[0; firstCorner([2,1])], [size(selectedVolume.data,2); secondCorner([2,1])]];
    case 'Coronal'
        cropRange = [[firstCorner(1) ; 0 ; size(selectedVolume.data, 3) - secondCorner(2)], ...
            [secondCorner(1) ; size(selectedVolume.data,1); size(selectedVolume.data, 3) - firstCorner(2)]];
    case 'Axial'
        cropRange = [[firstCorner ; 0], [secondCorner ; size(selectedVolume.data,3)]];       
end
box(:,1) = selectedVolume.fov(2,1) + (cropRange(1,1) + [0 0 1 1 0 0 1 1 1 1 1 1 0 0 0 0 0]* ...
    (cropRange(1,2) - cropRange(1,1))).*selectedVolume.vox(1);
box(:,2) = selectedVolume.fov(1,1) + (cropRange(2,1) + [0 1 1 0 0 0 0 0 0 1 1 1 1 1 1 0 0]* ...
    (cropRange(2,2) - cropRange(2,1)))*selectedVolume.vox(2);
box(:,3) = selectedVolume.fov(3,1) + (cropRange(3,1) + [0 0 0 0 0 1 1 0 1 1 0 1 1 0 1 1 0]* ...
    (cropRange(3,2) - cropRange(3,1))).*selectedVolume.vox(3);

axx = handles.axes4;
ax_lim = getappdata(0, 'view_lim');
ax_lim = [arrayfun(@min, ax_lim(:,1), min(box)'), ...
            arrayfun(@max, ax_lim(:,2), max(box)')];
hold(axx, 'on');
plot3(axx, box(:,1), box(:,2), box(:,3), 'r--', 'LineWidth',1.5, 'Tag', sprintf('cropPreview_%s', ax_name));
hold(axx, 'off');
set(handles.cancelCropBut, 'Enable', 'on');
set(handles.axes4,'xlim', ax_lim(1,:), ...
    'ylim', ax_lim(2,:), ...
    'zlim', ax_lim(3,:));
rotate3d on;

function cropVolumePreviewBut_Callback(hObject, eventdata, handles)
if handles.BaseVolumeMenu.Value == 1
    msgbox('Please select a base volume');
elseif ~isequal(handles.BaseVolumeMenu.String{handles.BaseVolumeMenu.Value}, ...
        handles.DispItem.String{handles.DispItem.Value})
    msgbox(sprintf('The base volume is not the active image in 2D views please switch the 2D views into %s', ...
        handles.BaseVolumeMenu.String{handles.BaseVolumeMenu.Value}));
else
    show_preview(handles);
end

function cancelCropBut_Callback(hObject, eventdata, handles)
L = findobj(handles.axes4.Children, 'Type', 'Line', '-and', '-regexp', 'Tag', 'cropPreview');
ax_name = strsplit(L.Tag, '_');
ax_name = ax_name{2};    
delete(findobj(handles.(ax_name).Children, 'Tag', 'cropRect'));
delete(L);
ax_lim = getappdata(0, 'view_lim');
set(handles.axes4,'xlim', ax_lim(1,:), ...
    'ylim', ax_lim(2,:), ...
    'zlim', ax_lim(3,:));
set(handles.applyCropBut, 'Enable', 'off');
set(handles.cropVolumePreviewBut, 'Enable', 'off');
set(handles.cancelCropBut, 'Enable', 'off');

% --- Executes on button press in applyCropBut.
function applyCropBut_Callback(hObject, eventdata, handles)
prj = getappdata(0, 'project');
if handles.BaseVolumeMenu.Value == 1
    msgbox('Please select a base volume');
elseif ~isequal(handles.BaseVolumeMenu.String{handles.BaseVolumeMenu.Value}, ...
        handles.DispItem.String{handles.DispItem.Value})
    msgbox(sprintf('The base volume is not the active image in 2D views please switch the 2D views into %s', ...
        handles.BaseVolumeMenu.String{handles.BaseVolumeMenu.Value}));
else
    selectedVolume = prj.find_volume(handles.BaseVolumeMenu.String{handles.BaseVolumeMenu.Value}, 'Image');
    axx = handles.axes4;
    if isempty(findobj(axx.Children, 'Type', 'Line', '-and', '-regexp', 'Tag', 'cropPreview'))
        show_preview(handles);
    end
    answer = questdlg(sprintf('Are you sure you would like to crop %s with the box?', selectedVolume.name));
    L = findobj(axx.Children, 'Type', 'Line', '-and', '-regexp', 'Tag', 'cropPreview');
    ax_name = strsplit(L.Tag, '_');
    ax_name = ax_name{2};    
    h = findobj(handles.(ax_name).Children, 'Tag', 'cropRect');    
    if isequal(answer, 'Yes')        
        lines = findobj(h.Children, 'Type', 'Line');
        firstCorner = findobj(lines, 'Tag', 'minx miny corner marker');
        firstCorner = round([firstCorner.XData ; firstCorner.YData]);
        secondCorner = findobj(lines, 'Tag', 'maxx maxy corner marker');
        secondCorner = round([secondCorner.XData ; secondCorner.YData]);
        switch ax_name
            case 'axes1'
                cropRange = [[0; firstCorner([2,1])], [size(selectedVolume.data,2); secondCorner([2,1])]];
            case 'axes2'
                cropRange = [[firstCorner(1) ; 0 ; size(selectedVolume.data, 3) - secondCorner(2)], ...
                    [secondCorner(1) ; size(selectedVolume.data,1); size(selectedVolume.data, 3) - firstCorner(2)]];
            case 'axes3'
                cropRange = [[firstCorner ; 0], [secondCorner ; size(selectedVolume.data,3)]];
        end     
        if ismember(handles.ResultVolumeTxt.String, handles.DispItem.String)            
            if ~isequal(handles.BaseVolumeMenu.String{handles.BaseVolumeMenu.Value}, ...
                    handles.ResultVolumeTxt.String)
                msgbox('To crop an existing volume the base and result must be the same volume');
            else                
                selectedVolume.crop(cropRange([2,1,3], :));
                adjustSliders(handles, size(selectedVolume.data));
                magic_tool_update(handles, 'slice', selectedVolume);
                if handles.dispBox.Value
                    magic_tool_update(handles, 'box', selectedVolume);
                end
            end            
        else
            prj.imageSeries{end+1} = selectedVolume.copy();
            prj.imageSeries{end}.name = handles.ResultVolumeTxt.String;
            prj.imageSeries{end}.crop(cropRange([2,1,3],:));            
        end
    end
    delete(h);
    delete(L);
    ax_lim = getappdata(0, 'view_lim');
    set(handles.axes4,'xlim', ax_lim(1,:), ...
        'ylim', ax_lim(2,:), ...
        'zlim', ax_lim(3,:));
    set(handles.applyCropBut, 'Enable', 'off');
    set(handles.cropVolumePreviewBut, 'Enable', 'off');
    set(handles.cancelCropBut, 'Enable', 'off');
    update_volumeLists(handles, prj, 0);
end

% --- Executes on button press in newVolumeBut.
function newVolumeBut_Callback(hObject, eventdata, handles)
if get(handles.BaseVolumeMenu, 'Value') == 1
    msgbox('Please select a base volume first');
else
    name = inputdlg('Enter the name of the new volume');
    while ~isempty(name) && ismember(name, handles.DispItem.String)
        name = inputdlg('Another volume with the same name exists please a unique name for the volume');
    end
    if ~isempty(name)    
        set(handles.ResultVolumeTxt, 'String', name{1});
    end
end

% --- Executes on button press in roiCropBut.
function roiCropBut_Callback(hObject, eventdata, handles)
if handles.BaseVolumeMenu.Value == 1
    msgbox('Please select a base volume');
elseif ~isequal(handles.BaseVolumeMenu.String{handles.BaseVolumeMenu.Value}, ...
        handles.DispItem.String{handles.DispItem.Value})
    msgbox(sprintf('The base volume is not the active image in 2D views please switch the 2D views into %s', ...
        handles.BaseVolumeMenu.String{handles.BaseVolumeMenu.Value}));
else
    if strcmp(handles.activeAxesCrop.SelectedObject.String, 'Sagittal')
        ax = handles.axes1; 
    elseif strcmp(handles.activeAxesCrop.SelectedObject.String, 'Coronal')
        ax = handles.axes2;  
    elseif strcmp(handles.activeAxesCrop.SelectedObject.String, 'Axial')
        ax = handles.axes3;   
    end
    delete(findobj(ax.Children, 'Tag', 'cropRect'));
    h = imrect(ax);
    set(h, 'Tag', 'cropRect');
    set(handles.cropVolumePreviewBut, 'Enable', 'On');
    set(handles.applyCropBut, 'Enable', 'On');
end

% --------------------------------------------------------------------
function segmentMenu_Callback(hObject, eventdata, handles)
% hObject    handle to segmentMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function thresholdingAction_Callback(hObject, eventdata, handles)
set(handles.segThreshPanel, 'Visible', 'on');
set(handles.segROIPanel, 'Visible', 'off');
set(handles.segRGPanel, 'Visible', 'off');
set(handles.cropPanel, 'Visible', 'off');
set(handles.seg_Selection, 'Visible', 'On');
set(handles.registerPanel, 'Visible', 'off');

% --------------------------------------------------------------------
function roiAction_Callback(hObject, eventdata, handles)
set(handles.segThreshPanel, 'Visible', 'off');
set(handles.segROIPanel, 'Visible', 'on');
set(handles.segRGPanel, 'Visible', 'off');
set(handles.cropPanel, 'Visible', 'off');
set(handles.seg_Selection, 'Visible', 'On');
set(handles.registerPanel, 'Visible', 'off');

% --------------------------------------------------------------------
function regionGrowingAction_Callback(hObject, eventdata, handles)
set(handles.segThreshPanel, 'Visible', 'off');
set(handles.segROIPanel, 'Visible', 'off');
set(handles.segRGPanel, 'Visible', 'on');
set(handles.cropPanel, 'Visible', 'off');
set(handles.seg_Selection, 'Visible', 'On');
set(handles.registerPanel, 'Visible', 'off');

% --------------------------------------------------------------------
function cleanBackgroungNoiseAction_Callback(hObject, eventdata, handles)
prj = getappdata(0, 'project');
selectedVolume = prj.find_volume(handles.DispItem.String{handles.DispItem.Value});
if ~isa(selectedVolume, 'Mask')
    msgbox('The active volume must be a mask for background noise removal');
else
    selectedVolume.data = double(bwareaopen(selectedVolume.data, floor(200/min(selectedVolume.vox)), 6));
    magic_tool_update(handles, 'slice', selectedVolume);
    magic_tool_update(handles, 'isosurface');
end
    
% --------------------------------------------------------------------
function MLsegmentationAction_Callback(hObject, eventdata, handles) %MA20191119 - integration with Haben's IC_Seg
prj = getappdata(0, 'project');
magFile = prj.mag.user.path;
velFile = prj.vel.user.path;
maskName = 'ML_segmentation';
%Try to make the mask
try
   maskStruct = IC_Seg_tool(velFile, magFile, 0);
catch 
   %If it didn't work
   msgbox('ML segmentation failed, try using IC_Seg_tool as standalone and importing the result as a struct')
   return
end 
%If it worked
msgbox(['A new ML mask was saved to ' maskStruct])
%From here on out the procedure is like you are loading a mask
importedMask = matfile(maskStruct);
f = fields(importedMask);
importedMask = importedMask.(f{cellfun(@(x) contains(x, 'mrstruct', 'ignoreCase', true), fields(importedMask))});        

if isequal(importedMask.dim11, 'unused')
    maskFOV = [zeros(3,1), (importedMask.vox(1:3).*size(importedMask.dataAy))'];
else
    maskFOV = reshape(cellfun(@str2double, strsplit(importedMask.dim11, ',')), 3, 2);
end
if isequal(importedMask.dim10, 'unused')
    importedMask.interpFactor=1;
else
    importedMask.interpFactor=str2double(importedMask.dim10);
end
prj.add_mask(Mask(maskName, 1, [], 'IMPORTED', importedMask.dataAy, ...
        importedMask.vox(1:3), maskFOV, importedMask.edges, importedMask.interpFactor));

update_volumeLists(handles, prj);
msgbox('Mask Imported!');

% --- Executes when selected cell(s) is changed in VesselTable.
function VesselTable_CellSelectionCallback(hObject, eventdata, handles)
if ~isempty(eventdata.Indices)
    selectedVesselRows = eventdata.Indices(:,1);
    selectedVesselRows(eventdata.Indices(:,2) == 2) = [];
    setappdata(0, 'selectedVessels', selectedVesselRows');
    availOperationTable(handles);
end

% --- Executes on button press in onBut.
function onBut_Callback(hObject, eventdata, handles)
changeDisplay(handles, 1);

% --- Executes on button press in offBut.
function offBut_Callback(hObject, eventdata, handles)
changeDisplay(handles, 0);

function changeDisplay(handles, state)
findVessels = [];
prj = getappdata(0, 'project');

switch handles.filterType.Value
    case 1
        findVessels = getappdata(0,'selectedVessels');
    
    case 2
        name = get(handles.nameSearch, 'String');
        vesselList = handles.VesselTable.Data(:,1);
        findVessels = find(cellfun(@(x) contains(lower(x), lower(name)), vesselList))';        

    case 3        
        vesselLength = cellfun(@length, cellfun(@(x) x.pList, prj.branches, 'UniformOutput', false));
        if strcmpi(handles.maxRange.String, 'max')
            set(handles.maxRange, 'String', num2str(max(vesselLength)));
        end
        if strcmpi(handles.minRange.String, 'min')
            set(handles.minRange, 'String', num2str(min(vesselLength)));
        end
        
        findVessels = find( vesselLength >= str2double(handles.minRange.String) ...
                            & vesselLength <= str2double(handles.maxRange.String));
end
switch state % switch on/off
    case 1
        for i = findVessels
            currentVessel = handles.VesselTable.Data{i,1};
            handles.VesselTable.Data{i,2} = 'on';
            prj.branches{cellfun(@(x) x.id, prj.branches) == str2double(currentVessel(1:find(currentVessel == '-')-1))}.visibility = 'on';
            set(findobj(handles.axes4.Children, 'Type', 'line', '-and', 'Visible', 'off', '-and', ...
            '-regexp','Tag',sprintf('_%d_CL', str2double(currentVessel(1:find(currentVessel == '-')-1)))), 'Visible', 'on');
        end
    case 0
        for i = findVessels
            currentVessel = handles.VesselTable.Data{i,1};
            handles.VesselTable.Data{i,2} = 'off';
            prj.branches{cellfun(@(x) x.id, prj.branches) == str2double(currentVessel(1:find(currentVessel == '-')-1))}.visibility = 'off';
            set(findobj(handles.axes4.Children, 'Type', 'line', '-and', 'Visible', 'on', '-and', ...
            '-regexp','Tag',sprintf('_%d_CL', str2double(currentVessel(1:find(currentVessel == '-')-1)))), 'Visible', 'off');
        end
end
magic_tool_update(handles, 'label');
setappdata(0, 'selectedVessels', []);

% --- Executes on button press in deleteHiddenBut.
function deleteHiddenBut_Callback(hObject, eventdata, handles)
vessels = handles.VesselTable.Data(cellfun(@(x) strcmp(x, 'off'), handles.VesselTable.Data(:,2)),1);
prj = getappdata(0, 'project');
if strcmp(questdlg('Do you want to delete the selected vessel(s)?'), 'Yes')
    
    prj.backup_push();  % first make a backup
    if ~isempty(prj.backup)
        set(handles.undoBut, 'Enable', 'on');
    end
    prj.removeBranch(cellfun(@(x) str2double(x(1:find(x == '-')-2)), vessels));

    updatelist(handles);
    magic_tool_update(handles, 'centerline', 0);
    magic_tool_update(handles,'label');
end

% --- Executes on selection change in branchListPlot.
function branchListPlot_Callback(hObject, eventdata, handles)
selectedVesselNumbers = get(handles.branchListPlot, 'Value');

%Get into the project
prj = getappdata(0,'project');
branch = prj.branches;

%Check for values out of range and correct
if any(selectedVesselNumbers < 1)
    set(handles.branchListPlot, 'Value', 1);
elseif any(selectedVesselNumbers > length(branch))
    set(handles.branchListPlot, 'Value', length(branch));
end

%If only one vessel is selected, set up the plane slider for it
if isequal(length(selectedVesselNumbers),1) && strcmp(handles.cutplanePanel.Visible, 'on')
    currentItem = handles.branchListPlot.String{selectedVesselNumbers,:}; %handles.branchListPlot.Value
    b = str2double(currentItem(1:find(currentItem == '-')-2)); %Number
    set(handles.planeSlider, 'Enable', 'on');
    set(handles.DispCutPlot, 'Enable', 'on');
    set(handles.dispCutPlaneBut, 'Enable', 'on');    
    set(handles.planeSlider, 'max', max(2,size(branch{b}.cPoints, 1)));
    set(handles.planeSlider, 'Value', get(handles.planeSlider, 'min'));
    set(handles.planeSlider, 'SliderStep', [1/(get(handles.planeSlider, 'max')-1), ...
        1/(get(handles.planeSlider, 'max')-1) ]);
    set(handles.plotItemMenu, 'Enable', 'on');
    set(handles.medianFilterPlot, 'Enable', 'on');
    set(handles.parPlotBut, 'Enable', 'on');
    set(handles.PDEstimationPanel, 'Visible', 'on');
    
elseif length(get(handles.branchListPlot, 'Value')) >= 1 && strcmp(handles.cutplanePanel.Visible, 'on')
    set(handles.dispCutPlaneBut, 'Enable', 'on');
    set(handles.planeSlider, 'Enable', 'off');
    set(handles.plotItemMenu, 'Enable', 'on');
    set(handles.medianFilterPlot, 'Enable', 'on');
    set(handles.parPlotBut, 'Enable', 'on');
    set(handles.PDEstimationPanel, 'Visible', 'off');
    
else
    set(handles.dispCutPlaneBut, 'Enable', 'off');
    set(handles.planeSlider, 'Enable', 'off');
    set(handles.plotItemMenu, 'Enable', 'off');
    set(handles.medianFilterPlot, 'Enable', 'off');
    set(handles.parPlotBut, 'Enable', 'off');
    set(handles.DispCutPlot, 'Enable', 'off');
    set(handles.PDEstimationPanel, 'Visible', 'off');
end

%Show the correct cutplane
currentItem = handles.branchListPlot.String{get(handles.branchListPlot, 'Value'),:};
b = str2double(currentItem(1:find(currentItem == '-')-2));
set(findobj(handles.axes4.Children, 'Visible', 'on', '-and', 'Type', 'Surface', '-and', ...
        '-regexp','Tag',['b' num2str(b) '_p']), 'Visible', 'off');
    
ind = floor(handles.planeSlider.Value);
h1 = findobj(handles.axes4.Children, 'Type', 'Surface', '-and', 'Tag', sprintf('b%d_p%d', b, ind));
set(h1, 'Visible', 'on');

%Make plots
magic_tool_update(handles, 'parameters', b, ind);
magic_tool_update(handles, '2DPlot', b, ind);
magic_tool_update(handles, '3DPlot', b, ind);

% --- Executes on button press in newMaskBut.
function newMaskBut_Callback(hObject, eventdata, handles)
%keyboard
prj = getappdata(0, 'project');
[baseImage, newMask_name] = newMaskDialog;
if ~isempty(newMask_name) 
    baseImageSeries = prj.find_volume(baseImage, 'Image');
    if isequal(handles.segThreshPanel.Visible, 'on')
        prj.add_mask(baseImageSeries.create_mask(newMask_name, 'Thresholding', handles.thresholdSlider.Value));
    else
        prj.add_mask(baseImageSeries.create_mask(newMask_name, 'None'));
    end
    update_volumeLists(handles, prj);
	handles.seg_Masks.Value = find(cellfun(@(x) isequal(x,newMask_name), handles.seg_Masks.String));
    set(handles.seg_ImageSeries, 'String', prj.masks{handles.seg_Masks.Value - 1}.parentName);
end

% --- Executes on selection change in seg_Masks.
function seg_Masks_Callback(hObject, eventdata, handles)
prj = getappdata(0, 'project');
if handles.seg_Masks.Value ~= 1
    set(handles.seg_ImageSeries, 'String', prj.masks{handles.seg_Masks.Value-1}.parentName);
else
    set(handles.seg_ImageSeries, 'String', []);
end

% --- Executes on selection change in BaseVolumeMenu.
function BaseVolumeMenu_Callback(hObject, eventdata, handles)
if ~isequal(handles.BaseVolumeMenu.Value, 1)
    set(handles.ResultVolumeTxt, 'String', ...
        handles.BaseVolumeMenu.String{handles.BaseVolumeMenu.Value});
end

% --------------------------------------------------------------------
function registerAction_Callback(hObject, eventdata, handles)
prj = getappdata(0, 'project');
set(handles.segThreshPanel, 'Visible', 'off');
set(handles.segROIPanel, 'Visible', 'off');
set(handles.segRGPanel, 'Visible', 'off');
set(handles.cropPanel, 'Visible', 'off');
set(handles.seg_Selection, 'Visible', 'off');
set(handles.registerPanel, 'Visible', 'on');
set(handles.refMaskMenu, 'String', [{''}, prj.maskList()]);
set(handles.movingMaskMenu, 'String', [{''}, prj.maskList()]);
set(handles.refMaskMenu, 'Value', 1);
set(handles.movingMaskMenu, 'Value', 1);

% --- Executes on button press in applyRegisterationBut.
function applyRegisterationBut_Callback(hObject, eventdata, handles)
%keyboard
prj = getappdata(0, 'project');
refMask = prj.find_volume(handles.refMaskMenu.String{handles.refMaskMenu.Value}, 'Mask');
movingMask = prj.find_volume(handles.movingMaskMenu.String{handles.movingMaskMenu.Value}, 'Mask');





indMovingMask = find(cellfun(@(x) isequal(x, movingMask.name), prj.maskList()));
if ~isempty(refMask) && ~isempty(movingMask)
    if ~isequal(refMask, movingMask)
        try
            if registration(movingMask, refMask) %status = 1 if registration runs to end
                %Re-find pointer
                movingMask = prj.find_volume(handles.movingMaskMenu.String{handles.movingMaskMenu.Value}, 'Mask');
                %Display correct items
                if handles.Disp3D.Value && (isequal(movingMask.name, handles.isoSurfaceMenu.String) ...
                        || ismember(movingMask.name, handles.isoSurfaceMenu.String))                
                    magic_tool_update(handles, 'isosurface');
                end
                if isequal(handles.DispItem.String{handles.DispItem.Value}, movingMask.parent.name)
                    adjustSliders(handles, size(movingMask.parent.data));
                    magic_tool_update(handles, 'slice', movingMask.parent);
                    magic_tool_update(handles, 'box', movingMask.parent);
                elseif isequal(handles.DispItem.String{handles.DispItem.Value}, movingMask.name)
                    adjustSliders(handles, size(movingMask.data));
                    magic_tool_update(handles, 'slice', movingMask);
                    magic_tool_update(handles, 'box', movingMask);
                end
            end
        catch ME
            keyboard
            errordlg({'Registration failed!', ME.message});
        end        
    else
        msgbox('The reference mask and moving mask are the same but they should be different');
    end
else
    msgbox('Please select reference and moving mask from the menus');
end    


function copyVolumeBut_Callback(hObject, eventdata, handles)
prj = getappdata(0, 'project');
selectedVolume = prj.find_volume(handles.DispItem.String{handles.DispItem.Value});
if isequal(questdlg(sprintf('Do you wish to make a copy of %s ?', selectedVolume.name)), 'Yes')
    name = inputdlg('Please enter a name for new volume');
    if ~isempty(name)
        if ismember(name{1}, handles.DispItem.String)
            msgbox('There is already a volume with the same name please enter another name');
        else
            if isa(selectedVolume, 'ImageSeries')
                prj.imageSeries{end+1} = selectedVolume.copy();
                prj.imageSeries{end}.name = name{1};
            elseif isa(selectedVolume, 'Mask')
                prj.masks{end+1} = selectedVolume.copy();
                prj.masks{end}.name = name{1};
            end
        end            
    end
end
update_volumeLists(handles, prj);


function deleteVolumeBut_Callback(hObject, eventdata, handles)
prj = getappdata(0, 'project');
selectedVolume = prj.find_volume(handles.DispItem.String{handles.DispItem.Value});
if isequal(selectedVolume.name, 'Magnitude')
    msgbox('The Magnitude image cannot be deleted!');
elseif isequal(questdlg(sprintf('Do you wish to delete %s ?', selectedVolume.name)), 'Yes')    
    if handles.DispItem.Value ~= 1
        handles.DispItem.Value = handles.DispItem.Value - 1;
    end
    if isa(selectedVolume, 'ImageSeries')
        indx = find(cellfun(@(x) isequal(x.name, selectedVolume.name), prj.imageSeries));
        prj.imageSeries{indx}.remove();
        prj.imageSeries(indx) = [];
    elseif isa(selectedVolume, 'Mask')
        indx = find(cellfun(@(x) isequal(x.name, selectedVolume.name), prj.masks));
        prj.masks{indx}.remove();
        prj.masks(indx) = [];
    end
    
    before = handles.isoSurfaceMenu.String(handles.isoSurfaceMenu.Value);
    set(handles.isoSurfaceMenu, 'Value', []);
    update_volumeLists(handles, prj);
    set(handles.isoSurfaceMenu, 'Value', find(ismember(handles.isoSurfaceMenu.String, before)));
    selectedVolume = prj.find_volume(handles.DispItem.String{handles.DispItem.Value});
    adjustSliders(handles, size(selectedVolume.data));
    magic_tool_update(handles, 'isosurface');
    magic_tool_update(handles, 'slice', selectedVolume);
    magic_tool_update(handles, 'box', selectedVolume);
end

% --- Executes when selected object is changed in roiDetectionSelect.
%This just controls what is visible in the dropdown
function roiDetectionSelect_SelectionChangedFcn(hObject, eventdata, handles)
prj = getappdata(0, 'project');
if isequal(handles.roiDetectionSelect.SelectedObject.Tag, handles.maskDetection.Tag)
    set(handles.maskROIMenu, 'Visible', 'on');
    set(handles.maskROIMenu, 'Value', 1);
    set(handles.maskROIMenu, 'String', [{''}, prj.maskList()]);
    
elseif isequal(handles.roiDetectionSelect.SelectedObject.Tag, handles.segmentDetection.Tag)
    set(handles.maskROIMenu, 'Visible', 'on');
    set(handles.maskROIMenu, 'Value', 1);
    set(handles.maskROIMenu, 'String', [{''}, prj.imageList()]);
    
else
    set(handles.maskROIMenu, 'Visible', 'off');    
end

% --- Executes on selection change in maskROIMenu.
function maskROIMenu_Callback(hObject, eventdata, handles)
% hObject    handle to maskROIMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns maskROIMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from maskROIMenu

% --- Executes on button press in captureImageBut.
function captureImageBut_Callback(hObject, eventdata, handles)
image = findobj(handles.axes2D.Children, 'Type', 'Image');
data = image.CData;
if isa(data, 'double')
    data = uint8(255 * mat2gray(data));
end
figure(), imagesc(data);
imwrite(data, 'image.png');

%Modifies tag to save data from this plane in result menu
function savePlaneDataBut_Callback(hObject, eventdata, handles)
if ~isempty(get(handles.branchListPlot, 'Value')) %Only do this stuff if a vessel is selected. Default plane is 1
    %Get info from project
    cProject = getappdata(0, 'project');
    branchStruct = cProject.branches;
    %Get info from GUI
    currentItem = handles.branchListPlot.String{get(handles.branchListPlot, 'Value'),:};
    b = str2double(currentItem(1:find(currentItem == '-')-2)); %Branch index
    ind = floor(handles.planeSlider.Value); %Plane index
    if handles.SavePlaneDataBut.Value
        %Set save tag to 1 (default is 0)
        branchStruct{b}.cPlaneTags(ind,2) = 1;
    else
        %Reset save tag to 0 
        branchStruct{b}.cPlaneTags(ind,2) = 0;
    end
end


%Modifies tag to exclude this plane from saved calculations
function excludePlaneDataBut_Callback(hObject, eventdata, handles)
if ~isempty(get(handles.branchListPlot, 'Value')) %Only do this stuff if a vessel is selected. Default plane is 1
    %Get info from project
    cProject = getappdata(0, 'project');
    branchStruct = cProject.branches;
    %Get info from GUI
    currentItem = handles.branchListPlot.String{get(handles.branchListPlot, 'Value'),:};
    b = str2double(currentItem(1:find(currentItem == '-')-2)); %Branch index
    ind = floor(handles.planeSlider.Value); %Plane index
    if handles.excludePlaneDataBut.Value
        %Set include tag to 0 (default is 1)
        branchStruct{b}.cPlaneTags(ind,1) = 0;
    else
        %Reset include tag to 1 
        branchStruct{b}.cPlaneTags(ind,1) = 1;
    end
end

% --------------------------------------------------------------------
function resultMenu_Callback(hObject, eventdata, handles)
% hObject    handle to resultMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function editLumenROIBut_Callback(hObject, eventdata, handles)
%Get info from project
cProject = getappdata(0, 'project');
branchStruct = cProject.branches;
currentItem = handles.branchListPlot.String{get(handles.branchListPlot, 'Value'),:};
b = str2double(currentItem(1:find(currentItem == '-')-2));
planeIdx = floor(handles.planeSlider.Value);
if ~isempty(branchStruct{b}.cPlane{planeIdx,2}) && ~isempty(branchStruct{b}.cPlane{planeIdx,5})
    img = findobj(handles.axes2D.Children, 'Type', 'Image');
    initalPoints = findobj(handles.axes2D.Children, 'Type', 'Scatter', '-and', '-regexp', 'Tag', '_');
    indx = cellfun(@str2double, strsplit(initalPoints.Tag, '_'));
    [polyPoints, breakPoints] = editLumenROIDialog(img, unique([initalPoints.XData; initalPoints.YData]', 'stable', 'row'));
    if ~isempty(polyPoints) && ~isempty(breakPoints)   
        magic_tool_update(handles, 'LumenROI', indx(1), indx(2), polyPoints, breakPoints);
        magic_tool_update(handles, '2DPlot', indx(1), indx(2));
        magic_tool_update(handles, '3DPlot', indx(1), indx(2));
        magic_tool_update(handles, 'parameters', indx(1), indx(2));
    end
else
    msgbox('Editing ROI is not compatible with the exact mask');
end


% --------------------------------------------------------------------
function visualizationAction_Callback(hObject, eventdata, handles)
% hObject    handle to visualizationAction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function streamlineAction_Callback(hObject, eventdata, handles)
prj = getappdata(0, 'project');
answer = inputdlg({'Mask name:', 'Number of stream lines:'});
if ~isempty(answer) && ~isempty(prj.find_volume(answer{1}, 'Mask')) && ~isnan(str2double(answer{2}))
    magic_tool_update(handles, 'streamLine', answer{1}, str2double(answer{2}));
else
    msgbox('Invalid inputs for stream line calculation');
end

% --------------------------------------------------------------------
function flowDirectionAction_Callback(hObject, eventdata, handles)
p = getappdata(0, 'project');
arrowDir = zeros(length(p.branches), 3);
figure();
hold on;
for i= 1:length(p.branches)
    mid = floor(size(p.branches{i}.pList, 1)/2);
    
    arrowDir(i,:) = sum(normrTwin([ (ppval(fnder(p.branches{i}.fitLine(1)), p.branches{i}.pList(mid-1:mid+1, 4))), ...
                    (ppval(fnder(p.branches{i}.fitLine(2)),p.branches{i}.pList(mid-1:mid+1, 4))), ...
                    (ppval(fnder(p.branches{i}.fitLine(3)),p.branches{i}.pList(mid-1:mid+1, 4)))]));
    arrowDir(i,:) = arrowDir(i,:)/norm(arrowDir(i,:));
    
    h = plot3(  p.branches{i}.lineHandle.XData, p.branches{i}.lineHandle.YData, ...
                p.branches{i}.lineHandle.ZData, 'LineWidth',2);
    set(h,'Color',get(p.branches{i}.lineHandle, 'Color'));
    quiver3(p.branches{i}.pList(mid, 2)-0.5, p.branches{i}.pList(mid, 1)-0.5, ...
        p.branches{i}.pList(mid, 3)-0.5, arrowDir(i,2), arrowDir(i,1), arrowDir(i,3), 12, ...
        'LineWidth', 2, 'MaxHeadSize', 5, 'Color','k');
    text(p.branches{i}.pList(mid,2)+1, p.branches{i}.pList(mid,1)+1, ...
        p.branches{i}.pList(mid,3)+1, num2str(p.branches{i}.id));
end
view(3);
rotate3d on;
axis equal;
axis off;


% --- Executes on selection change in normalVesselMenu.
function normalVesselMenu_Callback(hObject, eventdata, handles)
set(handles.NormalPlaneTxt, 'String', []);
if handles.normalVesselMenu.Value == 1
    set(handles.SelectToBut, 'String', 'Select');
    set(handles.FromBut, 'Visible', 'off');
elseif handles.normalVesselMenu.Value == 2
    set(handles.SelectToBut, 'String', 'To');
    set(handles.FromBut, 'Visible', 'on');
end

% --- Executes on button press in SelectToBut.
function SelectToBut_Callback(hObject, eventdata, handles)
if strcmp(handles.SelectToBut.String, 'Select')
    set(handles.NormalPlaneTxt, 'String', [handles.branchListPlot.String{handles.branchListPlot.Value} ...
        ' - Plane ' num2str(floor(handles.planeSlider.Value))]);
else
    if isempty(handles.NormalPlaneTxt.String)
        errordlg('Please select the start plane first');
    else
        if contains(handles.NormalPlaneTxt.String, ' to ')
            words = strsplit(handles.NormalPlaneTxt.String);
            newText = strjoin(words(1:find(cellfun(@(x) isequal(x, 'to'),words))-1));
            set(handles.NormalPlaneTxt, 'String', [newText ...
                ' to ' num2str(floor(handles.planeSlider.Value))]);
        else
            set(handles.NormalPlaneTxt, 'String', [handles.NormalPlaneTxt.String ...
                ' to ' num2str(floor(handles.planeSlider.Value))]);
        end
    end
end

% --- Executes on button press in FromBut.
function FromBut_Callback(hObject, eventdata, handles)
    set(handles.NormalPlaneTxt, 'String', [handles.branchListPlot.String{handles.branchListPlot.Value} ...
        ' - Plane ' num2str(floor(handles.planeSlider.Value))]);


% --- Executes on button press in selectStenosisBut.
function selectStenosisBut_Callback(hObject, eventdata, handles)
set(handles.StenoticPlaneTxt, 'String', [handles.branchListPlot.String{handles.branchListPlot.Value} ...
        ' - Plane ' num2str(floor(handles.planeSlider.Value))]);


% --- Executes on button press in estimateBut.
function estimateBut_Callback(hObject, eventdata, handles)
try
    % parse text for proximal plane
    parts = cellfun(@str2double, strsplit(handles.NormalPlaneTxt.String));
    parts = parts(~isnan(parts));
    vesselIndn = parts(1);
    planeIndn = parts(2:end);    
    % parse text for stenotic plane
    parts = cellfun(@str2double, strsplit(handles.StenoticPlaneTxt.String));
    parts = parts(~isnan(parts));
    vesselInds = parts(1);
    planeInds = parts(2);
    
    if vesselIndn ~= vesselInds
        throw([]);
    end
    
    p = getappdata(0, 'project');
    if length(planeIndn)==1
        A_n = p.branches{vesselIndn}.cPlane{planeIndn,4}(1);
    elseif length(planeIndn)==2
        if planeIndn(1) > planeIndn(2)
            throw([]);
        end
        A_n = mean(cellfun(@(x) x(1), p.branches{vesselIndn}.cPlane(planeIndn(1):planeIndn(2),4)));
    else
        throw([]);
    end
    
    A_s = p.branches{vesselInds}.cPlane{planeInds,4}(1);
    V_s = p.branches{vesselInds}.cPlane{planeInds,4}(4);
    PD = 4*V_s^2*(1-(A_s/A_n)^2);
    set(handles.PDValueTxt, 'String', num2str(round(PD,2)));
    
catch
    errordlg(['Please make sure at least one plane for normal and one plane' ... 
        ' for stenosis are selected on the same branch']);
end


% --------------------------------------------------------------------
function ClearPlaneTags_Callback(hObject, eventdata, handles)
% hObject    handle to ClearPlaneTags (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Untitled_3_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function transformAction_Callback(hObject, eventdata, handles)
% hObject    handle to transformAction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on key press with focus on planeSlider and none of its controls.
function planeSlider_KeyPressFcn(hObject, eventdata, handles)
% Enable changing the tags with hotkeys
key = eventdata.Key;
switch key
    case 'e' %Exclude button
        %If cutplane box is visible
        if strcmp(get(handles.cutPlanePanel,'visible'),'on')
            %First change the value of the box as clicking on it would
            if handles.excludePlaneDataBut.Value
                set(handles.excludePlaneDataBut,'Value',0);
            else
                set(handles.excludePlaneDataBut,'Value',1);
            end
            %Then run the callback of the checkbox
            excludePlaneDataBut_Callback(hObject, eventdata, handles)
        end
        
    case 's' %Save button
        %If cutplane box is visible
        if strcmp(get(handles.cutPlanePanel,'visible'),'on')
            %First change the value of the box as clicking on it would
            if handles.SavePlaneDataBut.Value
                set(handles.SavePlaneDataBut,'Value',0);
            else
                set(handles.SavePlaneDataBut,'Value',1);
            end
            %Then run the callback of the checkbox
            savePlaneDataBut_Callback(hObject, eventdata, handles)
        end
        
    case 'n' %Scroll to the next vessel
        %Get into the project
        prj = getappdata(0,'project');
        branch = prj.branches;
        %Get current value and compare to max
        currentValue = get(handles.branchListPlot, 'Value');
        if (currentValue < length(branch))
            %Augment value
            set(handles.branchListPlot, 'Value', currentValue+1);
            %Do the rest of the process
            branchListPlot_Callback(hObject, eventdata, handles);
        end

    case 'b' %Scroll to the next vessel
        %Get current value and compare to 1
        currentValue = get(handles.branchListPlot, 'Value');
        if (currentValue > 1)
            %Decrease value
            set(handles.branchListPlot, 'Value', currentValue-1);
            %Do the rest of the process
            branchListPlot_Callback(hObject, eventdata, handles);
        end
end

% --------------------------------------------------------------------
function exportPlaneInfoAction_Callback(hObject, eventdata, handles)
% hObject    handle to exportPlaneInfoAction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
prj = getappdata(0, 'project');
    [planefile, path] = uiputfile([prj.workingDirectory 'planeInfo.mat'], 'Save planeInfo as');
        
    %%%%% Master Struct
    zipPI = reshape([{'mrParams', 'BranchData'}; cell(1,2)],1,[]);
    planeInfo = struct(zipPI{:});
    
    %%%%% Struct to hold acquisition parameters
    paramList = {'TimePoints','TR','TE','LowVenc','HighVenc','VoxelSize','HeartRate','Edges','Mask'};
    zipMP =  reshape([paramList; cell(size(paramList))],1,[]);
    mrParams = struct(zipMP{:});
    % record time information
    timePoints =  prj.mag.user.timePoints';
    mrParams.TimePoints = timePoints;% 4D Flow time points
    mrParams.TR = prj.mag.tr;
    mrParams.TE = prj.mag.te;
    
    %TODO: MAKE ROBUST TO SINGLE VENC ACQUISITIONS %%%%%%%%%%%%%%%%%
    mrParams.LowVenc = prj.mag.user.venc_in_plane;
    mrParams.HighVenc = prj.mag.user.high_venc3D;
    %voxel size
    if prj.imageSeries{1,1}.interpFactor ~= 1 %something w/in the MT can interpolate the data. This throws off the vox size.
        mrParams.VoxelSize = prj.imageSeries{1,1}.vox * prj.imageSeries{1,1}.interpFactor;
    else
        mrParams.VoxelSize = prj.imageSeries{1,1}.vox;
    end
    % heart rate
    HR_ms = prj.mag.user.nominal_interval;
    mrParams.HeartRate = [HR_ms, 60000 / HR_ms];   
    mrParams.Edges = prj.mag.edges; % scanner info / rotation matrix to line up acquisitions. NOT Maria's edges.
    
    %for the type of segmentation. This saves whatever mask has been most
    %recently "Updated". Making the assumption that user is on same
    %isosurface as outputs
    mrParams.Mask = prj.cMask.parentName;
    
    %%%%% Vessel information
    fieldList = {'id', 'name', 'cPlaneTags', 'PlaneData'};
    zipVI = reshape([fieldList; cell(size(fieldList))], 1, []);
    vesselInfo = struct(zipVI{:});
    
    if ~isequal(planefile,0) && ~isequal(path,0)
        for i=1:length(prj.branches)
            vesselInfo(i).id = prj.branches{i}.id;
            vesselInfo(i).name = prj.branches{i}.name;
            vesselInfo(i).cPlaneTags = prj.branches{i}.cPlaneTags; % record of excluded planes
            
                %%%%% Plane-specific Data
                % Create new struct for parameters of interest 
                branchList = {'Length','Area','Flowrate','MeanVel','StdVel','MedVel','PeakVel','Vel95percent'};
                zipBI = reshape([branchList; cell(size(branchList))],1, []); % BI = branch info
                branchInfo = struct(zipBI{:});              
                
                %save calculated data
                planesToSave = (prj.branches{i}.cPlaneTags(:,1)==1); % omit tagged planes
                length_mm = prj.branches{i}.cPoints(planesToSave,4); % vessel length
                area_mm = cellfun(@(x) x(1),prj.branches{i}.cPlane(planesToSave,4),'UniformOutput', false);
                
                % extract cell data for every time point
                branchData = cellfun(@num2cell, cellfun(@(x) x{4}(:), prj.branches{i}.cPlane(planesToSave,3), 'UniformOutput', false),'UniformOutput', false);
                branchDataArray = cell2mat([branchData{:}]');

                % record branch information and temporal data
                branchInfo.Length = length_mm;
                branchInfo.Area = area_mm; % area does not change per time point for flow calcs b/c only one segmentation / plane
                
                % Slice Data to fit fields. This should always the be same
                % factors * time points
                branchInfo.Flowrate = branchDataArray(:,1:length(timePoints));
                branchInfo.MeanVel = branchDataArray(:,1 + length(timePoints):2*length(timePoints));
                branchInfo.StdVel = branchDataArray(:,1 + 2*length(timePoints):3*length(timePoints));
                branchInfo.MedVel = branchDataArray(:,1 + 3*length(timePoints):4*length(timePoints));
                branchInfo.PeakVel = branchDataArray(:,1 + 4*length(timePoints):5*length(timePoints));
                branchInfo.Vel95percent = branchDataArray(:,1 + 5*length(timePoints):6*length(timePoints));
            
            %%%%% Recombine into master struct
            vesselInfo(i).PlaneData = branchInfo;

        end
        planeInfo.BranchData = vesselInfo;
        planeInfo.mrParams = mrParams;
        save(fullfile(path,planefile),'planeInfo');
    end

    
    
    %%pwinter, 2022/01/06
    function smp12Menu_Callback(hObject, eventdata, handles)
    prj = getappdata(0, 'project');
    
    %Import Dicom files of TOF Dataset
    msg1=msgbox('Import Dicom files of TOF dataset!');
    [imgStruct_tof, DICOMFile_tof, dataName_tof] = importImageDialog();
    close(msg1);
    
    msg2=msgbox('Import Dicom files of 4D flow magnitude images!');
    [imgStruct_mag, DICOMFile_mag, dataName_mag] = importImageDialog();
    close(msg2); 
   
    
    path_tof_dcm=DICOMFile_tof(1:end-10); %Path where tof dicoms are located
    path_pcmri_dcm=DICOMFile_mag(1:end-10); %Path where dicoms of 4d flow magnitude images are located
    
    path_coregis=fullfile('D:\temp\', 'coregis'); %Path where coregistration results are saved (hardcoded for now)

     
    %===Create coregis results path, if it does not exist===%
    if(~exist(path_coregis, 'dir'))
    mkdir(path_coregis);
    end
    %===End of this section===%

    %Conversion to NIfTI files. The results are saved in coregis\NIfTI
    h=waitbar(0.5, 'Converting dicom files to NIfTI files...');
    pw_convert_to_NIfTI(path_coregis, path_pcmri_dcm, path_tof_dcm)
    waitbar(1, h,  'Converting dicom files to NIfTI files...');
    close(h);
    
    %Temporal average
    %We can take the temporal average of the PCMRI dataset
    h=waitbar(0.5, 'Temporally averaging the PCMRI images...');
    pw_averagenifti(fullfile(path_coregis,'NIfTI', 'PCMRI'));
    waitbar(1, h,  'Temporally averaging the PCMRI images...');
    close(h);
    
    %Interpolation
    h=waitbar(0.5, 'Interpolation of PCMRI images. This can take a while. Please be patient');
    res_tof=pw_interpolate_pcmri(fullfile(path_coregis, 'NIfTI'), path_pcmri_dcm, path_tof_dcm, 1);
    waitbar(1, h,  'Interpolation of PCMRI images. This can take a while. Please be patient');
    close(h)
    
    %Set path where the NIfTI files of the reference PCMRI magnitude images are
    %saved
    path_ref=fullfile(path_coregis, 'NIfTI', 'Interpol', 'ipcmri.nii');
    
    
    %The next step is a bit complicated and may be replacd soon by something more logical. The problem at the moment is the following: The script pw_convert_to_nifti
    %converts the TOF dicoms to NIfTI. The script pw_interpolated_pcmri converts the
    %interpolated PCMRI images (a MATLAB struct) to NIfTI. Both NIfTI files are not
    %compatible since two different scripts are used to export the NIfTI files (I think the geomtric informations in the headers are not compatible). 
    %For that reason, SPM12 co-registration alwasy fails if these to NIfTI files are
    %compared. To circumvent these problems, I import the NIfTI file of the TOF
    %dataset back to MATLAB
    %and save the MATLAB struct again to NIfTI using the same routine as the pw_interpolate_pcmri script. 

    %Import of TOF dataset
    path_source=fullfile(path_coregis, 'NIfTI', 'TOF', 'tof.nii');
    tofdata=readnii(path_source); %Import NIfTI file back to MATLAB

    % %Write  to nii
    path_source=fullfile(path_coregis, 'NIfTI', 'TOF', 'tof2.nii');
    niftiwrite(tofdata, path_source); %Save the MATLAB struct again as NIfTI
    
    
    
    %########################################################################################################################################################################%
%Now everything is set to finally start the co-registration
%Create results folder for results
path_res=fullfile(path_coregis, 'results');

if(~exist(path_res, 'dir'))
    mkdir(path_res);
end

%Coregistration using SPM12. I used a script of the vascular_territory_tool for
%convenience
h=waitbar(0.5, 'Now the SPM12 stuff happens.');

register_nc(path_ref,path_source);
waitbar(1, h, 'Now the SPM12 stuff happens.');
close(h)

%Copy to results folder
copyfile(fullfile(path_coregis, 'NIfTI', 'TOF', 'rtof2.nii'), path_res);
%===End of coregistration step===%

%########################################################################################################################################################################%
%Now we save the coregistered image as MATLAB struct. Since SPM12 saves the
%co-registration as NIfTI file, we need to import the file back to MATLAB.
%Perhaps in future release I will implement something more intelligent.
%===Conversion back to matlab file===%
d_coregis=readnii(fullfile(path_res, 'rtof2.nii')); %We again use a script of the vascular_territory_tool for convenience
d_coregis(isnan(d_coregis))=0; %Remove NaNs

    %Optional image display of results
    im1=readnii(path_ref); im1=im1/max(im1(:)); %Reference PCMRI image
    im2=d_coregis/max(d_coregis(:)); %Coregistered TOF image
    
    [size_x,size_y,size_z]=size(im1);
    
    
    figure(100)
    subplot(3,2,1); imagesc(im1(:,:,round(size_z/2))), axis image, colormap('gray'), caxis([0 0.3]), title('PCMRI');
    subplot(3,2,2); imagesc(im2(:,:,round(size_z/2))), axis image, colormap('gray'), caxis([0 0.3]), title('Registered TOF');
    subplot(3,2,3); imagesc(rot90(squeeze(im1(round(size_x/2),:,:)))), axis image, colormap('gray'), caxis([0 0.3]), title('PCMRI');
    subplot(3,2,4); imagesc(rot90(squeeze(im2(round(size_x/2),:,:)))), axis image, colormap('gray'), caxis([0 0.3]), title('Registered TOF');
    subplot(3,2,5); imagesc(rot90(squeeze(im1(:,round(size_y/2),:)))), axis image, colormap('gray'), caxis([0 0.3]), title('PCMRI');
    subplot(3,2,6); imagesc(rot90(squeeze(im2(:,round(size_y/2),:)))), axis image, colormap('gray'), caxis([0 0.3]), title('Registered TOF');
  
   d_coregis=flip(d_coregis,3);
    
    %Create the MATLAB struct.
    mrStruct.dataAy=single(flip(permute(d_coregis, [2 1 3]),1)); %Co-registered TOF images
    mrStruct.vox=res_tof; %Spatial resolution
    mrStruct.dim10='unused'; %The 'unused' mode can be interpreted by the magic tool
   mrStruct.dim11='unused'; %The 'unused' mode can be interpreted by the magic tool

    %Save results to coregis\results. This is the file which can be imported to
    %the magic tool using the "import image" option.
    
    
    
    msg3=msgbox(['The MATLAB struct of the co-registered TOF images is saved to ' num2str(fullfile(path_coregis, 'results', 'tof_coregistered_MRStruct.mat'), 'mrStruct')]);
    save(fullfile(path_coregis, 'results', 'tof_coregistered_MRStruct.mat'), 'mrStruct');

%Import coregistered images to magic_tool GUI
imgStruct=fullfile(path_coregis, 'results', 'tof_coregistered_MRStruct.mat');
importedData = matfile(imgStruct);
importedData = importedData.mrStruct;

FOV = [zeros(3,1), (importedData.vox(1:3).*size(importedData.dataAy))'];
importedData.interpFactor=1;

dataName='tof_cores';

prj.add_imageSeries (dataName, importedData.dataAy, FOV, importedData.vox(1:3), ...
        importedData.interpFactor, 'mrStruct');
    update_volumeLists(handles, prj);
    
 msg4=msgbox('Data Imported as tof_cores into GUI workspace!');
    
%%end of pwinter, 2022/01/06

%%pwinter, 2022/01/13
function fliptofMenu_Callback(hObject, eventdata, handles)
    %keyboard
   prj = getappdata(0, 'project');
    
   path_coregis=fullfile('D:\temp\', 'coregis'); %Path where coregistration results are saved (hardcoded for now)
   
   %Path where mat file is saved
   path_matfile=fullfile(path_coregis, 'results', 'tof_coregistered_MRStruct.mat');
   
   answer = questdlg('Do you want to flip the FOV of the TOF measurement in z direction?', '', 'Yes', 'No', 'Cancel', 'Yes');
   
    switch answer
        case 'Yes'
            try
               
                resdata=importdata(path_matfile);
                
                %Flip data Array
                resdata.dataAy=flip(resdata.dataAy,3);
                
                msg1=msgbox(['The MATLAB struct of the flipped TOF images is saved to ' num2str(fullfile(path_coregis, 'results', 'tof_coregistered_MRStruct_flipped.mat'), 'mrStruct')]);
                save(fullfile(path_coregis, 'results', 'tof_coregistered_MRStruct_flipped.mat'), 'resdata');
               
                
                dataName='tof_cores_flipped';
                
                FOV = [zeros(3,1), (resdata.vox(1:3).*size(resdata.dataAy))'];
                resdata.interpFactor=1;


                prj.add_imageSeries (dataName, resdata.dataAy, FOV, resdata.vox(1:3), ...
                resdata.interpFactor, 'mrStruct');
                update_volumeLists(handles, prj);
                
                msg2=msgbox('Flipped data Imported as tof_cores_flipped into GUI workspace!');
            catch 
                msg3=msgbox('No co-registered TOF data found');
            end
            
        case 'No'
            %do nothing
            
        case 'Cancel'
            %do nothing
    end
            
   
   
   