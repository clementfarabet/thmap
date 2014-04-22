THMAP
=====

A simple distributed framework to map jobs/work onto multiple workers.

The framework provides two binaries: `thmap` and `thnode`. `thmap` is a controller,
that lets you mirror commands to multiple `thnode` instances, and absorb the output
of all these `thnode` instances in //.

The general philosophy is that you run a bunch of `thnode` instances on multiple machines,
then run `thmap` everytime you need to schedule/run new scripts onto these nodes.

`thmap` lets you git pull, and reload scripts, so that you can easily update a 
distributed code base.

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

Write a config file that lists all the available nodes (`nodes.lua`):

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
thmap --nodes nodes.lua
ip1:10001> ip2:10002> spawn('th', {'test.lua'})
...
```

The above shows you a double shell: you are connected to two `thnode` instances,
and any command you issue will be mirrored to both.

In its current version, `thmap` supports the following commands:

* spawn a job:            `spawn('th', {'script.lua', 'opt1', 'opt2', ...}, {autorestart=true})`
* restart running jobs:   `restart()`
* list running jobs:      `ps()`
* exec git command:       `git 'pull'  /  git 'status'`
* git pull + restart:     `update()`
* kill all zombies:       `zombies()`
