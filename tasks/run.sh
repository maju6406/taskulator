#!/usr/bin/env bash
echo module_name:           $PT_module_name
echo module_version:        $PT_module_version
echo module_execution_code: $PT_execution_code

puppet module install $PT_module_name
puppet apply -e $PT_module_execution_code

if [ "$PT_postinstall_cleanup" == "yes" ]; then
  puppet module uninstall $PT_module_name
fi