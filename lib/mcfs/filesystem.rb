
require 'set'
require 'yaml'

require_relative 'stores/dropbox'

module McFS
  class Filesystem
    
    def initialize
      @stores = []
      dbcfg1 = YAML.load_file(ENV['HOME'] + '/.mcfs/dropbox1.yml')
      dbcfg2 = YAML.load_file(ENV['HOME'] + '/.mcfs/dropbox2.yml')
      
      @stores << Stores::Dropbox.new(dbcfg1.access_token)
      @stores << Stores::Dropbox.new(dbcfg2.access_token)
      
    end

    def contents(path)
      files = []
      
      futures = []
      @stores.each do |store|
        futures << store.future.contents(path)
      end
      
      futures.each do |future|
        files += future.value
      end
      
      files.uniq
    end

    def file?(path)
      true
    end

    def can_write?(path)
      true
    end
    
    def read_file(path)
      puts "Read File: #{path}"
      contents = {}
      
      futures = []
      @stores.each do |store|
        futures << store.future.read_file(path)
      end
      
      futures.each do |future|
        contents.merge! future.value
      end
      
      data = ''
      
      contents.sort.each do |chunk|
        data << chunk[1]
      end
      
      data
    end
    
    def write_to(path, str)
      puts "write_to: #{path}, #{str}"
      buf = ''
      cnt = 0
      idx = 0
      
      str.each_byte do |b|
        buf << b
        cnt += 1
        
        if cnt == 4096 then
          @stores[idx % @stores.size].write_to(path, idx, buf)
          buf = ''
          idx += 1
          cnt = 0
        end
      end
      
      if buf.size > 0 then
        puts buf.size
        puts idx
        p @stores
        puts @stores[idx % (@stores.size)]
        @stores[idx % @stores.size].write_to(path, idx, buf)
      end
      
    end
    
  end
end
