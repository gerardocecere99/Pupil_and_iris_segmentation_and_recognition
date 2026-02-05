%% Segmentazione su tutte le immagini usando il metodo scelto.
clc; clear; close all;

% Scelta metodo (1 = Hough, 2 = Daugman)
SCELTA_METODO = 1; 

% Selezione cartella Dataset
folderPath = uigetdir(pwd, 'Seleziona Cartella Dataset');
if folderPath == 0, error('Annullato.'); end

files = dir(fullfile(folderPath, '*.tiff')); 
nFiles = length(files);
if nFiles == 0, error('Nessuna immagine trovata.'); end

% Crea cartella Output
if SCELTA_METODO == 1
    nome_metodo = 'Hough';
else
    nome_metodo = 'ActiveContours';
end
out_dir = fullfile(folderPath, ['Risultati_' nome_metodo]);
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

% Ciclo elaborazione
hWait = waitbar(0, 'Elaborazione...');

for k = 1:nFiles
    fname = files(k).name;
    fullPath = fullfile(folderPath, fname);

        waitbar(k/nFiles, hWait, sprintf('%d/%d: %s', k, nFiles));
        
% Filtraggio canale Rosso
img_rgb = imread(fullPath);
img_red = img_rgb(:,:,1); 

% Correzione riflessi ed enhancement
se_tophat = strel('disk', 20);
img_tophat = imtophat(img_red, se_tophat);
mask_riflessi = img_tophat > 35;
img_smooth = regionfill(img_red, mask_riflessi);
img_gamma = imadjust(img_smooth, [0 1], [0.2 1], 1);
img_enhanced = adapthisteq(img_gamma,'ClipLimit', 0.05 ,'Distribution', 'uniform', 'NumTiles', [6 6]);
img_denoised = medfilt2(img_enhanced, [7 7]);

% Calcolo ROI
% Imposta il centro della ROI al centro esatto dell'immagine
[rows, cols] = size(img_red);
y_center = rows/2;
x_center = cols/2;

box_width = 180;
box_height = 160; 

c_min = round(x_center - box_width/2); 
r_min = round(y_center - box_height/2); 
c_max = min(cols, c_min + box_width - 1);
r_max = min(rows, r_min + box_height - 1);

% Estrazione ROI
img_roi_denoised = img_denoised(r_min:r_max, c_min:c_max);
        
% Chiamata funzione di segmentazione scelta
        if SCELTA_METODO == 1
            % Chiama la funzione Hough 
            [c_pupil, r_pupil, c_iris, r_iris] = segmentazione_hough(img_roi_denoised); 
        else
            % Chiama la funzione Active
            %[cp, rp, ci, ri, ok] = segmentazione_active(img_red, c_min, r_min);
        end

% Salvataggio risultato
%Calcolo le coordinate globali per disegnare sull'immagine originale
c_pupil_global = c_pupil + [c_min-1, r_min-1];
c_iris_global = c_iris + [c_min-1, r_min-1];

f = figure('visible', 'off'); 
imshow(img_red); hold on;
title(fname, 'Interpreter', 'none');
rectangle('Position', [c_min, r_min, box_width, box_height], 'EdgeColor', 'g');
viscircles(c_pupil_global, r_pupil, 'Color', 'r', 'LineWidth', 1);
viscircles(c_iris_global, r_iris, 'Color', 'c', 'LineWidth', 2);

% Marker Centri
plot(c_pupil_global(1), c_pupil_global(2), 'r+', 'MarkerSize', 8);
plot(c_iris_global(1), c_iris_global(2), 'bx', 'MarkerSize', 8);
   


saveas(f, fullfile(out_dir, ['Res_' fname '.jpg']));
close(f);
        
end

close(hWait);
msgbox('Operazione completata!');