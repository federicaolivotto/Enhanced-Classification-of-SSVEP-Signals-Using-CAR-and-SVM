# 🧠 Enhanced Classification of SSVEP Signals  
### Using Common Average Referencing and Support Vector Machines  

## 📌 Overview
This project focuses on improving the performance of **SSVEP-based Brain-Computer Interfaces (BCIs)** through enhanced signal preprocessing and classification techniques.

The pipeline combines:
- **Common Average Referencing (CAR)** for noise reduction  
- **Canonical Correlation Analysis (CCA)** for feature extraction  
- **Support Vector Machines (SVM)** for robust multiclass classification  

The proposed approach improves both **Signal-to-Noise Ratio (SNR)** and **classification accuracy**, making it suitable for real-time BCI applications.

---

## 🧪 Objectives
- Improve detection of SSVEP frequencies and harmonics  
- Reduce noise in EEG signals  
- Enhance classification performance beyond standard CCA  
- Analyze trade-offs between **accuracy** and **processing speed**  

---

## 📊 Dataset
- **40-target SSVEP speller dataset**
- **35 subjects**
- **64 EEG channels**
- Sampling rate: **250 Hz**
- Trials: **240 per subject (40 targets × 6 blocks)**  

Each trial duration:
- 0.5 s pre-stimulus  
- 5 s stimulation  
- 0.5 s post-stimulus  

---

## ⚙️ Methodology

### 1. Preprocessing
- Selection of **9 occipital/parieto-occipital electrodes**  
- Signal trimming (removal of non-informative segments + latency delay)  
- Application of **Common Average Reference (CAR)**  
- **Bandpass filtering (5–90 Hz)** using a Butterworth filter  

👉 CAR significantly improves harmonic peak visibility in the frequency domain.

---

### 2. Feature Extraction (CCA)
- EEG signals are compared with **sinusoidal reference signals**  
- References include:
  - Fundamental frequencies  
  - First **5 harmonics**  

CCA extracts **correlation coefficients (ρ)** for each frequency → feature vector.

---

### 3. Classification (SVM)
- Multiclass classification using:
  - **Support Vector Machine (SVM)**
  - **ECOC (Error-Correcting Output Codes)** strategy  

#### Dataset split:
- Training: first 5 blocks (200 trials)  
- Testing: last block (40 trials)  

SVM replaces the traditional **maximum correlation classifier**, improving robustness especially for short signals.

---

## 📈 Results

### 🔹 Effect of CAR
- Increased SNR  
- Clearer peaks at stimulus frequencies and harmonics  
- Improved classification accuracy  

### 🔹 Best Performance

| Method | Accuracy | ITR |
|--------|--------|-----|
| CCA (no CAR) | 76.87% | 56.90 |
| CAR + CCA | 79.26% | 59.82 |
| CCA + SVM | 82.14% | 63.45 |
| **CAR + CCA + SVM** | **83.79%** | **65.58** |

---

### ⏱️ Time Window Analysis
- Optimal window: **~2.5 seconds**
- Trade-off:
  - Longer window → higher accuracy  
  - Shorter window → faster response  

---

## 📊 Evaluation Metrics
- Classification Accuracy  
- Signal-to-Noise Ratio (SNR)  
- Information Transfer Rate (ITR)  
- ROC Curves & AUC  
- Confusion Matrix  

---

## 🚀 Key Insights
- CAR improves signal quality even when a reference electrode is already used  
- SVM significantly enhances classification compared to standard CCA  
- Combining signal processing + machine learning yields the best results  
- Optimal performance requires balancing **speed vs accuracy**

---

## ⚠️ Limitations
- Tested only on **offline benchmark dataset**  
- No real-time validation  
- ITR estimated assuming ideal timing conditions  

---

## 🔮 Future Work
- Real-time BCI implementation  
- Subject-specific calibration (individual templates)  
- Adaptive / online learning models  
- Dynamic trial duration based on classifier confidence  
- Improved experimental design (e.g., stimulus spacing)

---

## 🛠️ Technologies
- **MATLAB** (main implementation)  
- Signal Processing  
- Machine Learning (SVM)  
- EEG Analysis  

---

## 👩‍💻 Author
**Federica Maria Olivotto**
**Paolo Di Giglio**

---

## 📎 Notes
This repository contains the project report and supporting material for an academic study on SSVEP-based BCI systems.
