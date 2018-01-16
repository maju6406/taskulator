#!/usr/bin/env bash
echo module_names:       $PT_module_names
echo puppet_code:        $PT_puppet_code
echo module_postinstall: $PT_postinstall_cleanup

if [ "$PT_postinstall_cleanup" == "" || ["$PT_postinstall_cleanup" == "yes" ]; then
  echo Uninstall: $PT_postinstall_cleanup
  uninstall_flag = true
fi

for module_name in $PT_module_names; do
  echo installed $module_name 
  puppet module install $module_name &>>/tmp/taskulator_install.log
done 

echo $PT_puppet_code >/tmp/taskulator.pp 
puppet apply /tmp/taskulator.pp &>/tmp/taskulator.log

if [ "$uninstall_flag" == true ]; then
  echo Uninstalled modules
  for module_name in $PT_module_names; do
    puppet module uninstall $module_name &>>/tmp/taskulator_uninstall.log 
  done 
fi