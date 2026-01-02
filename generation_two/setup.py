"""
Setup script for Generation Two
"""

from setuptools import setup, find_packages
from pathlib import Path

# Get the directory where setup.py is located
setup_dir = Path(__file__).parent
# Get project root (parent of generation_two) - this is where the package actually is
project_root = setup_dir.parent

# Read README
readme_file = setup_dir / "README.md"
long_description = readme_file.read_text(encoding="utf-8") if readme_file.exists() else ""

setup(
    name="generation-two",
    version="1.0.0",
    description="WorldQuant Brain Alpha Mining System - Generation Two",
    long_description=long_description,
    long_description_content_type="text/markdown",
    author="WorldQuant Miner",
    author_email="your-email@example.com",
    url="https://github.com/yourusername/worldquant-miner",
    # Specify package_dir so packages are found relative to project root
    package_dir={'': str(project_root)},
    packages=find_packages(where=str(project_root)),  # Find packages in project root
    include_package_data=True,
    install_requires=[
        "requests>=2.28.0",
    ],
    python_requires=">=3.8",
    entry_points={
        "console_scripts": [
            "generation-two=generation_two.gui.run_gui:main",
        ],
    },
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Financial and Insurance Industry",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
)
