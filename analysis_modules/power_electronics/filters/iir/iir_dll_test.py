"""
*************************** In The Name Of God ***************************
@file    iir_dll_test.py
@brief   IIR filter DLL testing with step response and Bode plots
@author  Analysis Team
@date    2025-06-26
Tests IIR filter DLL with visual plots and comprehensive analysis.
@license This work is dedicated to the public domain under CC0 1.0.
**************************************************************************
"""

import ctypes
import numpy as np
import os
import sys

try:
    import matplotlib.pyplot as plt
    MATPLOTLIB_AVAILABLE = True
except ImportError:
    MATPLOTLIB_AVAILABLE = False
    print("Warning: matplotlib not available - no plots will be generated")


class IIRFilterDLL:
    """Simple interface to IIR filter DLL."""
    
    def __init__(self, dll_path):
        """Initialize the IIR filter DLL interface."""
        self.dll = ctypes.CDLL(dll_path)
        self._setup_function_signatures()
        
    def _setup_function_signatures(self):
        """Setup ctypes function signatures."""
        
        # Define structures to match C++ structs
        class IIRParams(ctypes.Structure):
            _fields_ = [
                ("Ts", ctypes.c_float),     # Sample time
                ("fc", ctypes.c_float),     # Cutoff frequency  
                ("type", ctypes.c_int),     # Filter type (0=lowpass, 1=highpass)
                ("a", ctypes.c_float)       # Filter coefficient
            ]
        
        class IIRState(ctypes.Structure):
            _fields_ = [
                ("y_prev", ctypes.c_float), # Previous output
                ("u_prev", ctypes.c_float)  # Previous input
            ]
            
        class IIROutputs(ctypes.Structure):
            _fields_ = [
                ("y", ctypes.c_float)       # Current output
            ]
            
        class IIRModule(ctypes.Structure):
            _fields_ = [
                ("params", IIRParams),
                ("state", IIRState),
                ("outputs", IIROutputs)
            ]
        
        # Store structure classes
        self.IIRParams = IIRParams
        self.IIRState = IIRState  
        self.IIROutputs = IIROutputs
        self.IIRModule = IIRModule
        
        # Setup function signatures
        self.dll.iir_init.argtypes = [
            ctypes.POINTER(IIRModule),
            ctypes.POINTER(IIRParams)
        ]
        self.dll.iir_init.restype = None
        
        self.dll.iir_step.argtypes = [
            ctypes.POINTER(IIRModule),
            ctypes.c_float  # input
        ]
        self.dll.iir_step.restype = None
    
    def create_filter(self, fc, Ts, filter_type='lowpass'):
        """Create and initialize a filter."""
        module = self.IIRModule()
        
        # Setup parameters
        params = self.IIRParams()
        params.Ts = ctypes.c_float(Ts)
        params.fc = ctypes.c_float(fc)
        params.type = ctypes.c_int(0 if filter_type.lower() == 'lowpass' else 1)
        params.a = ctypes.c_float(0.0)  # Will be calculated by init
        
        # Initialize the filter
        self.dll.iir_init(ctypes.byref(module), ctypes.byref(params))
        
        return module
    
    def process_sample(self, module, input_sample):
        """Process a single sample."""
        self.dll.iir_step(ctypes.byref(module), ctypes.c_float(input_sample))
        return float(module.outputs.y)
    
    def reset_filter(self, module):
        """Reset filter state."""
        module.state.y_prev = 0.0
        module.state.u_prev = 0.0


