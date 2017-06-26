function FIRSTTHIRD(subjID,confed,acq,cond,cond_iter)
% E.G., FIRSTTHIRD('YOU_FIRSTTHIRD_01','grace',1,1,0)
%
% confed: string of confederate's name ('grace','julia',etc.)
% 
% cond:
% 1: 1p (2 runs)
% 2: computer (2 runs)
% 3: 3p (2 runs)
% 
% cond_iter: are you on the 0th or 1st run of this condition?
% 
% Total trials: 6 x 24 = 144
% design_run = 1x24 vector of conditions (1:6) used for THIS run
% RT         = 1x24 vector of reaction times for each run
% key        = 1x24 vector of user responses. 1=first choice, 4=last choice
% choiceRT   = 1x24 vector of reaction times for the choice period
% choiceKey  = 1x24 vector of keypresses for the card choice
% cards1_run = 1x24 cell of card filenames for the left card
% cards2_run = 1x24 cell of card filenames for the right card
% videos_run = 1x24 cell of video filenames shown in this run
% jitter_run = 1x24 vector of jitter values for the period after each trial
% design_randomization = 6 x 24 matrix, each row holding the values 1:24 shuffled
% this produces true trial randomization within each run

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
%PROMPT: 2s
%CHOOSE: 4s
%OUTCOME: 4s
%JUDG: 4s
% TOTAL: 14 s
% JITTER: 0-4s
% END OF RUN: 10s

trial_length = 14;
ips       = (14*24)/2 + (16+32)/2 + 5; % 197

rand('twister',GetSecs);% generate a new psuedorandom sequence

cd(behavDir);

try % after first run, load the same sequence
    load([subjID '.FIRSTTHIRD.1.mat'],'design_randomization','jitter');
catch % first run
    design_randomization = [];
    for j=1:6
        des_rand = Shuffle([1:24]);
        design_randomization=[design_randomization;des_rand];
    end
    jitter=[];
    for j=1:6
        jit = Shuffle([repmat(0,1,8) repmat(2,1,8) repmat(4,1,8)]);
        jitter=[jitter;jit];
    end
end
save([subjID '.FIRSTTHIRD.' num2str(acq) '.mat'],'design_randomization','jitter');

choiceRT   = zeros(24,1); % RT for card choice
choiceKey  = zeros(24,1); % button press for card choice (1 or 2)
RT         =  zeros(24,1); %RT for moral judgment
key        =  zeros(24,1); %keypress for moral judgment

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD STIMULI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STIMULUS FILE CONTAINS:
% instructions (cell): 3x1 cell of instructions
% question (string): wrongness question
% prompt(cell): 3x1 cell of prompts
% cards: 6 x 24 struct of card filenames to display
% cards(i).card1{j} = 'thiscard.jpg'
% cards(i).card2{j} = 'thatcard.jpg'
% videos: 6 x 24 cell matrix of video filenames to display
% videos{i,j} = 'thisvideo.mov'
% NOTE: for design_outcomes, the first 2 correspond to 1p, 
% second 2 to computer, third 2 to 3p runs
% design_outcomes: 6 x 24 matrix of predetermined outcomes
% design_outcomes(1) = [1 2 1 2 1 ...], etc.
% design values are as follows
% - 1: SelfHarmOther
% - 2: SelfNeutOther
% - 3: CompHarmOther
% - 4: CompHarmSelf
% - 5: OtherHarmOther
% - 6: OtherNeutOther
load(fullfile(rootdir,'FIRSTTHIRD_stimuli.mat')); 
for run_num = 1:6
    for item_num = 1:24
        cards(run_num).card1{item_num} = fullfile(rootdir,'cards',cards(run_num).card1{item_num});
        cards(run_num).card2{item_num} = fullfile(rootdir,'cards',cards(run_num).card2{item_num});
        if strcmp(videos{run_num,item_num},'SELF')
            videos{run_num,item_num} = fullfile(rootdir,'videos','participants',[subjID '.png']);
        else
            videos{run_num,item_num} = fullfile(rootdir,'videos',confed,[confed '_' videos{run_num,item_num}]);
        end
    end
end
participant_image = fullfile(rootdir,'videos','participants',[subjID '.png']);
% keyboard
noise_file = fullfile(rootdir,'whitenoise.wav');
% make sure to re-randomize the cards and videos when you load the stimuli file
% note that the design values must match the cards/videos, so randomize them together
cards1_run = cell(24,1);
cards2_run = cell(24,1);
videos_run = cell(24,1);
for item_num=1:24
  cards1_run{item_num} = cards(acq).card1{design_randomization(acq,item_num)};
  cards2_run{item_num} = cards(acq).card2{design_randomization(acq,item_num)};
  videos_run{item_num} = videos{acq,design_randomization(acq,item_num)};
