"""
Build script for Generation Two
Creates executables for Windows (exe), Linux (deb), and macOS (dmg)
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path

# Get the script's directory (generation_two/)
SCRIPT_DIR = Path(__file__).parent.absolute()
PROJECT_ROOT = SCRIPT_DIR.parent.absolute()

def run_command(cmd, check=True, cwd=None):
    """Run a shell command"""
    print(f"Running: {' '.join(cmd)}")
    if cwd:
        print(f"  Working directory: {cwd}")
    result = subprocess.run(cmd, check=check, cwd=cwd)
    return result.returncode == 0

def build_windows_exe():
    """Build Windows executable using PyInstaller"""
    print("\n" + "="*60)
    print("Building Windows EXE...")
    print("="*60)
    
    # Install PyInstaller if not available
    try:
        import PyInstaller
    except ImportError:
        print("Installing PyInstaller...")
        run_command([sys.executable, "-m", "pip", "install", "pyinstaller"])
    
    # Verify files exist
    gui_script = SCRIPT_DIR / "gui" / "run_gui.py"
    constants_file = SCRIPT_DIR / "constants" / "operatorRAW.json"
    
    if not gui_script.exists():
        raise FileNotFoundError(f"GUI script not found: {gui_script}")
    if not constants_file.exists():
        raise FileNotFoundError(f"Constants file not found: {constants_file}")
    
    # Use absolute paths and ensure they're properly formatted
    # Convert to string and normalize (use forward slashes for PyInstaller compatibility)
    gui_script_abs = gui_script.resolve()
    constants_file_abs = constants_file.resolve()
    project_root_abs = PROJECT_ROOT.resolve()
    
    gui_script_str = str(gui_script_abs).replace('\\', '/')
    constants_file_str = str(constants_file_abs).replace('\\', '/')
    project_root_str = str(project_root_abs).replace('\\', '/')
    
    print(f"  GUI script: {gui_script_abs}")
    print(f"  Constants: {constants_file_abs}")
    print(f"  Project root: {project_root_abs}")
    
    # Create spec file in project root
    spec_content = f"""# -*- mode: python ; coding: utf-8 -*-

block_cipher = None

