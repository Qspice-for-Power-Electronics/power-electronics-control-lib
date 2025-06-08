# *************************** In The Name Of God ***************************
# * @file    project_config.py
# * @brief   Python script for project configuration parsing and management
# * @author  Dr.-Ing. Hossein Abedini
# * @date    2025-06-08
# * Utility for reading project_config.json and providing easy access to
# * project structure, build configuration, and file paths.
# * @note    Designed for real-time signal processing applications.
# * @license This work is dedicated to the public domain under CC0 1.0.
# *          Please use it for good and beneficial purposes!
# ***************************************************************************

#!/usr/bin/env python3
"""
================================================================================
Power Electronics Control Library - Project Configuration Parser
================================================================================

This utility reads the project_config.json file and provides easy access to
project structure, build configuration, and file paths for the power electronics
control library designed for QSPICE integration.

WHAT THIS SCRIPT DOES:
1. Parses project_config.json configuration file
2. Provides command-line access to project settings
3. Extracts include paths for compiler configuration
4. Lists source files and build dependencies
5. Outputs clang-tidy flags and build order information
6. Validates project structure and configuration

REQUIREMENTS:
- Python 3.6 or higher
- config/project_config.json file in project root
- Proper JSON structure with required configuration sections

OUTPUT FORMATS:
- Include paths: Space-separated list for compiler flags
- Source files: Newline-separated list of all .cpp files
- Build order: Space-separated list of module build sequence
- Clang flags: Formatted flags for static analysis tools

USAGE:
    python scripts/project_config.py --include-paths    # Get include paths
    python scripts/project_config.py --source-files     # Get all source files
    python scripts/project_config.py --build-order      # Get build order
    python scripts/project_config.py --clang-flags      # Get clang-tidy flags

================================================================================
"""

import json
import os
import sys
import argparse
from pathlib import Path

# ================================================================================
# STEP 1: Define Configuration Loading Functions
# ================================================================================

