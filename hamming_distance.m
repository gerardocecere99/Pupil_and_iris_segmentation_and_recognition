function score = hamming_distance(template1, template2)
%% MATCHING TRA DUE IRIS_CODE

% restituisce 1 se i bit sono diversi, 0 se uguali
diff_map = xor(template1, template2);
num_diff = sum(diff_map(:));

% 3. Normalizza
total_bits = numel(template1);

score = num_diff / total_bits;

end