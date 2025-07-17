"""
*************************** In The Name Of God ***************************
@file    minimal_dll_test.py
@brief   Minimal DLL test - Essential functionality only
@author  Analysis Team
@date    2025-06-26
Tests DLL loading and basic functionality with minimal dependencies.
@license This work is dedicated to the public domain under CC0 1.0.
**************************************************************************
"""

import ctypes
import os
import sys


def main():
    """Minimal DLL test with only essential functionality."""
    print("*************************** In The Name Of God ***************************")
    print("MINIMAL DLL TEST")
    print("*"*72)
    
    # Check Python architecture
    architecture = '32-bit' if sys.maxsize <= 2**32 else '64-bit'
    print(f"Python Version: {sys.version}")
    print(f"Python Architecture: {architecture}")
    print()
    
    # Find DLL files
    current_dir = os.path.dirname(__file__)
    project_root = os.path.abspath(os.path.join(current_dir, '..', '..', '..'))
    build_dir = os.path.join(project_root, 'build')
    
    print(f"Build directory: {build_dir}")
    
    if not os.path.exists(build_dir):
        print("❌ Build directory not found!")
        return False
    
    dll_files = [f for f in os.listdir(build_dir) if f.endswith('.dll')]
    print(f"Found DLL files: {dll_files}")
    print()
    
    if not dll_files:
        print("❌ No DLL files found! Run the build task first.")
        return False
    
    # Test loading each DLL
    success_count = 0
    for dll_file in dll_files:
        dll_path = os.path.join(build_dir, dll_file)
        try:
            dll = ctypes.CDLL(dll_path)
            print(f"✅ Successfully loaded: {dll_file}")
            success_count += 1
            
            # Quick function check for IIR DLL
            if dll_file.startswith('iir'):
                try:
                    iir_init = dll.iir_init
                    iir_step = dll.iir_step
                    print(f"   Found functions: iir_init, iir_step")
                except AttributeError:
                    print(f"   Warning: Expected functions not found")
                    
        except OSError as e:
            if "not a valid Win32 application" in str(e):
                print(f"❌ Architecture mismatch for {dll_file}")
                print(f"   DLL is likely {'32-bit' if architecture == '64-bit' else '64-bit'}")
            else:
                print(f"❌ Failed to load {dll_file}: {e}")
        except Exception as e:
            print(f"❌ Failed to load {dll_file}: {e}")
    
    print(f"\nResult: Successfully loaded {success_count}/{len(dll_files)} DLL files")
    
    if success_count > 0:
        print("\n🎉 DLL COMPATIBILITY CONFIRMED!")
        print("Your Python architecture matches the compiled DLLs.")
        return True
    else:
        print("\n❌ ARCHITECTURE MISMATCH!")
        print("Please use a Python version that matches your DLL architecture.")
        return False


if __name__ == "__main__":
    success = main()
    input("\nPress Enter to exit...")
    sys.exit(0 if success else 1)
