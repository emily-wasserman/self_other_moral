function FIRSTTHIRD_practiceTrials()
% E.G., FIRSTTHIRD_practiceTrials()
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SET UP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if you are just testing on your laptop with no external monitor, uncomment:
Screen('Preference', 'SkipSyncTests', 1);
%% Init info
rootdir   = fileparts(which(mfilename)); % code directory path
behavDir  = fullfile(rootdir,'behavioral');

wrap      = 55;  %  new line of big font after this many characters
wrap_sm   = 70;  %  new line of small font after this many characters
big       = 35;  %  big font size
small     = 25;  %  small font size
trialtime = 14;  %  does not include jitter times

choiceRT   = zeros(4,1); % RT for card choice
choiceKey  = zeros(4,1); % button press for card choice (1 or 2)
RT         =  zeros(4,1); %RT for moral judgment
key        =  zeros(4,1); %keypress for moral judgment

card_white = fullfile(rootdir,'cards','card7.png');;
card_black = fullfile(rootdir,'cards','card8.png');;

f=load(fullfile(rootdir,'FIRSTTHIRD_stimuli.mat'));
instructions=f.instructions; 
question=f.question;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD STIMULI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PTB Stuff

% InitializePsychSound;
devices=PsychHID('devices');   
[dev_names{1:length(devices)}]=deal(devices.usageName);
kbd_devs = find(ismember(dev_names, 'Keyboard')==1);

HideCursor;
displays   = Screen('screens');
screenRect = Screen('rect', displays(end)); %
[x0,y0]    = RectCenter(screenRect); %sets Center for screenRect (x,y)
    
[s sRect]      = Screen('OpenWindow', displays(end),[0 0 0], screenRect, 32);

card_size1 = [0 0 250 350];
card_size2 = [0 0 250 350];
other_choice1 = [0 0 50 50];
other_choice2 = [0 0 50 50];

leftcard = CenterRectOnPoint(card_size1, sRect(3)/3, sRect(4)/2);
rightcard = CenterRectOnPoint(card_size2, 2*(sRect(3)/3), sRect(4)/2);
leftchoice = CenterRectOnPoint(other_choice1, sRect(3)/3, sRect(4)/5);
rightchoice = CenterRectOnPoint(other_choice2, 2*(sRect(3)/3), sRect(4)/5);

%% Instructions and Trigger
Screen(s,'TextSize',big);

DrawFormattedText(s,instructions{1},'center','center',255,wrap);
Screen('Flip',s);

while 1  % wait for the 1st trigger pulse
    FlushEvents;
    trig = GetChar;
    if trig == '+'
        break
    end
end
Screen('Flip',s);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN EXPERIMENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t0 = GetSecs; % used to time duration of experiment

for trial = 1:4
    
    trialStart = GetSecs; % start of trial
    
     %This is to prevent the continuous trigger at MIT from messing up
    %button press collection
    olddisabledkeys = DisableKeysForKbCheck(['+']);
    
    % present prompt ('CHOOSE/WATCH')
    Screen('FillRect',s,[0 0 0], screenRect);
    Screen(s,'TextSize',80);
    onsets(trial) = GetSecs - t0;
    DrawFormattedText(s,'CHOOSE','center','center',255,wrap_sm); 
    Screen('Flip',s);
    pause(2); %duration of prompt
    Screen('Flip',s);
    
    % present cards & collect button press
    if trial < 3
        lefty=Screen('MakeTexture',s, imread(card_black,'BackgroundColor',[0 0 0]));
        righty=Screen('MakeTexture',s, imread(card_white,'BackgroundColor',[0 0 0]));
    else
        lefty=Screen('MakeTexture',s, imread(card_white,'BackgroundColor',[0 0 0]));
        righty=Screen('MakeTexture',s, imread(card_black,'BackgroundColor',[0 0 0]));
    end
    Screen('DrawTexture',s,lefty,[],leftcard);
    Screen('DrawTexture',s,righty,[],rightcard);
    Screen('Flip',s);
    card_t = GetSecs;

    %get RT for choice button press:
    while (GetSecs - card_t) < 4;
        [keyIsDown timeSecs keyCode] = KbCheck(-1);       
       % 30:33 (right hand: index, middle, ring, pinky)
       % 46 is trigger
       % to find out what value corresponds to what key, type this on the
       % command window:
       % WaitSecs(0.1); [a b] = KbWait; find(b==1)
        [button number]         = intersect(30:33, find(keyCode));
        if choiceRT(trial)   == 0 & number > 0
            choiceRT(trial) = GetSecs - card_t;
            choiceKey(trial) = number;
        end
    end
    pause(4-(GetSecs-card_t));
    

  % present outcome text
    Screen(s,'TextSize',80);
    Screen('FillRect',s,[0 0 0], screenRect);
    if (ismember(trial,[1,4]) && choiceKey(trial)==1) || (ismember(trial,[2,3]) && choiceKey(trial)==2)
        % CORRECT
        DrawFormattedText(s,'NO NOISE','center','center',255,wrap_sm);
    else
        % INCORRECT
        DrawFormattedText(s,'NOISE','center','center',255,wrap_sm);
    end
    Screen('Flip',s);
    pause(4);

    % get judgment:
    % present question and multi-choice answers
    Screen(s,'TextSize',big);
    Screen('FillRect',s,[0 0 0], screenRect);
    DrawFormattedText(s,question{1},'center','center',255,wrap); 
    Screen('Flip',s); 
    response_t = GetSecs;
    
    % collect responses - gives 4 seconds to respond
    while (GetSecs - response_t) < 4;
        [keyIsDown timeSecs keyCode] = KbCheck(-1);       
       % 30:33 (right hand: index, middle, ring, pinky)
       % 46 is trigger
       % to find out what value corresponds to what key, type this on the
       % command window:
       % WaitSecs(0.1); [a b] = KbWait; find(b==1)
        [button number]         = intersect(30:33, find(keyCode));
        if RT(trial)   == 0 & number > 0
            RT(trial) = GetSecs - response_t;
            key(trial) = number;
        end
    end
    
   % % take question off screen:
    Screen('Flip',s);

   %  % collect trial duration
    % trial_dur(trial) = GetSecs - trialStart;
    
    %post-trial jitter:
    if trial<4
        pause(2);    
    else
        DrawFormattedText(s,'+','center','center',255,wrap_sm);
        Screen('Flip',s);
        pause(2);
    end
    
end

experimentDur = GetSecs - t0;

ShowCursor; Screen('CloseAll');

clear all;

end %ends main function
