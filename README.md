# CWT-based BP Estimation Preprocessing (PPG → CWT)

This repository provides an open-source implementation of the **PPG Continuous Wavelet Transform (CWT, Complex Morlet)** preprocessing pipeline aimed at cuffless blood pressure estimation tasks.

**Core Objective:** Slice raw PPG waveforms into fixed windows and generate **256×256×2 (Real + Imag)** CWT tensors, consistent with the reference paper, to serve as input for Deep Learning models.

> **Note:** This repository focuses strictly on CWT data construction and reproducible preprocessing. Model training is not included in this scope but can be extended based on the output of this pipeline.

---

## 1. Project Structure

```text
CWT-based BP estimation/
│
├── data/                     # Raw Data (Read-only)
│   └── dataset_MIMICII.mat (as data is too big, plz download through google drive link: https://drive.google.com/file/d/18A8FjLt1Rdqz5PqMomooJ_-frzGzl2yB/view?usp=drive_link)
│
├── demos/                    # Visualization/Check scripts (Not for training)
│   └── signal_demo.m
│
├── preprocessing/            # Core Preprocessing Functions (Paper-Consistent)
│   ├── cwt_morlet_complex_conv.m
│   ├── reflect_pad_1d.m
│   ├── segment_ppg_windows.m
│   ├── ppg_to_cwt_tensor_batch.m
│   └── cwt_to_tensor_real_imag.m
│
├── scripts/                  # Executable Pipelines (Single/Batch)
│   ├── run_CWT_PPG_PaperConsistent.m
│   └── run_CWT_PPG_PaperConsistent_Batch.m
│
├── outputs/                  # Runtime outputs (Temporary)
│
└── CWT_Dataset/              # Generated Training Input Data (Batch Script Output)

## 2. Data Format (dataset_MIMICII.mat)

`data/dataset_MIMICII.mat` contains:

- `p`: a `1×N` cell array (e.g., `N=1000`)
- each `p{i}` is a `3×T double` matrix (three waveform channels)

This repo assumes the channel order (used by the demo scripts):

- `X(1,:)` → **PPG**
- `X(2,:)` → **ABP**
- `X(3,:)` → **ECG**

> The CWT pipeline only uses **PPG** (channel 1). ABP/ECG are for reference or later extensions.

---

## 3. Requirements

- MATLAB (recommended R2020a or newer; uses basic functions like `imresize`)
- Optional: Signal Processing Toolbox if you use `findpeaks`

---

## 4. Quick Start

### 4.1 Three-channel waveform demo

Purpose: verify data loading, channel order, and waveform shapes.

```matlab
cd demos
signal_demo
```

The script:
- loads `../data/dataset_MIMICII.mat`
- uses `idx=1` by default
- uses a fixed `fs=125 Hz` time axis
- plots **PPG / ABP / ECG** as three subplots

---

### 4.2 Single-sample CWT generation (paper-consistent)

Purpose: reproduce/inspect the CWT shape on one sample and debug parameters.

```matlab
cd scripts
run_CWT_PPG_PaperConsistent
```

---

### 4.3 Batch CWT dataset generation (recommended)

Purpose: generate CWT tensors for the full dataset.

```matlab
cd scripts
run_CWT_PPG_PaperConsistent_Batch
```

Default output folder:

```
CWT_Dataset/sample_0001/
CWT_Dataset/sample_0002/
...
```

Suggested per-sample files:
- `X_cwt.mat`: `X_cwt` with shape **256×256×2×num_windows** (single)
- `meta.mat`: configuration such as `fs`, `win_sec`, `stride_sec`, frequency band, etc.
- (optional) `ppg_peaks.mat`: peak detection results if enabled

---

## 5. Method Summary (Paper-consistent Semantics)

Key design choices:

1) **Sliding-window segmentation**
- window length: `win_sec = 5 s`
- stride: `stride_sec = 1 s` (overlap exists)

2) **Reflect padding**
- `pad_sec = 1 s` (example)
- reduces boundary artifacts

3) **Complex Morlet CWT**
- generates a complex matrix `W`
- split into `Real(W)` and `Imag(W)` as two channels

4) **Fixed output size**
- `out_hw = [256, 256]`
- resize real/imag maps to a standard tensor size

> Overlap note: If `stride_sec < win_sec`, adjacent windows overlap by `win_sec - stride_sec`.

---

## 6. Preprocessing Call Chain

Typical call chain in the batch pipeline:

```
run_CWT_PPG_PaperConsistent_Batch
    ↓
ppg_to_cwt_tensor_batch
    ↓
segment_ppg_windows
    ↓
