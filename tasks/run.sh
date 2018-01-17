#!/usr/bin/env bash
echo names:               $PT_module_names
echo puppet_code:         $PT_puppet_code
echo postinstall_cleanup: $PT_postinstall_cleanup

array_string=${PT_module_names#"["}
array_string=${array_string%"]"}
array_string=${array_string//\"}
IFS=',' read -a name_array <<< "${array_string}"
for module_name in "${name_array[@]}"
do
  echo $module_name installed
  puppet module install $module_name &>>/tmp/taskulator_install.log
done

echo $PT_puppet_code >/tmp/taskulator.pp 
puppet apply /tmp/taskulator.pp &>/tmp/taskulator.log
echo Puppet code executed

if [ "$PT_postinstall_cleanup" == "yes" ] || [ "$PT_postinstall_cleanup" == "" ]; then
  echo Modules uninstalled
  for module_name in "${name_array[@]}"
  do
    puppet module uninstall $module_name &>>/tmp/taskulator_uninstall.log
  done
fi