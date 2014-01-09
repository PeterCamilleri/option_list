# Really simple program # 3
# A Simple Interactive Ruby Environment
# SIRE Version 0.2.6

require 'readline'
require 'pp'
require_relative 'lib/option_list'
include Readline

class Object 
  def classes
    begin
      klass = self
      
      begin
        klass = klass.class unless klass.instance_of?(Class)
        print klass
        klass = klass.superclass
        print " < " if klass
      end while klass
      
      puts
    end
  end
end

def show_args(*args)
  args
end

puts "Welcome to SIRE Version 0.2.6"
puts "Simple Interactive Ruby Environment"
done = false

until done
  begin
    line = readline('SIRE>', true)
    result = eval line
    pp result unless result.nil?
  rescue Interrupt
    done = true
  rescue Exception => e
    puts "#{e.class} detected: #{e}"
    puts e.backtrace
    puts
  end
end

puts
puts "Bye bye for now!"

