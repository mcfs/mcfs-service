require_relative   'namespace'

module McFS; module Service
  
  # McFSShare is a namespace created from a collection of stores
  class McFSShare < Namespace
    
    # Use 64 kB chunk size until we find a mechanism to decide an optimum
    # value.
    CHUNK_SIZE = (64 * 1024)
    
    def initialize(nsid, stores)
      super nsid
      @stores = []
      @sharedir = "/.McFS/#{nsid}"
      
      # TODO: create /.McFS/<nsid> directory under each store
      stores.each do |store|
        if meta = store.metadata('/.McFS')
          unless meta.is_a? DirMeta
            Log.info "McFSShare skipping store"
            next
          end
        else
          store.mkdir('/.McFS') # Assuming it would work
        end
        
        if meta = store.metadata(@sharedir)
          unless meta.is_a? DirMeta
            Log.info "McFSShare skipping store"
            next
          end
        else
          store.mkdir(@sharedir) # Assuming it would work
        end
        
        Log.info "McFSShare adding store #{store.nsid}"
        
        @stores << store
      end
      
    end # initialize
    
    def list(dirpath)
      Log.info "McFSShare listing contents of #{dirpath}"
      
      file_list = []
      
      # For directories, take their names as such. For files, strip
      # their suffixes.
      stores_perform(:metadata, dirpath).each do |store, dirmeta|
        dirmeta.contents.each do |entry|
          
          file_list << if entry.is_a? DirMeta
             entry.name
          else
            File.basename(entry.name, '.*')
          end
          
        end
      end 
      
      file_list.uniq
      
    end
    
    def metadata(path)
      Log.info "McFSShare metadata for #{path}"
      
      if path == '/'
        return DirMeta.new('/', 'NA')
      end
      
      basename = File.basename(path)
      filesize = nil
      
      parent_dir = File.dirname(path)
      
      # Now go through the contents of parent directory in each store and
      # check to see if there's a directory that exactly matches the name
      # of the path we are looking for. If so, return the metadata of the
      # directory.
      #
      # Otherwise, we need to assume the entry must be a file and therefore
      # look for all files whose filename with suffix removed matches the
      # basename of the path we are seaching for.
      stores_perform(:metadata, parent_dir).each do |store, dirmeta|
        dirmeta.contents.each do |entry|
          if entry.name == basename and entry.is_a? DirMeta
            # Note that we do not try to fill the contents of DirMeta unlike
            # how the stores does it.
            # TODO: need to look in to this later.
            return DirMeta.new(entry.name, entry.mtime)
          end
          
          if File.basename(entry.name, '.*') == basename and entry.is_a? FileMeta
            filesize ||= 0
            filesize += entry.size
          end
        end
      end
      
      if filesize
        FileMeta.new(basename, filesize, 'N/A')
      else
        nil
      end
      
    end # metadata
    
    def readfile(path)
      Log.info "McFSShare readfile #{path}"
      
      results = {}
      
      stores_perform_selective(:readfile, stores_fileparts(path)).each do |store, parts|
        parts.each do |path, result|
          index = File.extname(path)[1..-1].to_i
          results[index] = result
        end
      end
      
      # Join together all the results, sorted by their index number
      results.sort.collect { |index, result| result }.join
    end
    
    def writefile(path, data)
      Log.info "McFSShare writefile to #{path}"
      
      fileparts = []
      
      # Break data into chunks until the last chunk becomes an empty
      # chunk (for now we write empty chunk too).
      begin
        fileparts << data.slice!(0, CHUNK_SIZE)
      end until fileparts[-1].size == 0
      
      # { store => { path => data } }
      # List contents to be written/deleted. For paths that need
      # deletion, set data to nil.
      contents = {}
      
      # By default existing parts are to be deleted
      stores_fileparts(path).each do |store, files|
        contents[store] = files.each_with_object({}) do |file, hsh|
          hsh[file] = nil
        end
      end
      
      # Now add new data to contents
      fileparts.each_with_index do |data, index|
        store = next_store
        filename = "#{path}.#{index}"
        
        contents[store] ||= {}
        contents[store][filename] = data
      end
      
      # The generic actions to be performed are now going to be created
      # based on contents created above.
      actions = {}
      
      contents.each do |store, fileparts|
        actions[store] = []
        
        fileparts.each do |filepath, data|
          store_filepath = store_path(filepath)
          
          actions[store] << if data
            # Write/overwrite file
            [ :writefile, [store_filepath, data] ]
          else
            # Delete the file
            [ :delete, [store_filepath] ]
          end
          
        end # fileparts
      end # contents
      
      # pp actions
      #
      stores_perform_generic(actions)
      
    end # writefile
    
    def delete(path)
      Log.info "McFSShare delete #{path}"
      
      stores_perform_selective(:delete, stores_fileparts(path))
    end
    
    def mkdir(path)
      Log.info "McFSShare mkdir #{path}"
      
      stores_perform(:mkdir, path)
    end # mkdir
    
    def rmdir(path)
      Log.info "McFSShare rmdir #{path}"
      
      stores_perform(:rmdir, path)
    end
    
    private
    
    def next_store
      if @laststore
        @laststore += 1
        @laststore = (@laststore % @stores.size)
      else
        @laststore = 0
      end
      
      @stores[@laststore]
    end
    
    def store_path(path)
      if path == '/'
        @sharedir
      else
        File.join(@sharedir, path)
      end
    end
    
    # Perform different set of operation of different stores with
    # separate list of arguments.
    #
    # { store => [[op,[arg,...]],...],... }
    #
    # returns { store => [[op,[arg,...],result],...],... }
    def stores_perform_generic(actions)
      Log.info "McFSShare store perform generic"
      
      results = {}
      
      actions.each do |store, ops|
        results[store] = []
        
        ops.each do |op, args|
          
          future = Celluloid::Future.new do
            store.send(op, *args)
          end # Future
          
          results[store] << [op, args, future]
        end
      end
      
      results.each do |store, ops|
        ops.each do |op_info|
          op_info[2] = op_info[2].value
        end
      end
      
      results
      
    end # stores_perform_generic

    # Perform a given operation on a path inside a store with optional
    # additional arguments
    def stores_perform(op, path, *args)
      Log.info "McFSShare store perform #{op} on #{path}"
      
      storepath = store_path(path)
      
      actions = {}
      
      # Initiate operations as futures
      @stores.each do |store|
        actions[store] = []
        actions[store] << [ op, [storepath] + [*args] ]
      end
      
      results = {}
      
      stores_perform_generic(actions).each do |store, opresults|
        _, _, result = opresults.pop
        results[store] = result
      end
      
      results
      
    end # stores_perform
        
    # Perform a given operation on a set of paths for a set of stores
    # with optional additional arguments
    # pathlist is a map from store => list of paths
    # { store => [path,...],... }
    #   or
    # { store => {path => [arg1,...],...} }
    # 
    # returns { store => { path => result,... },... }
    #
    # TODO: Implement this using stores_perform_generic()
    #
    def stores_perform_selective(op, pathlist, *args_default)
      Log.info "McFSShare store perform selective #{op}"
      
      futures = {}
      results = {}
      
      pathlist.each do |store, paths|
        futures[store] = {}
        
        # paths can either be a simple array of path strings or a hash
        # map from path name to args.
        #
        # Note that 'args' will become nil when paths is just an array.
        paths.each do |path, args_specific|
          storepath = store_path(path)
          args = args_specific ? args_specific : args_default
          
          futures[store][path] = Celluloid::Future.new do
            store.send(op, storepath, *args)
          end # Future
          
        end
      end
      
      # Collect the results
      futures.each do |store, futurelist|
        results[store] = {}
        
        futurelist.each do |path, future|
          results[store][path] = future.value
        end
      end
      
      results
      
    end # stores_perform_selective
    
    # List all suffixed files present in a path in all stores
    def stores_fileparts(filepath)
      Log.info "McFSShare fileparts #{filepath}"
      
      basename = File.basename(filepath)
      dirname = File.dirname(filepath)
      
      partlist = {}
      
      stores_perform(:list, dirname).each do |store, entries|
        partlist[store] = entries.collect do |entry|
          File.join(dirname, entry) if File.basename(entry, '.*') == basename
        end.compact
      end
      
      partlist
      
    end
    
  end # McFSShare
