# Iris Recognition System (MATLAB) 👁️

A complete biometric iris recognition pipeline implemented in MATLAB, based on **Hough transform and Daugman's algorithms**. 

This project processes eye images (specifically designed for the **UBIRIS v2** dataset), isolates the iris, extracts its unique textural features using 2D Gabor Wavelets, and performs identity verification via Hamming Distance matching.

The system implements a classic biometric pipeline to translate these patterns into a digital code (**IrisCode**) for authentication purposes.

The system is designed to handle noisy images (reflections, eyelashes, eyelids) typical of the UBIRIS dataset through advanced preprocessing and robust segmentation techniques.

---

## 🗝️ Key Features

* **Robust Preprocessing:** 
* **Hough Transform Segmentation:** Detects the pupil and iris boundaries using Circular Hough Transform with radius constraints.
* **Daugman's Rubber Sheet Normalization:** Unwraps the circular iris region into a fixed-size rectangular block ($64 \times 512$) using polar coordinates, ensuring invariance to size and pupil dilation.
* **Gabor Wavelet Encoding:** Extracts phase information using **2D Gabor Filters** (Real and Imaginary parts) to generate a binary feature template.
* **Hamming Distance Matching:** Performs bitwise comparison (XOR) to calculate the dissimilarity score between subjects.
* **Performance Analysis:** Includes tools to generate **Positive vs. Negative** histograms and calculate accuracy metrics.

---

## 🛠️ Project Structure

The project is modularized into separate functions for each stage of the pipeline:

```text
├── main_run_dataset.m       # Main script to process the entire dataset
├── matching_analysis.m      # Script for matching analysis
├── segmentazione_hough.m    # Function for pupil/iris segmentation
├── normalizza_iride.m       # Function for Rubber Sheet Normalization
├── encode_iris.m            # Function for Gabor Wavelet encoding
├── hamming_distance.m       # Function to calculate dissimilarity score
└── [Dataset Folder]         # Folder containing .tiff images (e.g., UBIRIS)