end
% make sure you choose the outcomes for this particular condition
design_run = design_outcomes((cond+(cond-1)+cond_iter),:);
design_run = design_run(design_randomization(acq,:));
jitter_run = jitter(acq,:);
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
self_image_size = [0 0 1080 720];

leftcard = CenterRectOnPoint(card_size1, sRect(3)/3, sRect(4)/2);
rightcard = CenterRectOnPoint(card_size2, 2*(sRect(3)/3), sRect(4)/2);
leftchoice = CenterRectOnPoint(other_choice1, sRect(3)/3, sRect(4)/5);
rightchoice = CenterRectOnPoint(other_choice2, 2*(sRect(3)/3), sRect(4)/5);
self_image = CenterRectOnPoint(self_image_size, sRect(3)/2, sRect(4)/2);

% [y, freq] = psychwavread(noise_file);
% wavedata = y';
% nrchannels = size(wavedata,1);
[noisedata,noisefreq]=audioread(noise_file);
%% Instructions and Trigger
Screen(s,'TextSize',big);

DrawFormattedText(s,instructions{cond},'center','center',255,wrap);
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

for trial = 1:24
    
    trialStart = GetSecs; % start of trial
    
     %This is to prevent the continuous trigger at MIT from messing up
    %button press collection
    olddisabledkeys = DisableKeysForKbCheck(['+']);
    
    % present prompt ('CHOOSE/WATCH')
    Screen('FillRect',s,[0 0 0], screenRect);
    Screen(s,'TextSize',80);
    onsets(trial) = GetSecs - t0;
    DrawFormattedText(s,prompt{cond},'center','center',255,wrap_sm); 
    Screen('Flip',s);
    pause(2); %duration of prompt
    Screen('Flip',s);
    
    % present cards & collect button press
    lefty=Screen('MakeTexture',s, imread(cards1_run{trial},'BackgroundColor',[0 0 0]));
    righty=Screen('MakeTexture',s, imread(cards2_run{trial},'BackgroundColor',[0 0 0]));
    Screen('DrawTexture',s,lefty,[],leftcard);
    Screen('DrawTexture',s,righty,[],rightcard);
    Screen('Flip',s);
    card_t = GetSecs;

    %get RT for choice button press:
    if cond == 1 % 1p; wait for participant's keypress
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
    else if cond == 2 % computer: make immediate choice
        choiceKey(trial) = randi(2);
        choiceRT(trial) = 0;
        if choiceKey(trial)==1
            Screen('DrawTexture',s,lefty,[],leftcard);
            Screen('DrawTexture',s,righty,[],rightcard);
            Screen('FillOval',s,255,leftchoice);
            Screen('Flip',s);
        else
            Screen('DrawTexture',s,lefty,[],leftcard);
            Screen('DrawTexture',s,righty,[],rightcard);
            Screen('FillOval',s,255,rightchoice);
            Screen('Flip',s);
        end
        pause(4-(GetSecs-card_t));
    else if cond == 3 % 3p: make delayed choice
        choiceRT(trial)=(1.5-0.3).*rand(1,1) + 0.3;
        choiceKey(trial) = randi(2);
        pause(choiceRT);
        if choiceKey(trial)==1
            Screen('DrawTexture',s,lefty,[],leftcard);
            Screen('DrawTexture',s,righty,[],rightcard);
            Screen('FillOval',s,255,leftchoice);
            Screen('Flip',s);
        else
            Screen('DrawTexture',s,lefty,[],leftcard);
            Screen('DrawTexture',s,righty,[],rightcard);
            Screen('FillOval',s,255,rightchoice);
            Screen('Flip',s);
        end
        pause(4-(GetSecs-card_t));
    end
    end
    end

  % present outcome video
    if design_run(trial)==4 % show still self image
        im_draw=Screen('MakeTexture',s, imread(participant_image,'BackgroundColor',[0 0 0]));
        Screen('DrawTexture',s,im_draw,[],self_image);
        % Screen('DrawTexture',s,im_draw);
        Screen('Flip',s);
        % noiseblast
        % noise_handle = PsychPortAudio('Open', [], [], 0, freq, nrchannels);
        % PsychPortAudio('FillBuffer', noise_handle, wavedata);
        % PsychPortAudio('Start', noise_handle, 1, 0, 1);
        sound(noisedata,noisefreq);
        vid_t = GetSecs;
        pause(4);
        % PsychPortAudio('Stop', noise_handle);
        % PsychPortAudio('Close', noise_handle);
    else
        outcome_video = Screen('OpenMovie', s, videos_run{trial});
        Screen('PlayMovie', outcome_video, 1,0,0);
        vid_t = GetSecs;
        while ~KbCheck
            vidframe=Screen('GetMovieImage',s,outcome_video);
            if vidframe <= 0
                break
            end
            Screen('DrawTexture',s,vidframe);
            Screen('Flip',s);
            Screen('Close',vidframe);
        end
        Screen('PlayMovie',outcome_video,0);
        Screen('CloseMovie',outcome_video);
        pause(4-(GetSecs-vid_t));
    end

    % get judgment:
    % present question and multi-choice answers
    Screen(s,'TextSize',big);
    Screen('FillRect',s,[0 0 0], screenRect);
    DrawFormattedText(s,question{cond},'center','center',255,wrap); 
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
    trial_dur(trial) = GetSecs - trialStart;
    
    %post-trial jitter:
    if trial<24
        pause(jitter_run(trial));    
    else
        DrawFormattedText(s,'+','center','center',255,wrap_sm);
        Screen('Flip',s);
        pause(10);
    end
    
    save([subjID '.FIRSTTHIRD.' num2str(acq) '.mat'],'ips','RT','choiceRT','choiceKey','key','design_run','jitter','jitter_run',...
        'onsets','trial_dur','acq','subjID','cond','confed','cards1_run','cards2_run','videos_run','-append');
    
    % while GetSecs - trialStart < trialtime;end
    
