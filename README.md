# Bio-Inspired Disturbance Sensing System
### Fish Lateral Line — Flow & Vibration Detection Prototype

Arduino UNO · MATLAB Signal Analysis · Simulink Modeling · Tinkercad Simulation

---

## What This Is

The fish lateral line is a mechanoreceptive organ that detects water flow, pressure changes, and vibrations — allowing fish to navigate, detect predators, and school together without relying on vision. It has evolved over 400 million years into one of the most efficient distributed sensing systems in nature.

This project translates that biological system into an Arduino-based electronic prototype. A potentiometer emulates the neuromast hair cells. Signal processing in MATLAB and Simulink replicates the adaptive thresholding, frequency analysis, and closed-loop sensing behavior of the fish's nervous system.

---

## Files

```
lateral_system.m              ← MATLAB signal analysis pipeline (10 sections)
line_lateral_system_simulink.slx  ← Simulink closed-loop sensing model
lateral_line_report.docx      ← Full project report with bio-inspiration mapping
```

The Arduino firmware is embedded in the report (Section 3). The Tinkercad circuit simulation is linked below.

---

## Hardware

| Component | Role |
|-----------|------|
| Arduino UNO R3 | Microcontroller, 10-bit ADC at 100 Hz |
| 10 kΩ Potentiometer | Flow/displacement sensor — emulates neuromast hair cell |
| Green LED | Calm state indicator |
| Red LED | Disturbance detected |
| Yellow LED | Intermediate warning |
| 16×2 LCD (HD44780) | Real-time ADC readout and status display |
| 220 Ω resistors | LED current limiting |

**Tinkercad Simulation:** [View Circuit](https://www.tinkercad.com)

---

## Bio-Inspiration Mapping

| Biological Component | Electronic Analogue | Implementation |
|----------------------|---------------------|----------------|
| Neuromast hair cell | Potentiometer wiper | Arduino analog pin A0 |
| Cupula deflection | Voltage change ΔV | ADC reading shift (0–1023) |
| Afferent nerve firing | Serial + LED output | Arduino digital outputs |
| Lateral inhibition | Moving average filter | MATLAB movmean() |
| Adaptive gain control | Baseline correction | Polynomial detrending |
| Frequency tuning | FFT + Gaussian filter bank | MATLAB Section 9 |
| Brain threshold | Adaptive threshold (μ + 2.5σ) | MATLAB Section 4 |
| Motor response | LED / LCD activation | Arduino digital outputs |

---

## MATLAB Analysis Pipeline

`lateral_system.m` runs a 10-section offline signal analysis pipeline on simulated potentiometer data. Each section maps directly to a biological function of the lateral line.

| Section | What it does | Biological equivalent |
|---------|--------------|-----------------------|
| 1 | Simulate 3 disturbance events with realistic waveforms | Hydrodynamic stimulus |
| 2 | Moving average filter + polynomial detrending + normalisation | Cupula mechanics + adaptation |
| 3 | FFT frequency analysis, dominant frequency detection | Frequency tuning of neuromasts |
| 4 | Adaptive threshold (μ + 2.5σ), event detection | Afferent nerve threshold crossing |
| 5 | Response time measurement per event | Neural latency |
| 6 | Repeatability analysis — Coefficient of Variation | Biological reliability |
| 7 | SNR calculation | Signal quality metric |
| 8 | Dual threshold detection (high + low, bidirectional) | Bidirectional hair cell sensitivity |
| 9 | Virtual 5-neuromast population model with Gaussian tuning curves | Distributed lateral line array |
| 10 | Summary performance report | System validation |

**How to run:**
```matlab
>> lateral_system
```
No inputs needed — the script simulates its own sensor data internally.

---

## Simulink Model

`line_lateral_system_simulink.slx` implements the complete lateral line sensing pathway as a closed-loop Simulink model.

Signal path:
1. Three sources combine — DC offset (ambient pressure), sine wave (periodic flow), random noise (turbulence)
2. Gain block K scales the input — represents hair cell sensitivity
3. Transfer function models cupula spring-mass-damper mechanics
4. Feedback subtraction implements adaptation to steady-state flow
5. Absolute value block replicates bidirectional hair cell rectification
6. Saturation models the neuron's refractory period

The gain K was tuned to achieve SNR > 3 dB on disturbance events and settling time < 500 ms — consistent with real lateral line response characteristics.

**How to run:**
```matlab
>> open('line_lateral_system_simulink.slx')
```
Then press Run in Simulink.

---

## Performance Results

| Metric | Result | Target |
|--------|--------|--------|
| Detection range | 5–15 cm | 5–15 cm |
| Response time | ~370 ms | ≤ 500 ms |
| Coefficient of Variation | < 15% | < 15% |
| SNR | > 12 dB | > 3 dB |
| Events detected (3 trials) | 3/3 | 3/3 |

---

## Assumptions and Limitations

- The potentiometer models neuromast deflection as a purely resistive (position) sensor — real hair cells have more complex electromechanical dynamics
- Steam property approximations are used in the signal model rather than full hydrodynamic simulation
- Tinkercad does not support noise injection, so all noise analysis is done in MATLAB offline
- The Simulink model uses a simplified transfer function for cupula mechanics — a full biomechanical model would require higher-order viscoelastic parameters

---

## References

- Coombs, S. & Montgomery, J.C. — *The enigmatic lateral line system*, Sensory Processing in Aquatic Environments, Springer
- Bleckmann, H. & Zelick, R. — *Lateral line system of fish*, Integrative Zoology, 2009
- Arduino Reference Documentation — [arduino.cc/reference](https://www.arduino.cc/reference)

---

**Gokula Priya R**
B.Tech Mechanical Engineering, NIT Calicut
