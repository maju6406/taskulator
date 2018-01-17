#!/opt/puppetlabs/puppet/bin/ruby

require 'json'
require 'open3'

def exec(command)
  output, exit_code  = Open3.popen2({}, command, {:err => [:child, :out]}) do  |i, o, w|
    out = o.read()
    exit_code = w.value.exitstatus
    [out, exit_code]
  end

  { _output: output,
    exit_code: exit_code
  }
end

def install_module(mod)
    puts "module name: #{mod}"
end

def puppet_apply(code)
    puts "puppet_code: #{code}"
end

params = JSON.parse(STDIN.read)
#module_names = params['module_names']
puppet_code = params['puppet_code']
postinstall_cleanup = params['postinstall_cleanup']
failonfail = true

begin
  params['module_names'].each do |module_name|
    begin
      install_module(module_name)
    rescue
      puts "couldn't update file #{module_name}"
    end
  end
  puppet_apply(puppet_code)
  puts "postinstall_cleanup: #{postinstall_cleanup}"
  result = exec(command)
  puts result.to_json
  
  if failonfail
    exit result[:exit_code]
  else
    exit 0
  end
end