a = Analysis(
    [r'{gui_script_str}'],
    pathex=[r'{project_root_str}'],
    binaries=[],
    datas=[
        (r'{constants_file_str}', 'constants'),
    ],
    hiddenimports=[
        'tkinter',
        'tkinter.ttk',
        'generation_two',
        'generation_two.gui',
        'generation_two.core',
        'generation_two.ollama',
        'generation_two.data_fetcher',
        'generation_two.storage',
    ],
    hookspath=[],
    hooksconfig={{}},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='generation-two',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,  # No console window for GUI app
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=None,  # Add icon path if you have one
)
"""
    
    spec_file = PROJECT_ROOT / "generation_two.spec"
    spec_file.write_text(spec_content)
    
    # Build from project root
    dist_dir = SCRIPT_DIR / "dist"
    dist_dir.mkdir(exist_ok=True, parents=True)
    
    run_command(
        [sys.executable, "-m", "PyInstaller", "--clean", str(spec_file)],
        cwd=PROJECT_ROOT
    )
    
    # Move exe to dist
    exe_path = PROJECT_ROOT / "dist" / "generation-two.exe"
    target_path = SCRIPT_DIR / "dist" / "generation-two.exe"
    if exe_path.exists():
        target_path.parent.mkdir(exist_ok=True, parents=True)
        shutil.move(str(exe_path), str(target_path))
        print(f"✅ Windows EXE built: {target_path}")
    else:
        print(f"❌ EXE not found in expected location: {exe_path}")

def build_linux_deb():
    """Build Debian package"""
    print("\n" + "="*60)
    print("Building Linux DEB package...")
    print("="*60)
    
    # Install build dependencies
    print("Installing build dependencies...")
    run_command([sys.executable, "-m", "pip", "install", "stdeb"], check=False)
    
    # Build source distribution
    # setup.py is in generation_two/ but needs to be run from project root
    print("Building source distribution...")
    setup_py = SCRIPT_DIR / "setup.py"
    if not setup_py.exists():
        raise FileNotFoundError(f"setup.py not found: {setup_py}")
    
    # Run setup.py from project root so it can find the generation_two package
    run_command([sys.executable, str(setup_py), "sdist"], cwd=PROJECT_ROOT)
    
    # Convert to deb
    print("Converting to DEB...")
    # Source dist is created in PROJECT_ROOT/dist when run from project root
    dist_dir = PROJECT_ROOT / "dist"
    tar_files = list(dist_dir.glob("generation-two-*.tar.gz"))
    if not tar_files:
        print(f"❌ Source distribution not found in {dist_dir}")
        print(f"   Files in dist: {list(dist_dir.glob('*')) if dist_dir.exists() else 'dist/ does not exist'}")
        return
    
    tar_file = tar_files[0]
    print(f"✓ Found source distribution: {tar_file}")
    run_command([sys.executable, "-m", "stdeb", str(tar_file.name)], cwd=dist_dir)
    
    # Find and move deb file
    deb_files = list(PROJECT_ROOT.rglob("*.deb"))
    if deb_files:
        deb_file = deb_files[0]
        target_path = SCRIPT_DIR / "dist" / deb_file.name
        target_path.parent.mkdir(exist_ok=True, parents=True)
        shutil.move(str(deb_file), str(target_path))
        print(f"✅ Linux DEB built: {target_path}")
    else:
        print("❌ DEB file not found")

def build_macos_dmg():
    """Build macOS DMG package"""
    print("\n" + "="*60)
    print("Building macOS DMG...")
    print("="*60)
    
    if sys.platform != "darwin":
        print("⚠️  DMG can only be built on macOS")
        return
    
    # Install PyInstaller if not available
    try:
        import PyInstaller
    except ImportError:
        print("Installing PyInstaller...")
        run_command([sys.executable, "-m", "pip", "install", "pyinstaller"])
    
    # Verify files exist
    gui_script = SCRIPT_DIR / "gui" / "run_gui.py"
    constants_file = SCRIPT_DIR / "constants" / "operatorRAW.json"
    
    if not gui_script.exists():
        raise FileNotFoundError(f"GUI script not found: {gui_script}")
    if not constants_file.exists():
        print(f"❌ Constants file not found: {constants_file}")
        print(f"   Looking in: {SCRIPT_DIR}")
        if SCRIPT_DIR.exists():
            print(f"   Available files in constants/: {list((SCRIPT_DIR / 'constants').glob('*')) if (SCRIPT_DIR / 'constants').exists() else 'constants/ does not exist'}")
        raise FileNotFoundError(f"Constants file not found: {constants_file}")
    
    print(f"✓ Found constants file: {constants_file}")
    
    # Use absolute paths and ensure they're properly formatted
    gui_script_abs = gui_script.resolve()
    constants_file_abs = constants_file.resolve()
    project_root_abs = PROJECT_ROOT.resolve()
    
    gui_script_str = str(gui_script_abs).replace('\\', '/')
    constants_file_str = str(constants_file_abs).replace('\\', '/')
    project_root_str = str(project_root_abs).replace('\\', '/')
    
    print(f"  GUI script: {gui_script_abs}")
    print(f"  Constants: {constants_file_abs}")
    print(f"  Project root: {project_root_abs}")
    
    # Create spec file for macOS (similar to Windows approach)
    spec_content = f"""# -*- mode: python ; coding: utf-8 -*-

block_cipher = None

