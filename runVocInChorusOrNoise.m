function runVocInChorusOrNoise(btag)

% This function parses the serial port input 'btag' and controls TDT
% stimulus generation. The function has two sections
% Init: setup TDT parameters and task type.
% Run:  Based on task identity (TDT.TT) turn on/off stim in the correct
%       order. The current step (TDT.CS), tracks which step we are on and
%       turns on/off TDT triggers appropriately

% Note: if writing another runXYZ(bTag) script, change the init section to
% setup each trial correctly and change the run section so that the steps for
% each ;task type match the task structure
% USES TNT.RCX

%% setup
global TDT;
C_L = 65; % intensity of Chorus
% ModSc = 0.0041; % scaling for 60dB
% uModSc = 0.003; % scaling for 60dB
% wavfs = 48828;
vocLen = numel(TDT.Voc);

%% INIT - start of the trial to setup parameters
% btag = 'SPKHTI4&80&1END';

if numel(btag)>1 % then setup the trial
    % Figure out TT (Trial Type) first
    TDT.TT = btag(4);
    % get and set Chorus voltage
    aInd = strfind(btag,'&');
    CHN = str2double(btag(aInd(1)-1));
    TDT.getTDT_cV(C_L,CHN);
    TDT.setTDT_PT('ChorusSc',TDT.V);
    % get Voc voltage
    V_L = str2double(btag(aInd(1)+1:aInd(1)+2));
    TDT.getTDT_cV(V_L);
    TDT.setTDT_PT('VocSc',TDT.V);
    % Write chorus, voc and voltages & update # of trials
    TDT.NT = TDT.NT+1;
    TDT.writeTDT_buffer('Chorus',TDT.Choruses{CHN});
    TDT.writeTDT_buffer('Voc',TDT.Voc);
    % get preStim voltage
    TDT.vocOrNoise = btag(aInd(1)+4);
    if TDT.vocOrNoise == '0'
        TDT.setTDT_PT('NoiseSc',.007);  % default = 0.007
        display('Background will be a noise.')
    elseif TDT.vocOrNoise == '1'
        display('Background will be a chorus.')
    else
        display('Error: Wrong Pavlov parameter!')
    end
    % reset state-list
    TDT = TDT.updateCS(0);
    % RUN - turn on/off stimuli
else
    % Based on btag, do different things
    switch btag
        case '5'
             switch TDT.CS
                case 1 % turn on chorus
                    % on some Hit trials, don't turn on the chorus
                    if TDT.TT=='H' && rand<=0
                        disp('No Chorus')
                        TDT = TDT.updateCS(1);
                    % Play chorus background
                    elseif TDT.vocOrNoise == '1'
                        display('Playing chorus background ...')
                        TDT.triggerTDT(3);
                        TDT = TDT.updateCS(1);
                    % Play noise background
                    elseif TDT.vocOrNoise == '0'
                        display('Playing noise background ...')
                        TDT.triggerTDT(5);
                        TDT = TDT.updateCS(1);
                    else
                        display('Error: Cannot determine background type')
                    end
                case 2 % turn on voc
                    TDT.triggerTDT(1);
                    TDT = TDT.updateCS(1);
                    % turn off after the voc has played fully
                    cIndex = TDT.RP.GetTagVal('VocIndex');
                    while cIndex < vocLen
                        cIndex = TDT.RP.GetTagVal('VocIndex');
                    end
                    % voc has played fully - turn it off
                    TDT.triggerTDT(2);
            end
        case '9'
            % TDT.triggerTDT(2); % Voc off first
            if TDT.vocOrNoise == '1'
                TDT.triggerTDT(4); % Turn off chorus
            else
                TDT.triggerTDT(6); % Turn off noise
            end
            TDT = TDT.updateCS(0); % reset
   end
end


% btag = 'SPKHTI4&80&1END';
