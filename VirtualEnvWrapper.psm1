#
# Python virtual environment manager inspired by VirtualEnvWrapper
#
# Copyright (c) 2020 spindensity
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

$WORKON_HOME = $env:WORKON_HOME

#
# Set the default path and create the directory if not exist
#
if (!$WORKON_HOME) {
    $WORKON_HOME = "$env:USERPROFILE\.virtualenvs"
}

if (!(Test-Path $WORKON_HOME)) {
    New-Item -ItemType Directory -Force -Path $WORKON_HOME
}


#
# Get the absolute path for the environment
#
function Get-FullPythonEnvPath($EnvName) {
    return ("{0}\{1}" -f $WORKON_HOME, $EnvName)
}


#
# Display a formated error message
#
function Write-FormatedError($Message) {
    Write-Host "`n  ERROR: $Message`n" -ForegroundColor Red
}


#
# Display a formated success messge
#
function Write-FormatedSuccess($Message) {
    Write-Host "`n  SUCCESS: $Message`n" -ForegroundColor Green
}


#
# Return the major version of python
#
function Get-PythonMajorVersion($Python) {
    if (!(Test-Path $Python)) {
        Write-FormatedError "$Python doesn't exist"
        return
    }

    $python_version = Invoke-Expression "& '$Python' --version 2>&1"
    if (!$python_version) {
        Write-Host "Cann't find python in your path" -ForegroundColor Red
        return
    }

    $is_version_2 = ($python_version -match "^Python\s2") -or ($python_version -match "^Python\s3.3")
    $is_version_3 = $python_version -match "^Python\s3" -and !$is_version_2

    if (!$is_version_2 -and !$is_version_3) {
        Write-FormatedError "Invalid python version, expect python 2 or python 3 but get $python_version"
        return
    }

    return $(if ($is_version_2) {"2"} else {"3"})
}


#
# Common command to create the Python Virtual Environement.
# $Command contains either the Py2 or Py3 command
#
function Invoke-CreatePythonEnv($Command, $Name) {
    $new_env = Join-Path $WORKON_HOME $Name
    Write-Host "Creating virtual environment... "

    Invoke-Expression "$Command '$new_env'"

    $env_scritps_path = Join-Path $new_env "Scripts"
    $activate_path = Join-Path $env_scritps_path "Activate.ps1"
    . $activate_path

    Write-FormatedSuccess "$Name virtual environment was created and activated."
}


#
# Create virtual environment using the virtualenv.exe command
#
function New-Python2Env($Python, $Name)  {
    $python_exe = $Python
    if (!$python_exe) {
        $python_exe = Find-Python
    }

    $virtualenv_exe = (Join-Path (Join-Path (Split-Path $python_exe -Parent) "Scripts") "virtualenv.exe")
    if (!(Test-Path $virtualenv_exe)) {
        Write-FormatedError "You must install virtualenv program to create the virtual environment '$Name'"
        return
    }

    $command = "G '$virtualenv_exe'"

    Invoke-CreatePythonEnv $command $Name
}


#
# Create python environment using the venv module
#
function New-Python3Env($Python, $Name) {
    $python_exe = $Python
    if (!$python_exe) {
        $python_exe = Find-Python
    }

    $command = "& '$python_exe' -m venv"

    Invoke-CreatePythonEnv $command $Name
}


#
# Find python.exe in the path. If $Python is given, try $Python as the given python path
#
function Find-Python ($Python) {
    if (!$Python) {
        return Get-Command "python.exe" | Select-Object -ExpandProperty Source
    }

    $python_exe = $Python

    if (Test-Path $Python -PathType Container) {
        $python_exe = Join-Path $python_exe "python.exe"
    }

    if (!$python_exe.EndsWith("python.exe") -or !(Test-Path $python_exe -PathType Leaf)) {
        return $false
    }

    return $python_exe
}


#
# Create the virtual environment
#
function New-PythonEnv($Python, $Name, $Packages) {
    $python_major_version = Get-PythonMajorVersion $Python

    if ($python_major_version -eq "2") {
        New-Python2Env -Python $Python -Name $Name
    } elseif ($python_major_version -eq "3") {
        New-Python3Env -Python $Python -Name $Name
    } else {
        throw "Invalid python path: $Python"
    }
}

#
# Test if there's currently a python virtual environment
#
function Get-IsInPythonEnv($Name) {
    if ($env:VIRTUAL_ENV) {
        if (!$Name) {
            return $true
        }

        if ($Name -and ((Split-Path $env:VIRTUAL_ENV -Leaf) -eq $Name)) {
            return $true
        }
    }

    return $false
}


