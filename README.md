THMAP
=====

A simple distributed framework to map jobs/work onto multiple workers.

Install
-------

```sh
luarocks install thmap
```

Use
---

On the compute machine(s), run `thnode`:

```sh
thnode
```

Write a config file that lists all the available nodes (`config.lua`):

```lua
-- example configuration, with two nodes:
return {
   {host='ip1', port=10001},
   {host='ip2', port=10001}
}
```

(by default, `thnode` listens to port 10001, then increments if not available).

Then start `thmap` to start monitoring and dispatching jobs:

```sh
thmap
ip1:10001> ip2:10002> spawn('th', {'test.lua'})
...
```

The above shows you a double shell: you are connected to two `thnode` instances,
and any command you issue will be mirrored to both.

In its current version, `thmap` supports the following commands:

* spawn a job:            spawn('th', {'script.lua', 'opt1', 'opt2', ...}, {autorestart=true})
* restart running jobs:   restart()
* list running jobs:      ps()
* exec git command:       git 'pull'  /  git 'status'
* git pull + restart:     update()
* kill all zombies:       zombies()
