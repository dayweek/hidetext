function Image_out = degrade_image(Image_in)

Image_out = Image_in;
s_x = size(Image_in, 1);
s_y = size(Image_in, 2);

pocet_vadnych_pixelu = round((s_x * s_y) / 1000);

pozice = rand(pocet_vadnych_pixelu, 2);

pozice(:, 1) = floor(pozice(:, 1) * s_x);
pozice(:, 2) = floor(pozice(:, 2) * s_y);

for i = 1:length(pozice)
    Image_out(pozice(i, 1), pozice(i, 2)) = 255;
end

end

