#!/usr/bin/env ruby

if ARGV.length == 0
  sig_exit = Proc.new { trap "EXIT", sig_exit; puts "sig_exit" }
  sig_term = Proc.new { trap "TERM", sig_term; puts "sig_term" }
  sig_quit = Proc.new { trap "QUIT", sig_quit; puts "sig_quit" }
  sig_int  = Proc.new { trap "INT" , sig_int ; puts "sig_int"  }
else
  sig_exit = sig_term = sig_quit = sig_int = "IGNORE"
end

trap "EXIT", sig_exit
trap "TERM", sig_term
trap "QUIT", sig_quit
trap "INT" , sig_int

loop {}