end; end

# require 'celluloid'
#
# module McFS
# module Stores
#
#   class McFSShare < FuseFS::FuseDir
#
#     # include Celluloid
#
#     def initialize(fs)
#       @fs = fs
#     end
#
#     def contents(dir)
#       Log.info "[McFS]: ls #{dir}..."
#
#       futures = []
#
#       @fs.stores.each do |store|
#         futures << store.future.contents('/McFS' + dir)
#       end
#
#       files = []
#
#       futures.each do |future|
#         future.value.each do |ent|
#           files << File.basename(ent, '.*')
#         end
#       end
#
#       files.uniq
#     end
#
#     def info
#       {
#         'service' => 'McFSShare',
#         'uid' => 0,
#         'name' => '',
#         'capacity' => 0,
#         'used' => 0,
#         'token' => ''
#       }
#     end
#
#     def directory?(path)
#       path == '/'
#
#       # futures = []
#       # @fs.stores.each do |store|
#       #   futures << store.future.directory?('/McFS')
#       # end
#       #
#       # are_dirs = []
#       #
#       # futures.each do |future|
#       #   are_dirs << future.value
#       # end
#       #
#       # are_dirs.compact! == [true]
#
#     end
#
#
#     def can_mkdir?(path)
#       false
#     end
#
#     # def times(path)
#     # end
#
#     # def file?(path)
#     #   if meta = @metadata[File.dirname(path)]
#     #     meta['contents'].detect {|e| e['path'] == path }
#     #   end
#     # end
#
#     def file?(path)
#       Log.info "[McFS]: file? #{path}..."
#
#       # For the time being, we will accept the path as a file
#       # if any of the stores have it as a file
#       futures = {}
#       @fs.stores.each do |store|
#         futures[store.future.contents('/McFS')] = store
#       end
#
#       ffutures = []
#       futures.each do |future, store|
#         future.value.each do |ent|
#           if File.basename(ent, '.*') == File.basename('/McFS' + path)
#             ffutures << store.future.file?('/McFS/' + ent)
#           end
#         end
#       end
#
#       ffutures.each {|f| return true if f.value == true }
#
#       false
#       # futures = []
#       # @fs.stores.each do |store|
#       #   futures << store.future.file?('/McFS')
#       # end
#       #
#       # are_files = []
#       #
#       # futures.each do |future|
#       #   are_files << future.value
#       # end
#       #
#       # are_files.compact! == [true]
#     end
#
#     # Everything is writable in Dropbox
#     def can_write?(path)
#       File.dirname(path) == '/'
#     end
#
#     def executable?(path)
#       true
#     end
#
#     # Size of a file in bytes
#     def size(path)
#       Log.info "[McFS]: size #{path}..."
#
#       futures = {}
#       @fs.stores.each do |store|
#         futures[store.future.contents('/McFS')] = store
#       end
#
#       sizes = {}
#       futures.each do |future, store|
#         future.value.each do |ent|
#           if File.basename(ent, '.*') == File.basename('/McFS' + path)
#             index = File.extname(ent)[1..-1].to_i
#             sizes[index] = store.future.size('/McFS/' + ent)
#           end
#         end
#       end
#
#       total_size = 0
#       sizes.each_value {|size| total_size += size.value }
#       total_size
#     end
#
#     def read_file(path)
#       Log.info "[McFS]: read #{path}..."
#
#       futures = {}
#       @fs.stores.each do |store|
#         futures[store.future.contents('/McFS')] = store
#       end
#
#       contents = {}
#       futures.each do |future, store|
#         future.value.each do |ent|
#           if File.basename(ent, '.*') == File.basename('/McFS' + path)
#             index = File.extname(ent)[1..-1].to_i
#             contents[index] = store.future.read_file('/McFS/' + ent)
#           end
#         end
#       end
#
#       data = ''
#       contents.sort.each do |chunk|
#         data << chunk[1].value
#       end
#
#       data
#     end
#
#     def write_to(path, str)
#       Log.info "[McFS]: write #{path} #{str.size}..."
#
#       delete(path)
#
#       buf = ''
#       cnt = 0
#       idx = 0
#       stores = @fs.stores
#
#       wfutures = []
#
#       str.each_byte do |b|
#         buf << b
#         cnt += 1
#
#         if cnt == 4096 then
#           wfutures << stores[idx % stores.size].future.write_to("/McFS#{path}.#{idx}", buf)
#           buf = ''
#           idx += 1
#           cnt = 0
#         end
#       end
#
#       if buf.size > 0 then
#         wfutures << stores[idx % stores.size].future.write_to("/McFS#{path}.#{idx}", buf)
#       end
#
#       # Wait until the files are written
#       wfutures.each { |future| future.value }
#
#     end
#
#     def can_delete?(path)
#       true
#     end
#
#     def delete(path)
#       Log.info "[McFS]: rm #{path}..."
#
#       # First delete the existing files - unfortunately the only
#       # way right now
#       futures = {}
#       @fs.stores.each do |store|
#         futures[store.future.contents('/McFS')] = store
#       end
#
#       dfutures = []
#       futures.each do |future, store|
#         future.value.each do |ent|
#           if File.basename(ent, '.*') == File.basename('/McFS' + path)
#             dfutures << store.future.delete('/McFS/' + ent)
#           end
#         end
#       end
#
#       # Wait until the files are deleted
#       dfutures.each { |future| future.value }
#
#     end
#
#     def can_mkdir?(path)
#       false
#     end
#
#     # def mkdir(path)
#     #   Log.info "[#{user_identity}]: mkdir #{path}..."
#     #
#     #   # @metadata[path] = @client.file_create_folder(path)
#     #   @client.file_create_folder(path)
#     # end
#
#     def can_rmdir?(path)
#       #FIXME
#       false
#     end
#
#     # def rmdir(path)
#     #   #FIXME
#     #   nil
#     # end
#
#   end # McFSShare
# end # Stores
# end # McFS
