%% Go/NoGo Task

% -------------------------------------------------------------------------

% Written by Yohyoh Wang for the CEDAR Lab at UIC, IRB#2017-1288
% yohyoh@uic.edu
% Principal Investigator: Ajna Hamidovic, PharmD, MS

% Version 1/15/2019

% -------------------------------------------------------------------------

% PURPOSE: The purpose of this program is to display a target, non-target
% 'X' and 'K' stimulus presentation series that logs responses of
% subjects to each frame. Subjects respond with a key press upon detection
% of the "Go" target, and must refrain from pressing a key when presented
% with the "NoGo" target.

% -------------------------------------------------------------------------

%% Task

function GNG
close all; clear
%% Experimental Preferences

prop.photoOn = 1;
%dell = 1;

% Extra Preferences
textsize = 24;
viewdist = 100; %distance from the screen (cm)
pixsize = 53.2/1920; %pixel size, computer-specific

% Trials
prop.numPract = 10;
prop.numPractGo = 8;
prop.numGo = 206;
prop.numNoGo = 39;
prop.numTot = prop.numGo + prop.numNoGo;
prop.percGo = prop.numGo/prop.numTot;

% Timing and Accuracy
prop.timeStim = 0.250; %stimulus duration (s)
prop.ISItype = [1.025 1.125 1.225]; %determine ISI types (s)

% Display Settings
%if dell == 1
 %   prop.dispSize = [1 1 1920 1080]; %forced resolution
%else
    prop.dispSize = get(0,'screensize');
%end
prop.dispCenterX = prop.dispSize(3)/2;
prop.dispCenterY = prop.dispSize(4)/2;
prop.dispBlack = [0 0 0];
prop.dispWhite = [255 255 255];
prop.countd = 5;
prop.countdSize = 72;
prop.crossSize = 10; %length of fixation cross arms
prop.crossWidth = 1; %line width of fixation cross
prop.crossLoc = [-prop.crossSize prop.crossSize 0 0; ...
    0 0 -prop.crossSize prop.crossSize]; %location (should be centered)

% Import Instructive Images
% prop.instr = imread('im_instr.png');
% prop.done = imread('im_done.png');

% Import Stimulus Images
prop.stimX = imread('im_stim_X.png');
prop.stimK = imread('im_stim_K.png');

% Stimulus Dimensions
prop.fixDim = 15; %length of fixation cross arm
prop.stimWidth = angle2pix(3, pixsize, viewdist); % search item size is 3x5deg
prop.stimHeight = angle2pix(5, pixsize, viewdist);
prop.fixWidth = angle2pix(4, pixsize, viewdist); %fixation square is 4x6deg
prop.fixHeight = angle2pix(6, pixsize, viewdist);
prop.fixRect = [prop.dispCenterX - prop.fixWidth/2, prop.dispCenterY - prop.fixHeight/2,...
    prop.dispCenterX + prop.fixWidth/2, prop.dispCenterY + prop.fixHeight/2];

%% Photo Sensor Preferences

prop.photoStim(1,:) = prop.dispWhite; %NoGo stimulus
prop.photoStim(2,:) = [100 100 100]; %Go stimulus
prop.photoStim(3,:) = [20 20 20]; %Start of experiment
prop.photoDim = [20, prop.dispSize(4)-60, 60, prop.dispSize(4)-20]; %oval is inscribed within this rectangle

%% Prompt

% Build GUI to input subject info
prompt = {'Leave as is; press OK', '', '',''};
defAns = {'0','1','1','p'}; % leave fields blank
box = inputdlg(prompt,'Enter Subject Info',1,defAns); %display GUI

if ~isempty(box)
    prop.subID = str2double(box{1}); % subject ID
    prop.session = str2double(box{2}); % session (1 or 2)
    prop.run = str2double(box{3}); % run (1 or 2)
    prop.mode = box{4};
    prop.root = pwd; % set path to current folder
else
    return
end

if ~exist([prop.root, filesep,'RUNS']) %make sure folder exists
    mkdir([prop.root, filesep,'RUNS'])
end

% File Name
fileName = [prop.root, filesep, 'RUNS', filesep, num2str(prop.subID), '_S' num2str(prop.session), '_R' num2str(prop.run), prop.mode, '.mat'];

if exist(fileName) && prop.subID~=0
    Screen('CloseAll');
    msgbox('File already exists.', 'modal') 
    return;
end

%% Mode Conditions

% Stimulus Conditions
if prop.mode == 'p'
    prop.nTrials = prop.numPract;
    prop.stim(1:prop.nTrials,1) = 0;
    prop.stim(1:prop.numPractGo,1) = 1;
elseif prop.mode == 't'
    prop.nTrials = prop.numTot;
    prop.stim(1:prop.nTrials,1) = 0;
    prop.stim(1:prop.numGo,1) = 1;
