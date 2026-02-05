function [c_pupil, r_pupil, c_iris, r_iris] = segmentazione_hough(img_roi_denoised)

%% SEGMENTAZIONE PUPILLA
img_pupil_in = img_roi_denoised; 

% Rimozione riflessi residui 
img_no_ref = ordfilt2(img_pupil_in, 1, true(7));

% Sottrazione dello sfondo
se_bg = strel('disk', 45); 
img_bg = imclose(img_no_ref, se_bg);
img_diff = imsubtract(img_bg, img_no_ref);

% Oscuriamo tutto ciò che non è al centro della ROI.
[h_roi, w_roi] = size(img_diff);
[xx, yy] = meshgrid(1:w_roi, 1:h_roi);
center_x = w_roi/2; center_y = h_roi/2;
sigma = w_roi / 3.0; 
spotlight = exp(-((xx - center_x).^2 + (yy - center_y).^2) / (2 * sigma^2));
img_weighted = uint8(double(img_diff) .* spotlight);

% Clamping
img_calc = img_weighted;
img_calc(img_calc > 100) = 100;
max_val = max(img_calc(:));
soglia = double(max_val) * 0.30; 

img_pupil = img_weighted;
img_pupil(img_pupil < soglia) = 0;
img_pupil = imgaussfilt(img_pupil, 2); % Blur per lisciare i bordi

% Hough Transform
% Cerchiamo cerchi luminosi poichè ora la pupilla è bianca
Rp_range = [8 25]; 

[centers, radii, metric] = imfindcircles(img_pupil, Rp_range, ...
    'ObjectPolarity', 'bright', ... 
    'Sensitivity', 0.96, ... 
    'EdgeThreshold', 0.05, ...
    'Method', 'TwoStage');

if ~isempty(centers)
    
    % Calcoliamo la distanza dal centro esatto della ROI.
    c_roi_center = [w_roi/2, h_roi/2];
    dists = sqrt(sum((centers - c_roi_center).^2, 2));
    
    %Accettiamo solo cerchi vicinissimi al centro (< 20px)
    valid = dists < 20;
    
    if any(valid)
        % Tra quelli validi, prendiamo quello con il punteggio migliore
        % Vogliamo massimizzare la metrica e minimizzare la distanza
        scores = (metric(valid) * 100) - (dists(valid) * 2);
        
        [~, best_sub_idx] = max(scores);
        
        valid_indices = find(valid);
        best_idx = valid_indices(best_sub_idx);
        
        c_pupil = centers(best_idx, :);
        r_pupil = radii(best_idx);
    end
end

%% SEGMENTAZIONE IRIDE
% L'iride è tipicamente tra 1.5 e 4.5 volte la pupilla.
R_iris_min = round(r_pupil*1.5); 
R_iris_max = round(r_pupil*4.5);
   
% Preparazione immagine
img_iris = img_roi_denoised; 
img_iris = imgaussfilt(img_iris, 2.5);

% Hough Transform
% Cerchiamo cerchi scuri (iride) su sfondo chiaro (sclera)
[centers_iris, radii_iris, metric_iris] = imfindcircles(img_iris, ...
[R_iris_min R_iris_max], ...
'ObjectPolarity', 'dark', ... 
'Sensitivity', 0.98, ...      
'EdgeThreshold', 0.02, ...    
'Method', 'TwoStage');
    
    if ~isempty(centers_iris)

        % Filtro: cartiamo cerchi il cui centro è troppo lontano dalla pupilla
        dists_iris = sqrt(sum((centers_iris - c_pupil).^2, 2));
        valid = dists_iris < 25; % Tolleranza max 25 pixel
        
        if any(valid)
            % Selezioniamo i candidati validi
            c_valid = centers_iris(valid, :);
            r_valid = radii_iris(valid, :);
            m_valid = metric_iris(valid, :);
            d_valid = dists_iris(valid, :);
            
            % Preferiamo cerchi forti e concentrici 
            scores = m_valid - (d_valid / 20);
            
            [~, best_idx] = max(scores);
            
            c_iris = c_valid(best_idx, :);
            r_iris = r_valid(best_idx);
        end
    end
    