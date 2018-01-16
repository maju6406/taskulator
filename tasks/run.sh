#!/usr/bin/env bash
echo module_names:          $PT_module_names
echo module_execution_code: $PT_puppet_code

if [ "$PT_postinstall_cleanup" == "" || ["$PT_postinstall_cleanup" == "yes" ]; then
  uninstall_flag = true
fi

for module_name in $PT_module_names; do
  puppet module install module_name
done 

echo $PT_puppet_code >/tmp/taskulator.pp 
puppet apply /tmp/taskulator.pp &>/tmp/taskulator.log

if [ "$uninstall_flag" = true ]; then
  for module_name in $PT_module_names; do
    puppet module uninstall module_name
  done 
fi