function Output = encode(Input, msg)

block_size = [4 4];

msg_int = [0 255 unicode2native(msg, 'cp1250')];
    
% vypočítání koeficientů transformačních matic
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
% TODO: necelé bloky
count_x = ceil(size_x / block_size(1));
count_y = ceil(size_y / block_size(2));
block_count = count_x * count_y;

if block_count < length(msg_int) * 2
    disp('Obrázek není dostatečně velký pro uložení celého textu.');
end

for x_th=1:count_x       
    for y_th=1:count_y
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
        
        block_nr = (x_th - 1) * count_x + (y_th-1);
        char_pos = floor(block_nr/2);
        is_lower_bit = mod(block_nr, 2);
        
        while char_pos + 1 > length(msg_int)
            char_pos = char_pos - length(msg_int);
        end
        
        byte = dec2bin(msg_int(char_pos + 1), 8);
        if ~is_lower_bit
            msg = (byte(1:4) - 48) * 3;
        else
            msg = (byte(5:8) - 48) * 3;
        end
        
        zz(end-3:end) = msg;
                
        quant = izigzag(zz, block_size(1), block_size(2));
        current_block = round(B'*(quant .* Q)*B);
        
		% update the active area (window)
        Output(block_start_y:block_end_y, block_start_x:block_end_x) = current_block(:,:);
    end
end

Output = dip_image(Output);

end
