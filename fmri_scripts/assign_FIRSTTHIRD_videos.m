
function assign_FIRSTTHIRD_videos(condition_order)
load('FIRSTTHIRD_stimuli.mat');

vids = videos;

vid_numbers = [1:36];

% distribute harm videos across runs
vid_numbers = Shuffle(vid_numbers);
% hack for grace
for i=1:3
    startnum=(i-1)*12+1;
    if ismember(3,vid_numbers(startnum:(startnum+11))) && ismember(6,vid_numbers(startnum:(startnum+11)))
        assign_FIRSTTHIRD_videos(condition_order);
    end
end % end hack
for i=1:3
    for j=1:12
        vids{(i-1)*2+1,j}=sprintf('harm_%d.mov',vid_numbers(j+((i-1)*12)));
        
    end
end
for i=1:3
    startnum=(i-1)*12+1;
    vid_numbers(startnum:(startnum+11)) = Shuffle(vid_numbers(startnum:(startnum+11)));
end
for i=1:3
    if i==1;sk=3;end
    if i==2;sk=1;end
    if i==3;sk=2;end
    for j=1:12
        vids{(i-1)*2+2,j}=sprintf('harm_%d.mov',vid_numbers(j+((sk-1)*12)));
    end
end
% distribute neutral videos across runs
vid_numbers = Shuffle(vid_numbers);
vid_numbers = [vid_numbers vid_numbers(1:12)];
vid_numbers(37:48) = Shuffle(vid_numbers(37:48));
for i=1:6
    if i<3 
        for j=1:12
            vids{i,12+j}=sprintf('neutral_%d.mov',vid_numbers(j+((i-1)*12)));
        end
    else if i>4 
        for j=1:12
            vids{i,12+j}=sprintf('neutral_%d.mov',vid_numbers(j+((i-3)*12)));
        end
    else
        for j=1:12
            vids{i,12+j}=sprintf('SELF');
        end
        end
    end
end
% do condition ordering
vids2=vids;
for c=1:length(condition_order)
    for j=1:24
%         disp(num2str((c-1)*2+1));
%         disp(num2str((condition_order(c)-1)*2+1));
        vids2{(c-1)*2+1,j} = vids{(condition_order(c)-1)*2+1,j};
        vids2{(c-1)*2+2,j} = vids{(condition_order(c)-1)*2+2,j};
    end
end

videos=vids2; clear vids2;
save('FIRSTTHIRD_stimuli.mat','videos','-append');
end % end function