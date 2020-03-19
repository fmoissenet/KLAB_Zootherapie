% Author     :   F. Moissenet
%                Kinesiology Laboratory (K-LAB)
%                University of Geneva
%                https://www.unige.ch/medecine/kinesiology
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License 
%                https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Source code:   https://gitlab.unige.ch/KLab/klab_zootherapie
% Reference  :   Not applicable
% Date       :   December 2019
% -------------------------------------------------------------------------
% Description:   This toolbox loads CSV files exported from Physilog RTK 
%                (GaitUp, Switzerland) and compute basic accelerometer-
%                based parameters for lower and upper limbs.
% Dependencies : Not applicable
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution - 
% NonCommercial 4.0 International License. To view a copy of this license, 
% visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
% -------------------------------------------------------------------------

clearvars;
close all;
clc;

% -------------------------------------------------------------------------
% TOOLBOX FOLDERS
% -------------------------------------------------------------------------
dependenciesFolder = '/home/chloups/Bureau/GIT/ZOOTHERAPIE/dependencies/Physilog5MatlabToolKit_v1_5_0';
toolboxFolder      = '/home/chloups/Bureau/GIT/ZOOTHERAPIE';
addpath(dependenciesFolder);
addpath(toolboxFolder);
template           = 'ZOOTHERAPIE_modele.xlsx';

% -------------------------------------------------------------------------
% EXTRACT SUBJECT DATA
% -------------------------------------------------------------------------
subjectID          = 'ZOOTHERAPIE_001';
dataFolder         = ['/home/chloups/Bureau/GIT/ZOOTHERAPIE/data/',subjectID];
cd(dataFolder);
files              = dir('*.BIN'); % all bin files must be in the subject folder and renamed with the measurement date and file number (e.g. 19_12_19_001.BIN)

for icondition = 1:size(files,1)
    
    % Clear workspace
    clearvars -except toolboxFolder dataFolder files template subjectID icondition
    cd(dataFolder);
    
    % Read files
    [sensorData, header] = rawP5reader(files(icondition).name,'3Dangle','sync');
    date     = [header.startDate.Year,'-',header.startDate.Month,'-',header.startDate.Day]; % YYYY-MM-DD
    n        = size(sensorData(1).data(:,1),1);
    f        = sensorData(1).Fs;                                                            % Hz
    time     = sensorData(1).timestamps;                                                    % s
    acc(:,1) = sensorData(1).data(:,1)*9.81;                                                % m.s-2
    acc(:,2) = sensorData(1).data(:,2)*9.81;                                                % m.s-2
    acc(:,3) = sensorData(1).data(:,3)*9.81;                                                % m.s-2
    
    % ---------------------------------------------------------------------
    % COMPUTE THE QUANTITY OF ACTIVITY
    % ---------------------------------------------------------------------
    % Compute the quantity of activity (norm of the 3D acceleration)
    quantityAct = sqrt(acc(:,1).^2+acc(:,2).^2+acc(:,3).^2);

    % Compute the mean value of acceleration norm on successive time-windows
    tWindow = 15*f; % 15 s window
    t2      = 1;
    for t = 1:tWindow:size(quantityAct,1)-tWindow
        quantityActAveraged(t2) = mean(quantityAct(t:t+tWindow-1));
        t2                      = t2+1;
    end
    quantityActAveraged(end+1)  = mean(quantityAct(t+tWindow:end));
    quantityActAveragedSum      = sum(quantityActAveraged);
    quantityActAveragedMean     = mean(quantityActAveraged);
    temp                        = sort(quantityActAveraged,'descend');
    quantityActAveragedMax      = mean(temp(1:5));
    quantityActAveragedMin      = min(quantityActAveraged);
    
    % Compute the % of time of activity > a predefined threshold
    timer = 0;
    for t = 1:size(quantityActAveraged,2)