end

prop.nBreak = floor(prop.nTrials/3);

% Shuffle Conditions
prop.stim = prop.stim(randperm(length(prop.stim)));

% Structures for artifacts
prop.blink = zeros(prop.nTrials,2);
prop.fidget = zeros(prop.nTrials,2);

%% Space for Timing

time.stim.vblstamp = nan(prop.nTrials,1);
time.stim.onset = nan(prop.nTrials,1);
time.stim.flipstamp = nan(prop.nTrials,1);
time.stim.missed = nan(prop.nTrials,1);

time.ISI.vblstamp = nan(prop.nTrials,1);
time.ISI.onset = nan(prop.nTrials,1);
time.ISI.flipstamp = nan(prop.nTrials,1);
time.ISI.missed = nan(prop.nTrials,1);

%% Generate ISIs

% 1. Randomly permute ISI
for trial = 1:prop.nTrials
    prop.ISI(trial,1) = prop.ISItype(randi(length(prop.ISItype))); %ISI can either be 1, 2, or 3 (CONSTRAINT 2)
end

%% Save Stats

prop.stats.meanISI = mean(prop.ISI(:));

prop.stats.twoNoGo = 0;
for trial = 1:length(prop.stim)-1
    if prop.stim(trial) == 0 & prop.stim(trial+1) == 0
        prop.stats.twoNoGo = prop.stats.twoNoGo+1;
    end
end

%% Display Setup


PsychDefaultSetup(2);
Screen('Preference', 'VBLTimestampingMode', -1);

