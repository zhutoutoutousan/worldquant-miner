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
    
    # Check if constants file exists, if not try root constants directory
    if not constants_file.exists():
        root_constants = PROJECT_ROOT / "constants" / "operatorRAW.json"
        if root_constants.exists():
            # Create constants directory and copy file
            constants_file.parent.mkdir(exist_ok=True, parents=True)
            shutil.copy2(root_constants, constants_file)
            print(f"✓ Copied constants file from root: {root_constants} -> {constants_file}")
        else:
            raise FileNotFoundError(f"Constants file not found in {constants_file} or {root_constants}")
    
    if not gui_script.exists():
        raise FileNotFoundError(f"GUI script not found: {gui_script}")
    
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
    # Try both patterns: generation_two (underscore) and generation-two (hyphen)
    tar_files = list(dist_dir.glob("generation_two-*.tar.gz")) + list(dist_dir.glob("generation-two-*.tar.gz"))
    if not tar_files:
        print(f"❌ Source distribution not found in {dist_dir}")
        print(f"   Files in dist: {list(dist_dir.glob('*')) if dist_dir.exists() else 'dist/ does not exist'}")
        return
    
    tar_file = tar_files[0]
    print(f"✓ Found source distribution: {tar_file}")
    # Use stdeb to convert tar.gz to deb
    # Try py2dsc-deb command first (installed by stdeb)
    py2dsc_deb_cmd = shutil.which("py2dsc-deb")
    if py2dsc_deb_cmd:
        run_command([py2dsc_deb_cmd, str(tar_file.name)], cwd=dist_dir)
    else:
        # Fallback: use Python module (stdeb.command.py2dsc_deb can be called as module)
        print("⚠️  py2dsc-deb not in PATH, trying Python module...")
        try:
            # Try using python -m stdeb.command.py2dsc_deb
            run_command(
                [sys.executable, "-m", "stdeb.command.py2dsc_deb", str(tar_file.name)],
                cwd=dist_dir
            )
        except Exception as e:
            print(f"⚠️  Module approach failed: {e}")
            print("   Trying direct API call...")
            # Last resort: use stdeb API directly
            import tarfile
            import tempfile
            from stdeb.command import py2dsc_deb
            
            with tempfile.TemporaryDirectory() as tmpdir:
                tmpdir_path = Path(tmpdir)
                # Extract source distribution
                with tarfile.open(tar_file, "r:gz") as tar:
                    tar.extractall(tmpdir_path)
                
                # Find the extracted package directory
                extracted_dirs = [d for d in tmpdir_path.iterdir() if d.is_dir() and (d / "setup.py").exists()]
                if not extracted_dirs:
                    raise FileNotFoundError("Could not find setup.py in extracted archive")
                
                package_dir = extracted_dirs[0]
                print(f"  Building DEB from: {package_dir}")
                
                # Use stdeb to build deb
                import os
                old_cwd = os.getcwd()
                try:
                    os.chdir(str(package_dir))
                    # py2dsc_deb.main() processes the current directory
                    py2dsc_deb.main([])
                finally:
                    os.chdir(old_cwd)
                
                # Find and move resulting deb files
                deb_dist = package_dir / "deb_dist"
                if deb_dist.exists():
                    for deb_file in deb_dist.rglob("*.deb"):
                        target_deb = dist_dir / deb_file.name
                        shutil.move(str(deb_file), str(target_deb))
                        print(f"  ✓ Moved DEB: {target_deb}")
                else:
                    raise FileNotFoundError(f"deb_dist not found in {package_dir}")
    
    # Find and move deb file
    # stdeb creates deb files in deb_dist/ subdirectory
    deb_dist_dir = dist_dir / "deb_dist"
    deb_files = []
    
    # First check deb_dist directory (where stdeb puts them)
    if deb_dist_dir.exists():
        deb_files = list(deb_dist_dir.rglob("*.deb"))
        print(f"Checking deb_dist directory: {deb_dist_dir}")
        if deb_files:
            print(f"Found {len(deb_files)} DEB file(s) in deb_dist")
    
    # If not found, search entire project
    if not deb_files:
        deb_files = list(PROJECT_ROOT.rglob("*.deb"))
        print(f"Searching entire project for .deb files...")
    
    if deb_files:
        deb_file = deb_files[0]
        target_path = SCRIPT_DIR / "dist" / deb_file.name
        target_path.parent.mkdir(exist_ok=True, parents=True)
        shutil.move(str(deb_file), str(target_path))
        print(f"✅ Linux DEB built: {target_path}")
    else:
        print("❌ DEB file not found")
        print(f"   Searched in: {deb_dist_dir}")
        print(f"   And recursively in: {PROJECT_ROOT}")
        if deb_dist_dir.exists():
            print(f"   Files in deb_dist: {list(deb_dist_dir.iterdir())}")
        if dist_dir.exists():
            print(f"   Files in dist: {list(dist_dir.iterdir())}")

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
    
    # Check if constants file exists, if not try root constants directory
    if not constants_file.exists():
        root_constants = PROJECT_ROOT / "constants" / "operatorRAW.json"
        if root_constants.exists():
            # Create constants directory and copy file
            constants_file.parent.mkdir(exist_ok=True, parents=True)
            shutil.copy2(root_constants, constants_file)
            print(f"✓ Copied constants file from root: {root_constants} -> {constants_file}")
        else:
            print(f"❌ Constants file not found: {constants_file}")
            print(f"   Also checked: {root_constants}")
            raise FileNotFoundError(f"Constants file not found in {constants_file} or {root_constants}")
    
    if not gui_script.exists():
        raise FileNotFoundError(f"GUI script not found: {gui_script}")
    
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

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='GenerationTwo',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='GenerationTwo',
)

app = BUNDLE(
    coll,
    name='GenerationTwo',
    icon=None,
    bundle_identifier='com.worldquant.generationtwo',
)
"""
    
    spec_file = PROJECT_ROOT / "generation_two_macos.spec"
    spec_file.write_text(spec_content)
    print(f"✓ Created spec file: {spec_file}")
    
    # Build app bundle using spec file
    # Note: Don't use --windowed flag when using a spec file - it's already in the spec
    print(f"✓ Building with spec file: {spec_file}")
    run_command(
        [sys.executable, "-m", "PyInstaller", "--clean", str(spec_file)],
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