%         if quantityActAveraged(t) >= quantityActAveragedMin + ...
%                                      (quantityActAveragedMax - ...
%                                       quantityActAveragedMin)/2
        if quantityActAveraged(t) >= 10 % arbitrarily defined
            timer = timer+1;
        end
    end
    durationActAveragedMax = timer*100/size(quantityActAveraged,2);

    % ---------------------------------------------------------------------
    % COMPUTE THE DURATION OF SITTING AND STANDING POSTURES
    % ---------------------------------------------------------------------            
    % Compute the mean value of accelerations on successive time-windows
    tWindow = 15*f; % 15 s window
    t2      = 1;
    for t = 1:tWindow:size(acc,1)-tWindow
        accAveraged(t2,1) = mean(acc(t:t+tWindow-1,1));
        accAveraged(t2,2) = mean(acc(t:t+tWindow-1,2));
        accAveraged(t2,3) = mean(acc(t:t+tWindow-1,3));
        t2                = t2+1;
    end
    accAveraged(end+1,1) = mean(acc(t+tWindow:end,1));
    accAveraged(end+1,2) = mean(acc(t+tWindow:end,2));
    accAveraged(end+1,3) = mean(acc(t+tWindow:end,3));

    % Compute the duration of each axis
    % The axis with an acceleration close to 9.81 is stored at each frame
    for t = 1:size(accAveraged,1)
        [value(t),axis(t)] = min(abs(abs(accAveraged(t,:))-9.81));
    end
    axisDuration(1) = length(find(axis==1))*15; % s
    axisDuration(2) = length(find(axis==2))*15; % s
    axisDuration(3) = length(find(axis==3))*15; % s

    % Find which axes characterise sitting and standing postures
    % - Select manually a sitting segment (axisCalib1)
    % - Set the second most used axis as standing (axisCalib2)
    figure(1); 
    subplot(2,1,1); plot(accAveraged); xlim([0 250]); 
    subplot(2,1,2); plot(axis); ylim([0 5]); xlim([0 250]);
    temp = round(ginput(2));
    close all;
    tCalib = temp(:,1);
    if nanmean(axis(tCalib)) == 1
        axisCalib1             = 1;          % axis related to sitting
        temp                   = axis;
        temp(temp==axisCalib1) = NaN;
        axisCalib2             = mode(temp); % axis related to standing
    elseif nanmean(axis(tCalib)) == 2
        axisCalib1             = 2;          % axis related to sitting
        temp                   = axis;
        temp(temp==axisCalib1) = NaN;
        axisCalib2             = mode(temp); % axis related to standing
    elseif nanmean(axis(tCalib)) == 3
        axisCalib1             = 3;          % axis related to sitting
        temp                   = axis;
        temp(temp==axisCalib1) = NaN;
        axisCalib2             = mode(temp); % axis related to standing
    end
    
    % Count the number of sit-to-stand (nSst) and stand-to-sit (nSts)
    % Correspond to the variation from axisCalib1 <-> axisCalib2
    nSst = 0;
    nSts = 0;
    for t = 1:size(axis,2)-1
        if axis(t) == axisCalib1 && axis(t+1) == axisCalib2
            nSst = nSst+1;
        elseif axis(t) == axisCalib2 && axis(t+1) == axisCalib1
            nSts = nSts+1;
        end
    end

