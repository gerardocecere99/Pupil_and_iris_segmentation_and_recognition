function [template] = encode_iris(img_norm)
%% ENCODE IRIS CON GABOR 2D WAVELET (Onda sinusoidale)

img = im2double(img_norm);

% Frequenza spaziale 
wavelength = 18;            
% Dimensioni della finestra
sigma_x = 0.5 * wavelength;
sigma_y = 0.5 * wavelength; 

% Matrice per il filtro di dimensioni sufficienti per contenere la campana di Gauss
Msize = fix(4 * sigma_x); 
[x, y] = meshgrid(-Msize:Msize, -Msize:Msize);

% Campana 2D Gaussiana
gaussian_env = exp(-(x.^2)/(2*sigma_x^2) - (y.^2)/(2*sigma_y^2));

% Onde su asse x (cerchiamo texture verticali)
carrier_real = cos(2*pi*x/wavelength);
carrier_imag = sin(2*pi*x/wavelength);

% Gabor wavelet 
gabor_real = gaussian_env .* carrier_real;
gabor_imag = gaussian_env .* carrier_imag;

% Applicazione filtro di Gabor
response_real = conv2(img, gabor_real, 'same');
response_imag = conv2(img, gabor_imag, 'same');

% Quantizzazione 
bit_real = response_real > 0;
bit_imag = response_imag > 0;

template = [bit_real; bit_imag];

end