a = Analysis(
    [r'{gui_script_str}'],
    pathex=[r'{project_root_str}'],
    binaries=[],
    datas=[
        (r'{constants_file_str}', 'constants'),
    ],
    hiddenimports=[
        'tkinter',
        'tkinter.ttk',
        'generation_two',
        'generation_two.gui',
        'generation_two.core',
        'generation_two.ollama',
        'generation_two.data_fetcher',
        'generation_two.storage',
    ],
    hookspath=[],
    hooksconfig={{}},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

app = BUNDLE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='GenerationTwo',
    icon=None,
    bundle_identifier='com.worldquant.generationtwo',
)
"""
    
    spec_file = PROJECT_ROOT / "generation_two_macos.spec"
    spec_file.write_text(spec_content)
    print(f"✓ Created spec file: {spec_file}")
    
    # Build app bundle using spec file
    print(f"✓ Building with spec file: {spec_file}")
    run_command(
        [sys.executable, "-m", "PyInstaller", "--clean", "--windowed", str(spec_file)],
        cwd=PROJECT_ROOT
    )
    
    # Create DMG using create-dmg (requires: brew install create-dmg)
    print("Creating DMG...")
    app_path = PROJECT_ROOT / "dist" / "GenerationTwo.app"
    dmg_path = SCRIPT_DIR / "dist" / "generation-two.dmg"
    
    if not app_path.exists():
        print(f"❌ App bundle not found: {app_path}")
        print(f"   Checking dist directory: {PROJECT_ROOT / 'dist'}")
        if (PROJECT_ROOT / "dist").exists():
            print(f"   Files in dist: {list((PROJECT_ROOT / 'dist').iterdir())}")
        raise FileNotFoundError(f"App bundle not found: {app_path}")
    
    print(f"✓ Found app bundle: {app_path}")
    dmg_path.parent.mkdir(exist_ok=True, parents=True)
    
    # Try to create DMG
    dmg_result = run_command([
        "create-dmg",
        "--volname", "Generation Two",
        "--window-pos", "200", "120",
        "--window-size", "800", "400",
        "--icon-size", "100",
        "--app-drop-link", "600", "185",
        str(dmg_path),
        str(app_path)
    ], check=False)
    
    if dmg_result and dmg_path.exists():
        print(f"✅ macOS DMG built: {dmg_path}")
    else:
        print(f"⚠️  DMG creation may have failed, but app bundle is available at: {app_path}")
        print("   You can manually create a DMG or distribute the .app bundle directly")

def main():
    """Main build function"""
    print("Generation Two Build Script")
    print("="*60)
    print(f"Script directory: {SCRIPT_DIR}")
    print(f"Project root: {PROJECT_ROOT}")
    
    # Clean previous builds
    for clean_dir in [SCRIPT_DIR / "dist", PROJECT_ROOT / "dist", 
                      SCRIPT_DIR / "build", PROJECT_ROOT / "build"]:
        if clean_dir.exists():
            print(f"Cleaning: {clean_dir}")
            shutil.rmtree(clean_dir)
    
    # Create dist directory
    (SCRIPT_DIR / "dist").mkdir(exist_ok=True, parents=True)
    
    # Detect platform and build accordingly
    platform = sys.platform.lower()
    
    if platform.startswith("win"):
        build_windows_exe()
    elif platform.startswith("linux"):
        build_linux_deb()
    elif platform == "darwin":
        build_macos_dmg()
    else:
        print(f"⚠️  Unknown platform: {platform}")
        print("Available build options:")
        print("  - Windows: python build.py --exe")
        print("  - Linux: python build.py --deb")
        print("  - macOS: python build.py --dmg")
    
    # Handle command line arguments
    if len(sys.argv) > 1:
        if "--exe" in sys.argv:
            build_windows_exe()
        if "--deb" in sys.argv:
            build_linux_deb()
        if "--dmg" in sys.argv:
            build_macos_dmg()
        if "--all" in sys.argv:
            build_windows_exe()
            build_linux_deb()
            if sys.platform == "darwin":
                build_macos_dmg()
    
    print("\n" + "="*60)
    print("Build complete!")
    print("="*60)

if __name__ == "__main__":
    main()
