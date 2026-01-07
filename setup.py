from setuptools import setup, find_packages
from pyouroboros import VERSION


def read(filename):
    with open(filename) as f:
        return f.read()


def get_requirements(filename="requirements.txt"):
    """returns a list of all requirements"""
    requirements = read(filename)
    return list(filter(None, [req.strip() for req in requirements.split() if not req.startswith('#')]))


# Convert "custom" to a valid PEP 440 version for local builds
version = VERSION if VERSION != "custom" else "0.0.0.dev0"


setup(
    name='ouroboros-cli',
    version=version,
    author='circa10a',
    author_email='wb@stylite.de',
    maintainer='styliteag',
    description='Automatically update running docker containers',
    long_description=read('README.md'),
    long_description_content_type='text/markdown',
    url='https://github.com/styliteag/ouroboros',
    license='MIT',
    classifiers=['Programming Language :: Python',
                 'Programming Language :: Python :: 3.6',
                 'Programming Language :: Python :: 3.7'],
    packages=find_packages(),
    scripts=['ouroboros'],
    install_requires=get_requirements(),
    python_requires='>=3.6.2'
)
