# ChocolateyGet

## Overview

This module can be used to programatically build Chocolatey packages using a single configuration file which follows the winget package schema. The aim of this project is to make Chocolatey a bit more approachable especially to those without much of a powershell background.

## WinGet Schema

This module create chocolatey packages that are defined using the winget schema which can be found here: https://github.com/microsoft/winget-cli/blob/master/doc/ManifestSpecv0.1.md

See the ./Examples for details

## Contributing

### 1. Install build dependencies

* Install all build dependencies referenced in the `./.depend.psd1` file or run `Invoke-PSDepend` to automatically install all dependencies.

### 2. Add new code

* Add **public** or **exported** cmdlets and functions to the `./src/public` directory. Helper functions or **private** functions should be added to the `./src/private` directory. Any powershell **classes** should be defined in the `./src/models` directory. Finally, any additional **assets** (png files, binaries, etc) should be stored in the `./src/assets` directory. A description of each type of code is provided below

#### Private funtions

* Each **private** function should be in its own powershell script file (`*.ps1`) within the `./src/private` directory and the script name should match the function name. (eg. function name: `Invoke-Command`, script name: `Invoke-Command.ps1`)

#### Public funtions

* Each **public** function should be in its own powershell script file (`*.ps1`) within the `./src/public` directory and the script name should match the function name. (eg. function name: `Invoke-Command`, script name: `Invoke-Command.ps1`)

#### Classes

* Each **class** should be defined in its own powershell module file (`*.psm1`) within the `./src/models` directory and the file name should match the class name. (eg. A class named `MyClass` would be in a file named `MyClass.psm1` ). It can be referenced by other classes and functions by adding a `using` header to the first line of their script file. (eg. `using module .\MyClass.psm1`)

#### Tests

* A Pester test should be written for *each* function/cmdlet defined in the module. All tests should be stored in the `./tests` directory. Each test script file should match the name of the function being tested and be suffixed with `.Tests.ps1`. Each test script should only test a single function. For example: A function named `My-Function` will have a test script named `./tests/My-Function.Tests.ps1` and within this test script will contains tests for the function `My-Function`.

#### Assets

* Any additional assets required by the module code should be stored in the `./src/assets` directory. It is advisable to not use binary assets.

### 3. Build

* To build the code in the module locally run the run the `./.build.ps1` script to using `Invoke-Build`. This script will, analyze, test, and compile the module.

* The build script will create a new directory called `./.build` which will contain all the module code. All functions, classes, docs, and assets will be merged into the root module file.
