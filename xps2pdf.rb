#! /usr/bin/env ruby
# Converts Microsoft's XPS to PDF using Ghostscript.
# Tested on Mac OS X.
# Require Ruby 1.9.2.
# Automatically downloads Ghostscript, compiles it (with a 
# small fix), and converts all the list XPS files.
# Usage: ruby xps2pdf.rb [XPS files or dirs]

def main
  url      = 'http://ghostscript.googlecode.com/files/ghostpdl-9.02.tar.bz2'
  tmp      = "/tmp/xps2pdf.tmp"
  bzipfile = File.basename(url)
  dirname  = bzipfile.gsub /[.]tar[.]bz2/, ''
  gccmake  = File.join(dirname, "main", "pcl6_gcc.mak")
  xps      = File.join(tmp, dirname, "xps/obj/gxps")
  convert  = "#{xps} -sDEVICE=pdfwrite -sOutputFile='%s' -dNOPAUSE '%s'"

  # Download and compile Ghostscript into the tmp directory.
  Dir.mkdir(tmp) unless File.exists?(tmp)
  Dir.chdir(tmp) do
    if !File.exists?(bzipfile)
      puts "downloading #{url}..."
      `curl -s -O #{url}`
    end
    
    if !File.exists?(dirname)
      puts "extracting #{bzipfile}..."
      `bzip2 -dc "#{bzipfile}" | tar -xpvf - &> /dev/null`
    end
    
    if !File.exists?(xps)
      puts "fixing the makefile..."
      comment_out = '.*include ../config.mak'
      oldc = File.read(gccmake)
      newc = oldc.gsub(/#{comment_out}/, '#\0')
      open(gccmake, 'w') { |f| f.write newc  }

      puts "compiling..."
      Dir.chdir(dirname) { `make xps &> /dev/null` }
    end
  end

  ARGV.each do |xps|
    pdf = xps.gsub(/[.]xps$/, '.pdf')
    if File.exists?(pdf)
      puts "skipping existing #{pdf}"
    else
      cmd = convert % [pdf, xps]
      puts "converting\n  #{xps} =>\n  #{pdf}"
      `#{cmd}`
    end
  end
rescue
  puts "error: #{$!}"
end

if $0 == __FILE__
  main
end
