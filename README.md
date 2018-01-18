[![Build Status](https://travis-ci.org/maju6406/taskulator.svg?branch=master)](https://travis-ci.org/maju6406/taskulator)

# taskulator

#### Table of Contents

1. [Description](#description)
2. [Requirements](#requirements)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Getting help - Some Helpful commands](#getting-help)

## Description

This module provides the taskulator task. This task allows you to install modules and run arbitary puppet code.

## Requirements
This module is compatible with Puppet Enterprise and Puppet Bolt.

* To run tasks with Puppet Enterprise, PE 2017.3 or later must be installed on the machine from which you are running task commands. Machines receiving task requests must be Puppet agents.

* To run tasks with Puppet Bolt, Bolt 0.5 or later must be installed on the machine from which you are running task commands. Machines receiving task requests must have SSH or WinRM services enabled. If using Bolt, the puppet agent must already installed.

## Usage

There are 3 parameters:
* module_names : modules you want to run. Ex \["puppetlabs-ntp","puppetlabs-motd"\]
* puppet_code : code you want to execute.
* postinstall_cleanup (Optional) : uninstall modules post execution
* puppet_code_url (Optional) : url to code that you want to execute (takes precedence over puppet_code)

## Reference

To view the available actions and parameters, on the command line, run `puppet task show taskulator` or see the taskulator module page on the [Forge](https://forge.puppet.com/beersy/taskulator/tasks).

## Getting Help

To display help for the taskulator task, run `puppet task show taskulator::run`

To show help for the task CLI, run `puppet task run --help` or `bolt task run --help`

## Limitations
This modules has been tested on Centos and Windows 2012r2 machines. It may work on other platforms but is untested,

## Release Notes/Contributors/Etc.
0.2.0 - Added support for Windows  
0.1.0 - Initial Release