require 'psych'

module McFS
  Config = Psych.load_file(File.join(MCFS_DIR_PATH,'config.yml'))
end
