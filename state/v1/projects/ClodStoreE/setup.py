"""
Setup script for ClodStoreE
Optional - for proper package installation
"""

from setuptools import setup, find_packages

setup(
    name="clodstore",
    version="0.1.0",
    packages=find_packages(),
    install_requires=[],
    python_requires=">=3.7",
    author="ClodForest",
    description="Story state management for LangFlow",
)