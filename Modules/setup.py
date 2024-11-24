from setuptools import setup
from Cython.Build import cythonize

setup(
    ext_modules=cythonize("mysql_runner.pyx"),
    install_requires=[
        'pandas',  # Ensure Pandas is installed
    ],
)
