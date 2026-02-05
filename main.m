clc; clear; close all;

%% STEP 1: CARICAMENTO IMMAGINE E PRE PROCESSING

% Definizione manuale del file
image = 'Dataset_test_C1\C1_S2_I7.tiff'; 

% Lettura immagine
try
    img_rgb = imread(image);
catch
    error('File non trovato! Controlla il percorso del file.');
end

% Filtraggio canale Rosso
img_red = img_rgb(:,:,1); 

% Correzione riflessi ed enhancement
se_tophat = strel('disk', 20);
img_tophat = imtophat(img_red, se_tophat);
mask_riflessi = img_tophat > 35;
img_smooth = regionfill(img_red, mask_riflessi);
img_gamma = imadjust(img_smooth, [0 1], [0.2 1], 1);
img_enhanced = adapthisteq(img_gamma,'ClipLimit', 0.05 ,'Distribution', 'uniform', 'NumTiles', [6 6]);
img_denoised = medfilt2(img_enhanced, [7 7]);

% Visualizzazione grafica
figure('Name', 'Pre processing');
subplot(1,3,1); imshow(img_red); title('Canale Rosso Filtrato');
subplot(1,3,2); imshow(img_smooth); title('Riflessi rimossi');
subplot(1,3,3); imshow(img_denoised); title('Immagine pre processata');


%% STEP 2: STIMA DEL CENTRO (ROI)
% Imposta il centro della ROI al centro esatto dell'immagine
[rows, cols] = size(img_red);
y_center = rows/2;
x_center = cols/2;

% Definizione della ROI
box_width = 180;
box_height = 160; 

c_min = round(x_center - box_width/2); 
r_min = round(y_center - box_height/2); 
c_max = min(cols, c_min + box_width - 1);
r_max = min(rows, r_min + box_height - 1);

% Estrazione ROI
img_roi_denoised = img_denoised(r_min:r_max, c_min:c_max);

% Visualizzazione
figure('Name', 'ROI');
subplot(1, 1, 1); imshow(img_red); hold on;
rectangle('Position', [c_min, r_min, box_width, box_height], 'EdgeColor', 'g', 'LineWidth', 2); 
title('ROI selezionata');

%% STEP 3: Chiamata alle funzioni di segmentazione
%Segmentazione Hough
[c_pupil, r_pupil, c_iris, r_iris] = segmentazione_hough(img_roi_denoised);   

%% STEP 4: Visualizzazione segmentazione Hough
%Calcolo le coordinate globali per disegnare sull'immagine originale
c_pupil_global = c_pupil + [c_min-1, r_min-1];
c_iris_global = c_iris + [c_min-1, r_min-1];
    
figure('Name', 'Segmentazione completa');
imshow(img_red); hold on; 
title('Verde = ROI, Rosso = Pupilla, Ciano = Iride')

rectangle('Position', [c_min, r_min, box_width, box_height], 'EdgeColor', 'g');
viscircles(c_pupil_global, r_pupil, 'Color', 'r', 'LineWidth', 1);
viscircles(c_iris_global, r_iris, 'Color', 'c', 'LineWidth', 2);
        
% Marker Centri
plot(c_pupil_global(1), c_pupil_global(2), 'r+', 'MarkerSize', 8);
plot(c_iris_global(1), c_iris_global(2), 'bx', 'MarkerSize', 8);
        