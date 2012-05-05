function decoded = decode(Input)
%
% - Input ... an input image matrix

block_size = [4 4];

a = 1/2;
b = sqrt(a)*cos(pi/8);
c = sqrt(a)*cos(3*pi/8);
d = c/b;
B = [ 1 1 1 1; 1 d -d -1; 1 -1 -1 1; d -1 1 -d];
aa = a*a;
ab = a*b;
bb = b*b;
Q = [aa ab aa ab; ab bb ab bb; aa ab aa ab; ab bb ab bb];
% convert image into matrix
Input = double(Input);

% image size
size_x = size(Input,2);
size_y = size(Input,1);

% number of blocks
count_x = ceil(size_x / block_size(1));
count_y = ceil(size_y / block_size(2));
fullmessage = [];
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
        if(length(zz) == 16)
          msg = zz(end-3:end);
          fullmessage = [fullmessage msg];
        end
    end
end
% -1,0,1,2,3 -> 0,1
fullmessage = fullmessage > 1;

% decode fullmessage to decimal values

decoded = [];
ii = 1;
for i=1:8:(length(fullmessage))
    decoded = [decoded, (bin2dec(num2str(fullmessage(i:(i+7)))))];
    ii = ii + 1;
end

% find occurences (indices) of the delimiter

del_indices = [];
for i=1:(length(decoded))
  if(decoded(i) == 0 && i < length(decoded))
      if(decoded(i+1) == 255)
          del_indices = [del_indices i];
      end
  end
end

% find most frequent difference between dilimiters

shift_indices =  [ 0 del_indices ];
% differences between delimiters
differences = del_indices - shift_indices(1:end-1);
sorted = sortrows([(0:100)', histc(differences', 0:100)], -2);
most_frequent_diff = sorted(1,:); % [a,b] where a is difference, b is number of occurences

% split decoded message to array of sentences (numbers)
% result is a matrix with rows as sentences

S = [];
ii = 1;
for i=3:most_frequent_diff(1):(length(decoded) - most_frequent_diff(1))
    S(ii,:) = decoded(i:(i+most_frequent_diff(1)-2));
    ii = ii + 1;
end

% count number of occurences of letters on i-th position in sentence.
% Choose the most frequent one.
corrupted = 0; % is it possible to reconstruct a letter from each of the sentences?
sentence = [];
for i=1:size(S,2) % traverse all columns
    column = S(:,i);
    sorted = sortrows([(0:255)', histc(column, 0:0255)], -2);
    if(sorted(1,2) < (size(S,2) / 2)) % number of most frequent letter is 
        % not higher than half of the number of sentences
        corrupted = 1;
    end
    sentence = [sentence sorted(1,1)];
end
decoded = native2unicode(sentence, 'cp1250');
end


% encoded = encode(e,'Toto je super tajná zpráva v českém kódování.')
% imwrite(uint8(encoded), 'erika_message.bmp', 'BMP')
% r = rand(256,256)<0.001 matice % vygeneruje matici s 0 a 1, jednicek bude
% 1 promile
% encoded = encoded.*uint8(1-r) % zanest sum
% imwrite(uint8(encoded), 'erika_message_noise.bmp', 'BMP')

