clc; clear; close all;

%% STEP1: CONFIGURAZIONE 
% Selezione cartella
folderPath = uigetdir(pwd, 'Seleziona Cartella Dataset');

if folderPath == 0
    error('Nessuna cartella selezionata.');
end

% Cerca le estensioni comuni per le immagini
extensions = {'*.tiff', '*.tif', '*.jpg', '*.png', '*.bmp'};
imageFiles = [];
for i = 1:length(extensions)
    imageFiles = [imageFiles; dir(fullfile(folderPath, extensions{i}))];
end

nFiles = length(imageFiles);
if nFiles == 0
    error('Nessuna immagine trovata nella cartella!');
end

% Crea cartella per i risultati
outputFolder = fullfile(folderPath, 'Risultati_Segmentazione');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

%% STEP 2: CICLO DI ELABORAZIONE
% Inizializziamo una waitbar per vedere il progresso
hWait = waitbar(0, 'Inizializzazione...');

for k = 1:nFiles
    
    baseFileName = imageFiles(k).name;
    fullFileName = fullfile(imageFiles(k).folder, baseFileName);
    
    try
        % Aggiorna barra progresso
        waitbar(k/nFiles, hWait, sprintf('Elaborazione: %s (%d/%d)', baseFileName, k, nFiles));
        
  
%% CODICE SEGMENTAZIONE (PUPILLA + IRIDE)
     img_rgb = imread(fullFileName);
        
        % Gestione Canali (Se RGB prendi Rosso, se Grigio lascia così)
        if size(img_rgb, 3) == 3
            img_red = img_rgb(:,:,1);
        else
            img_red = img_rgb;
        end
        
        % Rimozione Riflessi (Il tuo codice)
        se_tophat = strel('disk', 20);
        img_tophat = imtophat(img_red, se_tophat);
        mask_riflessi = img_tophat > 35;
        img_smooth = regionfill(img_red, mask_riflessi);
        
        % Enhancement
        img_gamma = imadjust(img_smooth, [0 1], [0.2 1], 1);
        img_enhanced = adapthisteq(img_gamma,'ClipLimit', 0.05 ,'Distribution', 'uniform', 'NumTiles', [6 6]);
        img_denoised = medfilt2(img_enhanced, [7 7]);
        
        %% STEP 2: ROI
        [rows, cols] = size(img_red);
        box_width = 180; box_height = 160; 
        
        % Centro immagine (o logica dinamica se preferisci)
        c_min = round(cols/2 - box_width/2); 
        r_min = round(rows/2 - box_height/2); 
        c_max = min(cols, c_min + box_width - 1);
        r_max = min(rows, r_min + box_height - 1);
        
        img_roi_denoised = img_denoised(r_min:r_max, c_min:c_max);
        
        %% PUPILLA
        img_pupil_in = img_roi_denoised; 
        img_no_ref = ordfilt2(img_pupil_in, 1, true(7));
        
        se_bg = strel('disk', 45); 
        img_bg = imclose(img_no_ref, se_bg);
        img_diff = imsubtract(img_bg, img_no_ref);
        
        [h_roi, w_roi] = size(img_diff);
        [xx, yy] = meshgrid(1:w_roi, 1:h_roi);
        sigma = w_roi / 3.0; 
        spotlight = exp(-((xx - w_roi/2).^2 + (yy - h_roi/2).^2) / (2 * sigma^2));
        
        img_weighted = uint8(double(img_diff) .* spotlight);
        
        img_calc = img_weighted;
        img_calc(img_calc > 100) = 100;
        soglia = double(max(img_calc(:))) * 0.30; 
        
        img_final_pupil = img_weighted;
        img_final_pupil(img_final_pupil < soglia) = 0;
        img_final_pupil = imgaussfilt(img_final_pupil, 2);
        
        [centers, radii, metric] = imfindcircles(img_final_pupil, [8 25], ...
            'ObjectPolarity', 'bright', 'Sensitivity', 0.96, 'Method', 'TwoStage');
        
        c_pupil = []; r_pupil = []; found_pupil = false;
        
        if ~isempty(centers)
            % Logica selezione pupilla (distanza dal centro ROI)
            dists = sqrt(sum((centers - [w_roi/2, h_roi/2]).^2, 2));
            valid_mask = dists < 20;
            
            if any(valid_mask)
                scores = (metric(valid_mask) * 100) - (dists(valid_mask) * 2);
                [~, best_sub_idx] = max(scores);
                valid_idx = find(valid_mask);
                
                c_pupil = centers(valid_idx(best_sub_idx), :);
                r_pupil = radii(valid_idx(best_sub_idx));
                found_pupil = true;
            else
                [~, best_idx] = min(dists);
                c_pupil = centers(best_idx, :);
                r_pupil = radii(best_idx);
                found_pupil = true;
            end
        end
        
        %% IRIDE
        c_iris = []; r_iris = []; found_iris = false;
        
        if found_pupil
            R_iris_min = round(r_pupil * 1.5); 
            R_iris_max = round(r_pupil * 4.5);
            
            % Usa immagine enhanced per iride
            img_iris_search = imgaussfilt(img_roi_denoised, 2.5);
            
            [centers_iris, radii_iris, metric_iris] = imfindcircles(img_iris_search, ...
                [R_iris_min R_iris_max], 'ObjectPolarity', 'dark', ...
                'Sensitivity', 0.98, 'EdgeThreshold', 0.02);
            
            if ~isempty(centers_iris)
                dists_iris = sqrt(sum((centers_iris - c_pupil).^2, 2));
                valid_mask = dists_iris < 25;
                if any(valid_mask)
                   scores = metric_iris(valid_mask) - (dists_iris(valid_mask) / 20);
                   [~, best_idx] = max(scores);
                   valid_idx = find(valid_mask);
                   c_iris = centers_iris(valid_idx(best_idx), :);
                   r_iris = radii_iris(valid_idx(best_idx));
                   found_iris = true;
                end
            end
        end
        
        %% STEP 5: VISUALIZZAZIONE E SALVATAGGIO
        % Creiamo una figura INVISIBILE ('visible', 'off') per velocità
        f = figure('visible', 'off'); 
        imshow(img_red); hold on;
        
        % Titolo con nome file
        titleStr = sprintf('%s', baseFileName);
        
        % Disegna ROI
        rectangle('Position', [c_min, r_min, box_width, box_height], 'EdgeColor', 'g');
        
        if found_pupil
            c_pupil_global = c_pupil + [c_min-1, r_min-1];
            viscircles(c_pupil_global, r_pupil, 'Color', 'r', 'LineWidth', 1);
            plot(c_pupil_global(1), c_pupil_global(2), 'r+', 'MarkerSize', 8);
        end
        
        if found_iris
            c_iris_global = c_iris + [c_min-1, r_min-1];
            viscircles(c_iris_global, r_iris, 'Color', 'c', 'LineWidth', 2);
        end
        hold off;
        
        % Salva immagine nella cartella risultati
        saveFileName = fullfile(outputFolder, strcat('Result_', baseFileName, '.jpg'));
        saveas(f, saveFileName);
        close(f); 
        
    catch ME
    end
end

close(hWait);
msgbox('Segmentazione Completata!');