% PsychJavaTrouble
screenN = max(Screen('Screens'));
wPtr = Screen('OpenWindow', screenN); %opens a window
Screen('BlendFunction', wPtr, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% instructions
HideCursor; commandwindow; ListenChar(2); %hide cursor and prevent subject from typing into command window
Screen('FillRect', wPtr, prop.dispBlack); % background color
DrawFormattedText(wPtr, 'In this task, you will be presented with a series of letters. \n \n If the letter is ''X'', press the button. \n \n If the letter is ''K'', do not press the button. \n \n It is important that you respond as quickly and as accurately as possible. \n \n \n \n Press the button to continue.',...
    'centerblock', 'center', prop.dispWhite);
Screen('Flip',wPtr);
WaitSecs(1);

while KbCheck; end
KbName('UnifyKeyNames');
while 1
    [keyIsDown,secs,keyCode]=KbCheck;
    if keyCode(KbName('space'))
        if prop.photoOn == 1
            Screen('FillRect', wPtr , prop.dispBlack); %background color
            Screen('FillOval', wPtr, prop.photoStim(3,:), prop.photoDim); %photo sensor
            Screen('Flip',wPtr);
            WaitSecs(prop.timeStim);
        end
        break
    end
end

% 5-second countdown
for i=1:prop.countd
    Screen('FillRect', wPtr , prop.dispBlack); %background color
    DrawFormattedText(wPtr, num2str(prop.countd+1-i), 'center', 'center', prop.dispWhite);
    Screen('Flip',wPtr);
    WaitSecs(1);
end

%% Trial loop

for trial = 1:prop.nTrials
    Screen('FillRect', wPtr, prop.dispBlack); %background color
    % Screen('FrameRect', wPtr, prop.dispWhite, prop.fixRect); %fixation rectangle
    Screen('DrawLines', wPtr, prop.crossLoc, prop.crossWidth, ...
        prop.dispWhite, [prop.dispCenterX prop.dispCenterY]); %fixation cross
    
    if prop.photoOn == 1
        Screen('FillOval', wPtr, prop.photoStim(prop.stim(trial)+1,:), prop.photoDim); %photo sensor
    end
    
    if prop.stim(trial) == 1 %if Go stimulus
        stim = Screen('MakeTexture', wPtr, prop.stimX);
    elseif prop.stim(trial) == 0 %if NoGo stimulus
        stim = Screen('MakeTexture', wPtr, prop.stimK);
    end
    Screen('DrawTexture', wPtr, stim, [], [prop.dispCenterX-prop.stimWidth/2 prop.dispCenterY-prop.stimHeight/2 ...
        prop.dispCenterX+prop.stimWidth/2 prop.dispCenterY+prop.stimHeight/2]) % Draw stimulus
    
    % Flip stimulus
    [time.stim.vblstamp(trial,1),...
        time.stim.onset(trial,1),...
        time.stim.flipstamp(trial,1),...
        time.stim.missed(trial,1)] ...
        = Screen('Flip',wPtr);
    
    WaitSecs(prop.timeStim);
    
    % Wait for response
    Screen('FillRect', wPtr , prop.dispBlack); %background color
    % Screen('FrameRect', wPtr, prop.dispWhite, prop.fixRect); %fixation rectangle
    Screen('DrawLines', wPtr, prop.crossLoc, prop.crossWidth, ...
        prop.dispWhite, [prop.dispCenterX prop.dispCenterY]); %fixation cross
    
    % Stimulus off, start of ISI
    [time.ISI.vblstamp(trial,1),...
        time.ISI.onset(trial,1),...
        time.ISI.flipstamp(trial,1),...
        time.ISI.missed(trial,1)] ...
        = Screen('Flip',wPtr);
    
    rtStart = GetSecs;
    
    % Options for experimental control during ISI
    while KbCheck; end
    KbName('UnifyKeyNames');
    while GetSecs > rtStart
        ListenChar(0);
        [keyIsDown,secs,keyCode]=KbCheck;
        if keyCode(KbName('ESCAPE')) %press "ESC" to exit out
            if prop.subID~=0
                fprintf('Saving...')
                save(fileName,'prop','time');
                fprintf('done.')
            end
            Screen('CloseAll'); ShowCursor; ListenChar(0); %shows cursor, allows typing into command window
            return
        elseif keyCode(KbName('b'))  %if subject blinks
            prop.blink(trial,1) = 1; %make note of trial
            prop.blink(trial,2) = GetSecs; %latency
        elseif keyCode(KbName('f')) %if subject fidgets
            prop.fidget(trial,1) = 1; %make note of trial
            prop.fidget(trial,2) = GetSecs; %latency
        elseif keyCode(KbName('space')) %press space to pause
            Screen('TextSize', wPtr, textsize);
            Screen('FillRect', wPtr, prop.dispBlack);
            DrawFormattedText(wPtr, 'Task paused.', 'center', 'center', prop.dispWhite);
            Screen('Flip',wPtr);
            pause; %wait for keypress to continue
            
            %when key is pressed, another countdown
            for i=1:prop.countd
                Screen('FillRect', wPtr , prop.dispBlack); %background color
                Screen('TextSize', wPtr, prop.countdSize);
                DrawFormattedText(wPtr, num2str(prop.countd+1-i), 'center', 'center', prop.dispWhite);
                Screen('Flip',wPtr);
                WaitSecs(1);
            end
            
        end
        if GetSecs > rtStart + prop.ISI(trial) %move on to the next trial once ISI elapses
            break
        end
    end
    
    % Break
    if mod(trial,prop.nBreak) == 0 && prop.mode == 't' && prop.nTrials-trial > 5 %break after "nBreak" # trials
        Screen('TextSize', wPtr, textsize);
        Screen('FillRect', wPtr , prop.dispBlack); %background color
        DrawFormattedText(wPtr, 'Break. Relax for 15 seconds', 'center', 'center', prop.dispWhite)
        Screen('Flip', wPtr)
        WaitSecs(10)
        for i=1:prop.countd
            Screen('FillRect', wPtr , prop.dispBlack); %background color
            %     countd = Screen('MakeTexture', wPtr, prop.countd{i});
            %     Screen('DrawTexture', wPtr, countd, [], [prop.dispCenterX-prop.stimWidth/2 prop.dispCenterY-prop.stimHeight/2 ...
            %         prop.dispCenterX+prop.stimWidth/2 prop.dispCenterY+prop.stimHeight/2]) % Draw stimulus
            Screen('TextSize', wPtr, prop.countdSize);
            DrawFormattedText(wPtr, num2str(prop.countd+1-i), 'center', 'center', prop.dispWhite);
            Screen('Flip',wPtr);
            WaitSecs(1);
        end
    end
    
end

% Done with block
if trial == prop.nTrials %finished with block
    Screen('FillRect', wPtr , prop.dispBlack); %background color
    Screen('TextSize', wPtr, 24);
    DrawFormattedText(wPtr, 'Task Complete. \n \n Press space to close window.', 'centerblock', 'center', prop.dispWhite);
    Screen('Flip',wPtr);
    
    WaitSecs(1);
    
    while KbCheck; end
    KbName('UnifyKeyNames');
    space = KbName('space');
    while 1
        [keyIsDown,secs,keyCode]=KbCheck;
        if keyIsDown
            kp = find(keyCode);
            if kp == space
                Screen('CloseAll'); ShowCursor; ListenChar(0);
                if prop.subID~=0
                    fprintf('Saving...')
                    save(fileName,'prop','time');
                    fprintf('done.')
                end
                return
            end
        end
    end
    
end

Screen('CloseAll'); ShowCursor; ListenChar(0);
end

%% Additional Functions

% Convert visual degrees to pixels
function x = angle2pix(y, pixsize, viewdist)
x = round(tan(y/180*pi)*viewdist/pixsize);
end