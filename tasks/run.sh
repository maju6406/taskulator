#!/usr/bin/env bash
echo module_name:           $PT_module_name
echo module_version:        $PT_module_version
echo module_execution_code: $PT_module_execution_code

puppet module install $PT_module_name
echo $puppet_command >/tmp/taskulator.pp 
puppet apply /tmp/taskulator.pp &>/tmp/taskulator.log

if [ "$PT_postinstall_cleanup" == "yes" ]; then
  puppet module uninstall $PT_module_name
fi