%     % ---------------------------------------------------------------------
%     % EXPORT RESULTS
%     % --------------------------------------------------------------------- 
%     cd(toolboxFolder);
%     % Create file
%     if ~isfile([subjectID,'.xlsx'])
%         system(['copy ',template,' ',subjectID,'.xlsx']);
%     else
%         disp('Subject file already exists !')
%     end
% 
%     % Subject and conditions
%     xlswrite([subjectID,'.xlsx'],cellstr(subjectID),'Rapport','B2');
%     if icondition == 1
%         xlswrite([subjectID,'.xlsx'],cellstr(date),'Rapport','B3');
%     elseif icondition == 2
%         xlswrite([subjectID,'.xlsx'],cellstr(date),'Rapport','B4');
%     end
% 
%     % Session duration
%     if icondition == 1
%         xlswrite([subjectID,'.xlsx'],size(acc,1)/f/60,'Rapport','B7');
%     elseif icondition == 2
%         xlswrite([subjectID,'.xlsx'],size(acc,1)/f/60,'Rapport','E7');
%     end
% 
%     % Quantity of activity
%     if icondition == 1
%         xlswrite([subjectID,'.xlsx'],quantityActAveraged,'Donn�es','B2');
%         xlswrite([subjectID,'.xlsx'],quantityActAveragedSum,'Donn�es','B3');
%         xlswrite([subjectID,'.xlsx'],quantityActAveragedMean,'Donn�es','B4');
%         xlswrite([subjectID,'.xlsx'],durationActAveragedMax,'Donn�es','B5');
%     elseif icondition == 2
%         xlswrite([subjectID,'.xlsx'],quantityActAveraged,'Donn�es','B6');
%         xlswrite([subjectID,'.xlsx'],quantityActAveragedSum,'Donn�es','B7');
%         xlswrite([subjectID,'.xlsx'],quantityActAveragedMean,'Donn�es','B8');
%         xlswrite([subjectID,'.xlsx'],durationActAveragedMax,'Donn�es','B9');
%     end
% 
%     % Type of activity
%     if icondition == 1
%         if axisCalib1 == 1
%             xlswrite([subjectID,'.xlsx'],axisDuration(1)/60,'Donn�es','B16');
%         elseif axisCalib1 == 2
%             xlswrite([subjectID,'.xlsx'],axisDuration(2)/60,'Donn�es','B16');
%         elseif axisCalib1 == 3
%             xlswrite([subjectID,'.xlsx'],axisDuration(3)/60,'Donn�es','B16');
%         end
%         if axisCalib2 == 1
%             xlswrite([subjectID,'.xlsx'],axisDuration(1)/60,'Donn�es','B15');
%         elseif axisCalib2 == 2
%             xlswrite([subjectID,'.xlsx'],axisDuration(2)/60,'Donn�es','B15');
%         elseif axisCalib2 == 3
%             xlswrite([subjectID,'.xlsx'],axisDuration(3)/60,'Donn�es','B15');
%         end
%         temp                   = axis;
%         temp(temp~=axisCalib1) = NaN;
%         temp(temp==axisCalib1) = 1;
%         xlswrite([subjectID,'.xlsx'],temp,'Donn�es','B14');
%         temp                   = axis;
%         temp(temp~=axisCalib2) = NaN;
%         temp(temp==axisCalib2) = 1;
%         xlswrite([subjectID,'.xlsx'],temp,'Donn�es','B13');
%         xlswrite([subjectID,'.xlsx'],nSst,'Donn�es','B18');
%         xlswrite([subjectID,'.xlsx'],nSts,'Donn�es','B19');
%     elseif icondition == 2
%         if axisCalib1 == 1
%             xlswrite([subjectID,'.xlsx'],axisDuration(1)/60,'Donn�es','B23');
%         elseif axisCalib1 == 2
%             xlswrite([subjectID,'.xlsx'],axisDuration(2)/60,'Donn�es','B23');
%         elseif axisCalib1 == 3
%             xlswrite([subjectID,'.xlsx'],axisDuration(3)/60,'Donn�es','B23');
%         end
%         if axisCalib2 == 1
%             xlswrite([subjectID,'.xlsx'],axisDuration(1)/60,'Donn�es','B22');
%         elseif axisCalib2 == 2
%             xlswrite([subjectID,'.xlsx'],axisDuration(2)/60,'Donn�es','B22');
%         elseif axisCalib2 == 3
%             xlswrite([subjectID,'.xlsx'],axisDuration(3)/60,'Donn�es','B22');
%         end
%         temp                   = axis;
%         temp(temp~=axisCalib1) = NaN;
%         temp(temp==axisCalib1) = 1;
%         xlswrite([subjectID,'.xlsx'],temp,'Donn�es','B21');
%         temp                   = axis;
%         temp(temp~=axisCalib2) = NaN;
%         temp(temp==axisCalib2) = 1;
%         xlswrite([subjectID,'.xlsx'],temp,'Donn�es','B20');
%         xlswrite([subjectID,'.xlsx'],nSst,'Donn�es','B25');
%         xlswrite([subjectID,'.xlsx'],nSts,'Donn�es','B26');
%     end
    
end