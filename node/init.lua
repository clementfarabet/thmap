local async = require 'async'

return function(opt)
   -- handles to jobs spawned, plus their options:
   local handles = {}
   local hoptions = {}
   local activity = {}

   -- logs
   local c = async.repl.colorize
   local hostname = 'localhost'

   local thnode = {}


   ---------------------------------------------------------------------------------
   -- functions to override for additional flexibility.  this feels kind of hacky...
   ---------------------------------------------------------------------------------
   
   local logpreprocess = function(instance, data)
      return true
   end

   local newprocess = function(name)
   end
   
   ---------------------------------------------------------------------------------


   local function log(instance,data)
      local lines = stringx.split(data,'\n')
      for _,line in ipairs(lines) do
         if line == '' or (line and line:find('idle$')) then
         else
            -- log line:
            local line = string.format('%s> %s> %s', c.Black(hostname), c.blue(instance), c.green(line))
            print(line)

            -- log activity:
            if opt.killdelay > 0 then
               activity[instance] = (activity[instance] or 0) + 1
            end
         end
      end
   end

   -- log activity:
   if opt.killdelay > 0 then
      async.setInterval(1000*opt.killdelay, function()
         for instance,count in pairs(activity) do
            -- no activity...
            if instance ~= 'master' and count == 0 then
               -- restarting:
               if handles[instance] then
                  log(instance, 'job stalled, restarting...')
                  hoptions[instance].restartonce = true
                  handles[instance].kill()
               end
            end

            -- reset:
            activity[instance] = 0
         end
      end)
   end

   -- spawn kernel
   local spawnid = 1
   function spawn(process,procoptions,options)
      -- options
      options = options or {}
      procoptions = procoptions or {}

      -- generate or get name:
      local name = options.name or (process .. '_' ..spawnid)
      if not options.name then spawnid = spawnid + 1 end
      options.name = name

      -- spawn job:
      async.process.spawn(process, procoptions, function(handle,err)
         -- failed?
         if not handle then
            log('master', 'failed launching kernel ' .. name, err)
         else
            -- spawned:
            log('master', 'spawned kernel: ' .. name)

            -- save handle:
            handles[name] = handle
            hoptions[name] = options

            -- on data/err:
            handle.stdout.ondata(function(data)
               if thnode.logpreprocess(name,data) then
                  log(name,data)
               end
            end)
            handle.stderr.ondata(function(data)
               log(name,data)
            end)

            -- on exit, auto-restart:
            handle.onexit(function(status)
               -- clear:
               log(name, 'died with status: '..status)
               handles[name] = nil
               hoptions[name] = nil

               -- respawn:
               if (options.autorestart or options.restartonce) and not options.dontrestart then
                  options.restartonce = nil
                  options.dontrestart = nil
                  log(name, 'automaticall restarting')
                  spawn(process,procoptions,options)
               end
            end)
            thnode.newprocess(name)
         end
      end)
   end

   -- restart all == kill all + autorestart option
   function thnode.restart()
      log('master','restarting all jobs')
      for h,handle in pairs(handles) do
         hoptions[h].restartonce = true
         handle.kill()
      end
   end

   -- kill all == just killall
   function thnode.killall()
      log('master','restarting all jobs')
      for h,handle in pairs(handles) do
         hoptions[h].dontrestart = true
         handle.kill()
      end
   end

   -- ps
   function thnode.ps()
      log('master','ps:')
      for h,handle in pairs(handles) do
         log('master', h)
      end
   end

   -- git
   function thnode.git(arg,cb)
      async.process.exec('git', {arg}, function(res)
         log('master',res)
         if cb then cb() end
      end)
   end

   -- update code + restart
   function thnode.update()
      thnode.git('pull', restart)
   end

   -- kill zombies
   function thnode.zombies()
      local f = io.popen('ps -ef | grep luajit')
      local res = f:read('*all')

      local lines = stringx.split(res, '\n')
      local parsed = {}
      for _,line in ipairs(lines) do
         local _,_,e1,e2,e3 = line:find('(.-)%s+(.-)%s+(.-)%s+')
         if e1 and not line:find('grep') then
            table.insert(parsed, {user=e1, pid=tonumber(e2), ppid=tonumber(e3)})
         end
      end
      log('master','found ' .. (#parsed-1) .. ' LuaJIT processes')

      local count = 0
      for _,parsed in ipairs(parsed) do
         if parsed.ppid == 1 then
            log('master','process ' .. parsed.pid .. ' is a zombie')
            count = count + 1
            os.execute('kill -9 ' .. parsed.pid)
            log('master','killed!')
         end
      end
      log('master','found and killed ' .. count .. ' zombies')
   end



   ---------------------------------
   
   function thnode.setlogpreprocess(cb)
      logpreprocess = cb 
   end

   function thnode.onnewprocess(cb)
      newprocess = cb 
   end


   return thnode

end