# Now, work on a virtual environment
function Switch-VirtualEnv {
    [CmdletBinding()]
    param(
        [string]$Name
    )

    if (!$Name) {
        Write-FormatedError "No virtual environment to work on, did you forget the -Name option?"
        return
    }

    $new_pyenv = Get-FullPythonEnvPath $Name
    if (!(Test-Path $new_pyenv)) {
        Write-FormatedError "The virtual environment '$Name' doesn't exist, you may want to create it with 'mkvirtualenv $Name'"
        return
    }

    if (Get-IsInPythonEnv) {
        deactivate
    }

    $activate_path = "$new_pyenv\Scripts\Activate.ps1"
    if (!(Test-path $activate_path)) {
        Write-FormatedError "Unable to find the activation script, your virtual environment '$Name' seems corrupted"
        return
    }

    . $activate_path
}


#
# Create a new virtual environment.
#
function New-VirtualEnv {
    param(
        [Parameter(HelpMessage="The virtual environment name")]
        [string]$Name,

        [Parameter(HelpMessage="The requirements file")]
        [alias("r")]
        [string]$Requirement,

        [Parameter(HelpMessage="The directory where the python.exe lives")]
        [string]$Python,

        [Parameter(HelpMessage="The packages to install")]
        [alias("i")]
        [string[]]$Packages
    )

    if ($Name.StartsWith("-")) {
        Write-FormatedError "The virtual environment name couldn't start with - (minus)"
        return
    }

    if (!$Name) {
        Write-FormatedError "You must at least give me a virtual environment name"
        return
    }

    if (IsPythonEnvExists $Name) {
        Write-FormatedError "There is an environment with the same name"
        return
    }

    $python_real_path = Find-Python $Python
    if (!$python_real_path) {
        Write-FormatedError "The path of python doesn't exist: $Python"
        return
    }

    New-PythonEnv -Python $python_real_path -Name $Name

    foreach($Package in $Packages)  {
        Invoke-Expression "& '$WORKON_HOME\$Name\Scripts\pip.exe' install $Package"
    }

    if ($Requirement -ne "") {
        if (!(Test-Path $Requirement -PathType Leaf)) {
            Write-Error "The requirement file doesn't exist"
            return
        }

        Invoke-Expression "& '$WORKON_HOME\$Name\Scripts\pip.exe' install -r $Requirement"
    }
}


#
# Check if there is an environment named $Name
#
function IsPythonEnvExists($Name) {
    return ![string]::IsNullOrEmpty($Name) -and (Test-Path -path (Join-Path $WORKON_HOME $Name) -PathType Container)
}


class VirtualEnv {
    [ValidateNotNullOrEmpty()][string]$Name
    [ValidateNotNullOrEmpty()][string]$PythonVersion

    VirtualEnv($Name, $PythonVersion) {
       $this.Name= $Name
       $this.PythonVersion = $PythonVersion
    }
}


function Get-VirtualEnvs {
    $children = Get-ChildItem $WORKON_HOME
    if ($children.Length -gt 0) {
        Write-Host "`n`n`tPython virtual environments available"

        $children | ForEach-Object {
            $env_name = $_.Name
            $python_version = (((Invoke-Expression ("& '$WORKON_HOME\{0}\Scripts\python.exe' --version 2>&1" -f $env_name)) -replace "`r|`n","") -Split " ")[1]
            [VirtualEnv]::new($env_name, $python_version)
        }
    } else {
        Write-Host "`n`n`tNo python virtual environments"
    }

    Write-Host
}


#
# Remove a virtual environment.
#
function Remove-VirtualEnv {
    [CmdletBinding()]
    param(
        [string]$Name
    )

    if (Get-IsInPythonEnv $Name) {
        Write-FormatedError "You want to remove the virtual environment you are in, please type 'deactivate' first"
        return
    }

    if (!$Name) {
        Write-FormatedError "You must give an environment name"
        return
    }

    $full_path = Get-FullPythonEnvPath $Name
    if (Test-Path $full_path) {
        Remove-Item -Path $full_path -Recurse
        Write-FormatedSuccess "$Name has been deleted permanently"
    } else {
        Write-FormatedError "Virtual environment $Name not found"
    }
}


$ScriptBlock = { (Get-ChildItem -Path $WORKON_HOME).Name }
Register-ArgumentCompleter -CommandName Switch-VirtualEnv -ParameterName Name -ScriptBlock $ScriptBlock
Register-ArgumentCompleter -CommandName Remove-VirtualEnv -ParameterName Name -ScriptBlock $ScriptBlock


#
# Powershell alias for naming convention
#
Set-Alias lsvirtualenv Get-VirtualEnvs
Set-Alias rmvirtualenv Remove-VirtualEnv
Set-Alias mkvirtualenv New-VirtualEnv
Set-Alias workon Switch-VirtualEnv
