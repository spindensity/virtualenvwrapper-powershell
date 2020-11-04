# VirtualEnvWrapper for Windows Powershell

This is a mimic of the powerfull [virtualenvwrapper](https://bitbucket.org/virtualenvwrapper/) but for Windows Powershell.


## Installation

Just use the `Install.ps1` script:

```powershell
.\Install.ps1
```


## Location

The virtual environments installed directory is set into your user home directory `$HOME\.virtualenvs`.

If you want to customize the virtual environments installed directory, just add the environment variable `WORKON_HOME` and set its value to the directory path to install the virtual environments.


## Usage

The module add few commands in PowerShell :

* `lsvirtualenv` (alias: `Get-VirtualEnvs`): list all Virtual environments;
* `mkvirtualenv` (alias: `New-VirtualEnv`): create a new virtual environment;
* `rmvirtualenv` (alias: `Remove-VirtualEnv`): remove an existing virtual environment;
* `workon` (alias: `Switch-VirtualEnv`): activate an existing virtual environment.


### Create a virtual environment

To create a virtual environment just type:

```powershell
mkvirtualenv -Name MyEnv -Python ThePythonDistDir
```

where `MyEnv` is the environment name and `ThePythonDistDir` is where the `python.exe` lives,  for example:

```powershell
mkvirtualenv -Name MyProject -Python c:\Python36
```

will create a virtual environment named `MyProject` located at `$WORKON_HOME` if set or `$HOME\.virtualenvs` as default with the python 3.6 distribution located at `C:\Python36`

If the `-Python` option is not set, the python command set in your `$env:PATH` is used by default.

Options are:

* `-Name`: the new environment name;
* `-Python`: the path of directory containing `python.exe`;
* `-Packages` or `-i`: install packages separated by a comma;
* `-Requirement` or `-r`: the requirement file to load.

If both options `-Packages` and `-Requirement` are set, the script will install first the packages then the requirements as in the original bash script.


### List virtual environments

Type:

```powershell
lsvirtualEnv
```

to display the list of all python virtual environments installed.

The output is something like:

```
        Python virtual environments available


Name            PythonVersion
----            -------------
EnvironmentName 3.8.6
```


### Activate a virtual environment

Type:

```powershell
workon EnvironmentName
```

If success, the PS command line starts now with:

```
(EnvironmentName) C:\Somewhere>
```

to show you the current activated virtual environment.

To ensure that the Python environment is the very one, type:

```powershell
Get-Command python
```

The output should be something like:

```
C:\Users\user\.virtualenvs\EnvironmentName\Scripts\python.exe
```


### Leave from a virtual environment

Just type `deactivate` as usual (python default).