reflect_pad_1d
    ↓
cwt_morlet_complex_conv
    ↓
cwt_to_tensor_real_imag
```

Function responsibilities:
- `segment_ppg_windows.m`: windowing by `win_sec` and `stride_sec`
- `reflect_pad_1d.m`: reflective padding for each window
- `cwt_morlet_complex_conv.m`: Complex Morlet CWT core
- `cwt_to_tensor_real_imag.m`: real/imag split + resize (and optional normalization)
- `ppg_to_cwt_tensor_batch.m`: orchestrator that outputs the final tensor

---

## 7. Can the output be used directly for deep learning?

Yes.

`X_cwt.mat` is already a fixed-size time–frequency tensor (two channels for real/imag). You can load it in MATLAB or Python:

- MATLAB: `load('X_cwt.mat')`
- Python: `scipy.io.loadmat` or `h5py` (if saved with `-v7.3`)

Typical tensor layouts:
- `(num_windows, 2, 256, 256)` or `(2, 256, 256)` (single window)

> Labels (SBP/DBP) should be constructed separately (e.g., from ABP), depending on your training setup.

---

## 8. FAQ

### Q1: “Cannot find dataset_MIMICII.mat”

Make sure the folder layout is:
- `demos/` and `data/` are siblings
- the file exists at `data/dataset_MIMICII.mat`

The demo typically uses:

```matlab
dataFile = fullfile('..','data','dataset_MIMICII.mat');
```

### Q2: Why does my CWT visualization not match the paper’s color tone exactly?

Common reasons:
- different colormap / rendering settings
- different normalization or log-compression
- different frequency-axis scaling (linear vs log)

This repo prioritizes **numerical and tensor-construction consistency**. Visualization styling can be aligned later by fixing the display parameters.

---

## 9. Citation

If you use this preprocessing implementation, please cite the associated paper:

- *A U-net and Transformer Paralleled Network for Robust Cuffless Blood Pressure Estimation* (IEEE SMC 2025 Oral, no index available yet, please star this project to stay updated)

---

## 10. License

Choose a license (e.g., MIT or Apache-2.0).
If the MIMIC-II derived data cannot be redistributed, clearly document the data access and usage restrictions.

---

# CWT-based BP Estimation（PPG → CWT 预处理开源）

本仓库开源并复现论文中的 **PPG 连续小波变换（CWT, Complex Morlet）预处理管线**，用于无袖带血压估计任务的时频表示构建。核心目标是：将原始 **PPG 波形**切分为固定窗口，并生成**论文一致**的 **256×256×2（Real + Imag）** CWT 张量，作为深度学习模型输入。

> 说明：本仓库聚焦 **CWT 数据构建与可复现的预处理实现**。模型训练部分不在本仓库范围内（可在后续扩展）。

---

## 1. 项目结构

```
CWT-based BP estimation/
│
├── data/                     # 原始数据（只读）
│   └── dataset_MIMICII.mat   （数据过大，请使用谷歌云盘下载：https://drive.google.com/file/d/18A8FjLt1Rdqz5PqMomooJ_-frzGzl2yB/view?usp=drive_link）
│
├── demos/                    # 展示/检查脚本（不参与训练）
│   └── signal_demo.m
│
├── preprocessing/            # 预处理核心函数（论文一致）
│   ├── cwt_morlet_complex_conv.m
│   ├── reflect_pad_1d.m
│   ├── segment_ppg_windows.m
│   ├── ppg_to_cwt_tensor_batch.m
│   └── cwt_to_tensor_real_imag.m
│
├── scripts/                  # 可执行 pipeline（单次/批量）
│   ├── run_CWT_PPG_PaperConsistent.m
│   └── run_CWT_PPG_PaperConsistent_Batch.m
│
├── outputs/                  # 运行时输出（临时，可删）
│
└── CWT_Dataset/              # 生成的训练输入数据（批量脚本输出）
```

---

## 2. 数据格式说明（dataset_MIMICII.mat）

`data/dataset_MIMICII.mat` 中包含变量：

- `p`：`1×N` cell（例如 N=1000）
- 每个 `p{i}` 为 `3×T double`（三通道波形）

本仓库默认通道顺序为（已在 demo 中使用）：

- `X(1,:)` → **PPG**
- `X(2,:)` → **ABP**
- `X(3,:)` → **ECG**

> pipeline 仅使用 **PPG（第 1 行）** 构建 CWT；ABP/ECG 用于参考或后续扩展。

---

## 3. 环境依赖

- MATLAB（建议 R2020a 及以上；需要 `imresize` 等基础函数）
- 若使用 `findpeaks`（可选）：Signal Processing Toolbox

---

## 4. 快速开始

### 4.1 波形展示 Demo（三通道）

用途：快速确认数据可读、通道顺序正确、波形形态正常。

```matlab
cd demos
signal_demo
```

脚本将：
- 从 `../data/dataset_MIMICII.mat` 读取 `p`
- 默认取 `idx=1` 的样本
- 固定 `fs=125 Hz` 构建时间轴
- 绘制三通道：**PPG / ABP / ECG**

---

### 4.2 单样本 CWT 生成（Paper-consistent）

用途：调参、对照论文图像形态，验证 Real/Imag 两通道输出。

```matlab
cd scripts
run_CWT_PPG_PaperConsistent
```

---

### 4.3 批量生成 CWT Dataset（推荐）

用途：对全数据集生成训练输入张量。

```matlab
cd scripts
run_CWT_PPG_PaperConsistent_Batch
```

默认输出目录：

```
CWT_Dataset/sample_0001/
CWT_Dataset/sample_0002/
...
```

建议每个 sample 文件夹包含：
- `X_cwt.mat`：`X_cwt`（**256×256×2×num_windows**，single）
- `meta.mat`：采样率、窗口长度、stride、频带等配置
- （可选）`ppg_peaks.mat`：峰值信息（若启用）

---

## 5. 预处理方法与参数（与论文一致的核心语义）

关键设计：

1) **滑动窗口切分**
- window length：`win_sec = 5 s`
- stride：`stride_sec = 1 s`（存在重叠）

2) **边界反射 padding**
- `pad_sec = 1 s`（示例）
- 减弱边界伪影

3) **Complex Morlet CWT**
- 输出复矩阵 `W`
- 拆分为 `Real(W)` 与 `Imag(W)` 两通道

4) **统一到图像尺寸**
- `out_hw = [256, 256]`
- resize 到固定大小并拼成张量

> 重叠说明：只要 `stride_sec < win_sec`，窗口就会重叠，重叠长度为 `win_sec - stride_sec`。

---

## 6. preprocessing/ 目录函数职责（调用链）

批量脚本典型调用链：

```
run_CWT_PPG_PaperConsistent_Batch
    ↓