def test_step_response(dll, fc=1000, Ts=1e-4, filter_type='lowpass', duration=0.01):
    """Test step response of IIR filter."""
    print(f"\n{'='*60}")
    print(f"STEP RESPONSE TEST - {filter_type.upper()} FILTER")
    print(f"{'='*60}")
    print(f"Cutoff frequency: {fc} Hz")
    print(f"Sample time: {Ts} s")
    print(f"Test duration: {duration} s")
    
    # Create filter
    filter_module = dll.create_filter(fc, Ts, filter_type)
    
    # Create time vector and step input
    t = np.arange(0, duration, Ts)
    step_input = np.ones(len(t))
    step_output = np.zeros(len(t))
    
    # Process step input
    for i, u in enumerate(step_input):
        step_output[i] = dll.process_sample(filter_module, u)
    
    # Print some key values
    steady_state = step_output[-1]
    rise_time_idx = np.where(step_output >= 0.63 * steady_state)[0]
    rise_time = t[rise_time_idx[0]] if len(rise_time_idx) > 0 else 0
    
    print(f"Steady-state value: {steady_state:.4f}")
    print(f"Rise time (63%): {rise_time*1000:.2f} ms")
    print(f"Filter coefficient 'a': {filter_module.params.a:.6f}")
    
    # Plot if matplotlib is available
    if MATPLOTLIB_AVAILABLE:
        plt.figure(figsize=(10, 6))
        plt.plot(t * 1000, step_input, 'r--', linewidth=2, label='Step Input')
        plt.plot(t * 1000, step_output, 'b-', linewidth=2, label='Filter Output')
        plt.axhline(y=0.63*steady_state, color='k', linestyle=':', alpha=0.7, label='63% Level')
        plt.xlabel('Time (ms)')
        plt.ylabel('Amplitude')
        plt.title(f'{filter_type.title()} Filter Step Response (fc={fc} Hz)')
        plt.legend()
        plt.grid(True, alpha=0.3)
        
        # Save plot
        plot_filename = f"step_response_{filter_type}_{fc}Hz.png"
        plt.savefig(plot_filename, dpi=150, bbox_inches='tight')
        print(f"Plot saved as: {plot_filename}")
        plt.show()
    
    return t, step_input, step_output