end

experimentDur = GetSecs - t0;

%% Analysis Info

%% Analysis Info
condnames = {'SelfHarmOther' 'SelfNeutOther' 'CompHarmOther' 'CompHarmSelf' 'OtherHarmOther' 'OtherNeutOther'};

% define contrasts for later
con_info(1).name = 'self > other';
con_info(1).vals = [1 1 0 0 -1 -1];
con_info(2).name = 'self > comp';
con_info(2).vals = [1 1 -1 -1 0 0];
con_info(3).name = 'other > self';
con_info(3).vals = [-1 -1 0 0 1 1];
con_info(4).name = 'other > comp';
con_info(4).vals = [0 0 -1 -1 1 1];
con_info(5).name = 'comp > self';
con_info(5).vals = [-1 -1 1 1 0 0];
con_info(6).name = 'comp > other';
con_info(6).vals = [0 0 1 1 -1 -1];
con_info(7).name = 'active > passive';
con_info(7).vals = [1 1 -.5 -.5 -.5 -.5];
con_info(8).name = 'passive > active';
con_info(8).vals = [-1 -1 .5 .5 .5 .5];
con_info(9).name = 'all harm > all neutral';
con_info(9).vals = [.5 -1 .5 .5 .5 -1];
con_info(10).name = 'self_harm_other > other_harm_other';
con_info(10).vals = [1 0 0 0 -1 0];
con_info(11).name = 'other_harm_other > self_harm_other';
con_info(11).vals = [-1 0 0 0 1 0];
con_info(12).name = 'self_harm_other > self_neut_other';
con_info(12).vals = [1 -1 0 0 0 0];
con_info(13).name = 'other_harm_other > other_neut_other';
con_info(13).vals = [0 0 0 0 1 -1];
con_info(14).name = 'self_harm_other > comp_harm_other';
con_info(14).vals = [1 0 -1 0 0 0];
con_info(15).name = 'comp_harm_other > comp_harm_self';
con_info(15).vals = [0 0 1 -1 0 0];
con_info(16).name = 'self_harm_other > comp-other_harm_other';
con_info(16).vals = [1 0 -.5 0 -.5 0];
con_info(17).name = 'comp-other_harm_other > self_harm_other';
con_info(17).vals = [-1 0 .5 0 .5 0];
con_info(18).name = 'other_harm_other > comp_harm_other';
con_info(18).vals = [0 0 -1 0 1 0];
con_info(19).name = 'self_harm_other > comp_harm_self';
con_info(19).vals = [1 0 0 -1 0 0];
con_info(20).name = 'other_harm_other > comp_harm_self';
con_info(20).vals = [0 0 0 -1 1 0];


%set up spm_inputs 
for design_ind = 1:6;    
    spm_inputs(design_ind).name = condnames{design_ind};
    try
      spm_inputs(design_ind).ons  = onsets(find(design_run==design_ind));
      spm_inputs(design_ind).dur  = repmat(trial_length,length(spm_inputs(design_ind).ons),1);
    catch
      spm_inputs(design_ind).ons = NaN;
      spm_inputs(design_ind).dur  = NaN;
    end
    % total time a stimulus is on the screen, for one trial, in scans
end

%% Saves data

cd(behavDir);

%saves full set of variables in behavioral dir 
save([subjID '.FIRSTTHIRD.' num2str(acq) '.mat'],'spm_inputs','con_info','experimentDur','-append'); 

clear spm_inputs;

cd ..

ShowCursor; Screen('CloseAll');

clear all;

end %ends main function