ppg_to_cwt_tensor_batch
    ↓
segment_ppg_windows
    ↓
reflect_pad_1d
    ↓
cwt_morlet_complex_conv
    ↓
cwt_to_tensor_real_imag
```

文件职责概览：
- `segment_ppg_windows.m`：按 window/stride 切分 PPG
- `reflect_pad_1d.m`：每个窗口反射 padding
- `cwt_morlet_complex_conv.m`：Complex Morlet CWT（核心）
- `cwt_to_tensor_real_imag.m`：拆 Real/Imag + resize（可含归一化）
- `ppg_to_cwt_tensor_batch.m`：整合流程并输出张量（核心 orchestrator）

---

## 7. 输出数据能不能直接用于深度学习训练？

可以。

`X_cwt.mat` 已经是固定尺寸的二维时频表示张量（Real/Imag 两通道）。可在 MATLAB / Python 中直接加载：

- MATLAB：`load('X_cwt.mat')`
- Python：`scipy.io.loadmat` 或 `h5py`（若 `-v7.3`）

常见张量布局：
- `(num_windows, 2, 256, 256)` 或 `(2, 256, 256)`（单窗）

> 标签（SBP/DBP）需要你根据训练设置另行构建（例如从 ABP 提取）。

---

## 8. 常见问题（FAQ）

### Q1：运行时报“找不到 dataset_MIMICII.mat”

请确认目录结构：`demos/` 与 `data/` 同级，且 `data/dataset_MIMICII.mat` 存在。

脚本通常使用：

```matlab
dataFile = fullfile('..','data','dataset_MIMICII.mat');
```

### Q2：为什么 CWT 的颜色/色调和论文图不完全一致？

常见原因包括：
- colormap / 渲染设置不同
- 归一化/对数压缩/裁剪策略不同
- 频率轴缩放不同（linear vs log）

本仓库优先保证 **数值与张量构造一致**；可视化色调可在后续通过固定显示参数对齐论文图。

---

## 9. 引用（Citation）

如果你使用了本仓库的预处理实现，请引用对应论文：

- *A U-net and Transformer Paralleled Network for Robust Cuffless Blood Pressure Estimation*（IEEE SMC 2025，暂未上限，等待后续补充地址，请先收藏这个github项目，等待1月末上线）

---

## 10. License

建议选择 MIT / Apache-2.0 等开源协议。
若 MIMIC-II 派生数据不便公开，请明确数据获取方式与使用限制。



