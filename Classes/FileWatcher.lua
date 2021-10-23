--Scans files and folders for changes. Used for auto refreshing feature when developing the editor.

FileWatcher = FileWatcher or class()

function FileWatcher:init(opt)
    self._files = {}
    self._folders = {}
    self._path = opt.path
    opt = opt or {}
    self._scan_t = opt.scan_t
    self._callback = opt.callback
    self._folder_callback = opt.folder_callback
    self._no_break = opt.no_break or false
    self._scan_t = opt.scan_t or 1
    self._dont_scan_files = opt.dont_scan_files or false
    self._dont_scan_folders = opt.dont_scan_folders or false
    self._dont_rescan_files = opt.dont_rescan_files or false

    if opt.files then
        for _, file in ipairs(opt.files) do
            self:WatchFile(file)
        end
    end

    self:CollectFilesAndFolders(self._path)
end

function FileWatcher:WatchFile(file)
    self._files[file] = lfs.attributes(file, "modification")
end

function FileWatcher:UnwatchFile(file)
    self._files[file] = nil
end

function FileWatcher:CollectFilesAndFolders(path)
    if path then
        for _, file in pairs(FileIO:GetFiles(path)) do
            self:WatchFile(path.."/"..file)
        end
        
        for _, folder in pairs(FileIO:GetFolders(path)) do
            local full_path = path.."/"..folder
            self._folders[full_path] = lfs.attributes(full_path, "modification")
            self:CollectFilesAndFolders(full_path)
        end
    end
end

function FileWatcher:Update(t, dt)
    if not self._next_scan or t >= self._next_scan then
        if not self._dont_scan_files then
            for file, mod in pairs(self._files) do
                local last_mod = lfs.attributes(file, "modification")
                if mod ~= last_mod then
                    self._callback(file)
                    self._files[file] = last_mod
                    if not self._no_break then
                        break
                    end
                end
            end
        end
        local first
        if not self._dont_scan_folders then
            for file, mod in pairs(self._folders) do
                if mod ~= lfs.attributes(file, "modification") then
                    if (not self._folder_callback or self._folder_callback(file, true) ~= false) and not self._dont_rescan_files then
                        if not first then
                            self._files = {}
                            self._folders = {}
                        end
                        first = true
                        self:CollectFilesAndFolders(self._path)
                    end                        
                end

                if not self._no_break then
                    break
                end
            end
        end
        self._next_scan = t + self._scan_t
    end
end