def test_frequency_response(dll, fc=1000, Ts=1e-4, filter_type='lowpass'):
    """Test frequency response (Bode plot) of IIR filter."""
    print(f"\n{'='*60}")
    print(f"FREQUENCY RESPONSE TEST - {filter_type.upper()} FILTER")
    print(f"{'='*60}")
    
    # Create filter
    filter_module = dll.create_filter(fc, Ts, filter_type)
    
    # Frequency range for testing
    frequencies = np.logspace(1, 4, 50)  # 10 Hz to 10 kHz
    magnitude_db = []
    phase_deg = []
    
    print("Testing frequencies...")
    
    for i, freq in enumerate(frequencies):
        if freq > 1/(2*Ts):  # Skip frequencies above Nyquist
            continue
            
        print(f"  {freq:.1f} Hz ({i+1}/{len(frequencies)})", end='\r')
        
        # Generate test signal (multiple periods for steady state)
        n_periods = 10
        test_duration = n_periods / freq
        t = np.arange(0, test_duration, Ts)
        
        if len(t) < 20:  # Skip if too few samples
            continue
            
        # Create sine wave input
        sine_input = np.sin(2 * np.pi * freq * t)
        
        # Reset filter and process
        dll.reset_filter(filter_module)
        sine_output = np.zeros(len(t))
        
        for j, u in enumerate(sine_input):
            sine_output[j] = dll.process_sample(filter_module, u)
        
        # Analyze steady-state response (last half of signal)
        steady_start = len(sine_output) // 2
        input_steady = sine_input[steady_start:]
        output_steady = sine_output[steady_start:]
        
        # Calculate magnitude
        input_rms = np.sqrt(np.mean(input_steady**2))
        output_rms = np.sqrt(np.mean(output_steady**2))
        
        if input_rms > 1e-10:
            magnitude = output_rms / input_rms
            magnitude_db.append(20 * np.log10(magnitude))
        else:
            magnitude_db.append(-100)  # Very small value
        
        # Calculate phase using cross-correlation
        correlation = np.correlate(output_steady, input_steady, mode='full')
        delay_samples = np.argmax(correlation) - len(input_steady) + 1
        phase_rad = -2 * np.pi * freq * delay_samples * Ts
        phase_deg.append(np.degrees(phase_rad))
    
    print(f"\nTested {len(magnitude_db)} frequencies")
    
    # Trim frequency array to match results
    frequencies = frequencies[:len(magnitude_db)]
    
    # Print key results
    fc_idx = np.argmin(np.abs(frequencies - fc))
    if fc_idx < len(magnitude_db):
        print(f"Magnitude at fc ({fc} Hz): {magnitude_db[fc_idx]:.2f} dB")
        print(f"Phase at fc: {phase_deg[fc_idx]:.1f}°")
    
    # Plot Bode diagram if matplotlib is available
    if MATPLOTLIB_AVAILABLE:
        plt.figure(figsize=(12, 8))
        
        # Magnitude plot
        plt.subplot(2, 1, 1)
        plt.semilogx(frequencies, magnitude_db, 'b-', linewidth=2)
        plt.axvline(fc, color='r', linestyle='--', alpha=0.7, label=f'fc = {fc} Hz')
        plt.axhline(-3, color='k', linestyle=':', alpha=0.7, label='-3 dB')
        plt.xlabel('Frequency (Hz)')
        plt.ylabel('Magnitude (dB)')
        plt.title(f'{filter_type.title()} Filter Bode Plot (fc={fc} Hz)')
        plt.legend()
        plt.grid(True, alpha=0.3)
        
        # Phase plot
        plt.subplot(2, 1, 2)
        plt.semilogx(frequencies, phase_deg, 'b-', linewidth=2)
        plt.axvline(fc, color='r', linestyle='--', alpha=0.7, label=f'fc = {fc} Hz')
        plt.xlabel('Frequency (Hz)')
        plt.ylabel('Phase (degrees)')
        plt.legend()
        plt.grid(True, alpha=0.3)
        
        plt.tight_layout()
        
        # Save plot
        plot_filename = f"bode_plot_{filter_type}_{fc}Hz.png"
        plt.savefig(plot_filename, dpi=150, bbox_inches='tight')
        print(f"Bode plot saved as: {plot_filename}")
        plt.show()
    
    return frequencies, magnitude_db, phase_deg


def main():
    """Main testing function."""
    print("*************************** In The Name Of God ***************************")
    print("IIR FILTER DLL TESTING WITH PLOTS")
    print("*"*72)
    
    # Find IIR DLL
    current_dir = os.path.dirname(__file__)
    project_root = os.path.abspath(os.path.join(current_dir, '..', '..', '..', '..'))
    iir_dll_path = os.path.join(project_root, 'build', 'iir.dll')
    
    if not os.path.exists(iir_dll_path):
        print(f"❌ IIR DLL not found at: {iir_dll_path}")
        print("Please build the project first!")
        input("Press Enter to exit...")
        return
    
    try:
        # Initialize DLL interface
        dll = IIRFilterDLL(iir_dll_path)
        print(f"✅ Successfully loaded IIR DLL: {iir_dll_path}")
        
        # Test configurations
        test_configs = [
            {'fc': 1000, 'Ts': 1e-4, 'filter_type': 'lowpass'},
            {'fc': 1000, 'Ts': 1e-4, 'filter_type': 'highpass'},
        ]
        
        for config in test_configs:
            # Step response test
            test_step_response(dll, **config)
            
            # Frequency response test
            test_frequency_response(dll, **config)
        
        print(f"\n{'='*60}")
        print("ALL TESTS COMPLETED SUCCESSFULLY!")
        print(f"{'='*60}")
        if MATPLOTLIB_AVAILABLE:
            print("Check the generated PNG files for visual results.")
        else:
            print("Install matplotlib to see visual plots: pip install matplotlib")
        
    except Exception as e:
        print(f"❌ Error during testing: {e}")
        import traceback
        traceback.print_exc()
    
    input("\nPress Enter to exit...")


if __name__ == "__main__":
    main()
