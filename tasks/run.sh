#!/usr/bin/env bash
puppet module install $PT_module_name
puppet apply -e $PT_execution_code

if [ "$PT_postinstall_cleanup" == "yes" ]; then
  puppet module uninstall $PT_module_name
fi