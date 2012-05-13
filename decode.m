function [decoded] = decode(Input)
%
% - Input ... an input image matrix
% 4x4 blocks will be processed
block_size = [4 4];

% construct matrices Q,B for intDCT
a = 1/2;
b = sqrt(a)*cos(pi/8);
c = sqrt(a)*cos(3*pi/8);
d = c/b;
B = [ 1 1 1 1; 1 d -d -1; 1 -1 -1 1; d -1 1 -d];
aa = a*a;
ab = a*b;
bb = b*b;
Q = [aa ab aa ab; ab bb ab bb; aa ab aa ab; ab bb ab bb];

corrupted = 0; % indicates wheter we can retrieve the message

% convert image into matrix
Input = double(Input);

% image size
size_x = size(Input,2);
size_y = size(Input,1);

% number of blocks
count_x = floor(size_x / block_size(1));
count_y = floor(size_y / block_size(2));
coeffs = []; % selected coefficiens from all blocks will be saved here
for x_th=1:count_x,       
    for y_th=1:count_y,
        % find the area of the current block
        block_start_x = (x_th-1)*block_size(1) + 1;
        block_start_y = (y_th-1)*block_size(2) + 1;
        % pay attention to the boundary item
        block_end_x = min(block_start_x + block_size(1) - 1,size_x);
        block_end_y = min(block_start_y + block_size(2) - 1,size_y);
        
        % copy the area
        current_block = Input(block_start_y:block_end_y, block_start_x:block_end_x);
        dct_block = round((B*current_block*B').*Q);
        
        zz = zigzag(dct_block);
        msg = zz(end-3:end);
        coeffs = [coeffs msg];
    end
end

% transform -1,0,1,2,3,4 to 0,1
bitcoeffs = coeffs > 1;

% decode bits to decimal values of ASCII characters
ordinals = []; 
ii = 1;
for i=1:8:(length(bitcoeffs)-8)
    ordinals = [ordinals, (bin2dec(num2str(bitcoeffs(i:(i+7)))))];
    ii = ii + 1;
end

% find occurences (indices) of the delimiter

delimiters = [];
for i=1:(length(ordinals))
  if(ordinals(i) == 0 && i < length(ordinals))
      if(ordinals(i+1) == 255)
          delimiters = [delimiters i];
      end
  end
end

if(length(delimiters) < 1)
    corrupted = 1;
    error('Message cannot be correctly retrieved. No delimiters were found');
end
% find most frequent difference between dilimiters. This indicates the
% length of one sentence in the message

shift_delimiters =  [ 0 delimiters ];
% differences between delimiters
delimiters_differences = delimiters - shift_delimiters(1:end-1);
uniq = unique(delimiters_differences);
sorted = sortrows([uniq', histc(delimiters_differences', uniq)], -2);
most_frequent_difference = sorted(1,:); % [a,b] where a is difference, b is number of occurences

% split decoded message to array of sentences (numbers)
% result is a matrix with rows as sentences

S = [];
ii = 1;
for i=3:most_frequent_difference(1):(length(ordinals) - most_frequent_difference(1))
    S(ii,:) = ordinals(i:(i+most_frequent_difference(1)-2));
    ii = ii + 1;
end

% count number of occurences of letters on i-th position in sentence.
% Choose the most frequent one.
sentence = [];
for i=1:size(S,2) % traverse all columns
    column = S(:,i);
    sorted = sortrows([(0:255)', histc(column, 0:255)], -2);
%    if(sorted(1,2) < (size(S,1) / 2)) % number of most frequent letter is 
        % not higher than half of the number of sentences
%        corrupted = 1;
%        error('Message cannot be correctly retrieved. Letter in the sentence does not occur in the other sencentes in required number.');
%    end
    sentence = [sentence sorted(1,1)];
end
decoded = native2unicode(sentence, 'cp1250');
end

% Notes
% encoded = encode(e,'Toto je super tajná zpráva v českém kódování.')
% imwrite(uint8(encoded), 'erika_message.bmp', 'BMP')
% r = rand(256,256)<0.001 matice % vygeneruje matici s 0 a 1, jednicek bude
% 1 promile
% encoded = encoded.*uint8(1-r) % zanest sum
% imwrite(uint8(encoded), 'erika_message_noise.bmp', 'BMP')