class ProjectConfig:
    def __init__(self, config_file="config/project_config.json"):
        """Initialize project configuration from JSON file."""
        self.config_file = config_file
        self.config = self._load_config()
        self.root_path = Path(self.config["paths"]["root"])
    
    def _load_config(self):
        """Load configuration from JSON file."""
        try:
            with open(self.config_file, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            print(f"Error: Configuration file '{self.config_file}' not found")
            sys.exit(1)
        except json.JSONDecodeError as e:
            print(f"Error: Invalid JSON in '{self.config_file}': {e}")
            sys.exit(1)
    
    def get_include_paths(self):
        """Get all include paths for compilation."""
        include_paths = []
        
        # Add configured include paths
        for path in self.config["build_config"]["include_paths"]:
            include_paths.append(str(self.root_path / path))
        
        # Add all module header directories
        for module_type in self.config["modules"]:
            for component_name, component in self.config["modules"][module_type]["components"].items():
                if component["headers"]:
                    include_paths.append(str(self.root_path / component["path"]))
        
        # Remove duplicates while preserving order
        return list(dict.fromkeys(include_paths))
    
    def get_source_files(self, module_type=None, component=None):
        """Get source files, optionally filtered by module type or component."""
        source_files = []
        
        for mod_type in self.config["modules"]:
            if module_type and mod_type != module_type:
                continue
                
            for comp_name, comp_config in self.config["modules"][mod_type]["components"].items():
                if component and comp_name != component:
                    continue
                
                for source_file in comp_config["sources"]:
                    full_path = self.root_path / comp_config["path"] / source_file
                    source_files.append(str(full_path))
        
        return source_files
    
    def get_header_files(self, module_type=None):
        """Get all header files."""
        header_files = []
        
        for mod_type in self.config["modules"]:
            if module_type and mod_type != module_type:
                continue
                
            for comp_name, comp_config in self.config["modules"][mod_type]["components"].items():
                for header_file in comp_config["headers"]:
                    full_path = self.root_path / comp_config["path"] / header_file
                    header_files.append(str(full_path))
        
        return header_files
    
    def get_all_source_and_header_files(self):
        """Get all C++ source and header files."""
        files = []
        files.extend(self.get_source_files())
        files.extend(self.get_header_files())
        return files
    
    def get_build_order(self):
        """Get the build order for modules."""
        return self.config["build_config"]["build_order"]
    
    def get_compiler_flags(self):
        """Get compiler flags."""
        flags = self.config["build_config"]["common_flags"].copy()
        
        # Add include paths as compiler flags
        for include_path in self.get_include_paths():
            flags.append(f'-I"{include_path}"')
        
        return flags
    
    def get_clang_tidy_flags(self):
        """Get clang-tidy configuration flags."""
        cpp_standard = self.config["project"]["cpp_standard"]
        include_paths = self.get_include_paths()
        
        flags = [f"-std={cpp_standard}"]
        for include_path in include_paths:
            flags.append(f'-I"{include_path}"')
        
        return flags
    
    def get_clang_checks(self, check_category=None):
        """Get clang-tidy checks, optionally filtered by category."""
        all_checks = []
        
        if check_category:
            if check_category in self.config["tools"]["clang_tidy"]["checks"]:
                return self.config["tools"]["clang_tidy"]["checks"][check_category]
            else:
                return []
        
        # Get all checks
        for category, checks in self.config["tools"]["clang_tidy"]["checks"].items():
            all_checks.extend(checks)
        
        return all_checks
    
    def get_qspice_modules(self):
        """Get QSPICE modules configuration."""
        qspice_modules = []
        
        if "qspice_modules" in self.config["modules"]:
            for comp_name, comp_config in self.config["modules"]["qspice_modules"]["components"].items():
                module_info = {
                    "name": comp_name,
                    "path": comp_config["path"],
                    "sources": comp_config["sources"],
                    "definition_file": comp_config.get("definition_file"),
                    "output_dll": comp_config.get("output_dll"),
                    "dependencies": comp_config.get("dependencies", [])
                }
                qspice_modules.append(module_info)
        
        return qspice_modules
    
    def get_dependencies(self, component_name):
        """Get dependencies for a specific component."""
        for module_type in self.config["modules"]:
            for comp_name, comp_config in self.config["modules"][module_type]["components"].items():
                if comp_name == component_name:
                    return comp_config.get("dependencies", [])
        return []
    
    def print_summary(self):
        """Print a summary of the project configuration."""
        print("=" * 80)
        print(f"PROJECT: {self.config['project']['name']}")
        print(f"VERSION: {self.config['project']['version']}")
        print(f"AUTHOR:  {self.config['project']['author']}")
        print("=" * 80)
        
        print("\nMODULES:")
        for module_type in self.config["modules"]:
            print(f"  {module_type}:")
            for comp_name, comp_config in self.config["modules"][module_type]["components"].items():
                print(f"    - {comp_name}: {len(comp_config['sources'])} sources, {len(comp_config['headers'])} headers")
        
        print(f"\nINCLUDE PATHS ({len(self.get_include_paths())}):")
        for path in self.get_include_paths():
            print(f"  - {path}")
        
        print(f"\nSOURCE FILES ({len(self.get_source_files())}):")
        for file in self.get_source_files():
            print(f"  - {file}")

def main():
    parser = argparse.ArgumentParser(description="Project Configuration Parser")
    parser.add_argument("--include-paths", action="store_true", help="Print include paths")
    parser.add_argument("--source-files", action="store_true", help="Print source files")
    parser.add_argument("--header-files", action="store_true", help="Print header files")
    parser.add_argument("--all-files", action="store_true", help="Print all source and header files")
    parser.add_argument("--build-order", action="store_true", help="Print build order")
    parser.add_argument("--compiler-flags", action="store_true", help="Print compiler flags")
    parser.add_argument("--clang-flags", action="store_true", help="Print clang-tidy flags")
    parser.add_argument("--clang-checks", action="store_true", help="Print clang-tidy checks")
    parser.add_argument("--qspice-modules", action="store_true", help="Print QSPICE modules")
    parser.add_argument("--summary", action="store_true", help="Print project summary")
    parser.add_argument("--module-type", help="Filter by module type (power_electronics, qspice_modules)")
    parser.add_argument("--component", help="Filter by component name")
    
    args = parser.parse_args()
    
    # If no arguments provided, show summary
    if not any(vars(args).values()):
        args.summary = True
    
    config = ProjectConfig()
    
    if args.summary:
        config.print_summary()
    
    if args.include_paths:
        for path in config.get_include_paths():
            print(path)
    
    if args.source_files:
        for file in config.get_source_files(args.module_type, args.component):
            print(file)
    
    if args.header_files:
        for file in config.get_header_files(args.module_type):
            print(file)
    
    if args.all_files:
        for file in config.get_all_source_and_header_files():
            print(file)
    
    if args.build_order:
        for module in config.get_build_order():
            print(module)
    
    if args.compiler_flags:
        for flag in config.get_compiler_flags():
            print(flag)
    
    if args.clang_flags:
        for flag in config.get_clang_tidy_flags():
            print(flag)
    
    if args.clang_checks:
        for check in config.get_clang_checks():
            print(check)
    
    if args.qspice_modules:
        for module in config.get_qspice_modules():
            print(f"{module['name']}: {module['output_dll']}")

if __name__ == "__main__":
    main()
