##Pssh.

Ever have an itch to show code off to your buddies? Or how about make an ASCII dog
run across the screen while your co-workers watch in awe?

What about just wanting to pair program without all the hassle of setting up an SSH
user, figuring out how the heck to get tmux to integrate everything, and then
opening up port 22 on your firewall to let everyone know you're ready and willing
for the all the brute force attacks your network can handle.

What if it was as simple as opening up a new shell, or a tab in tmux or screen,
typing four letters, then sharing a URL with a friend?

Pssh. Is that even possible?

Yup.

```ruby
> gem install pssh
# to get started, just run it from the command line
> pssh
```

It defaults to running on port 8022, but throw in a `-p PORT` flag and you're
up and running on whatever port.  If you're in a tmux or screen session, it'll
share that.  If you're not, no worries. **Pssh has its own session sharing built in.**

If you're already in a tmux or screen session, you'll have a pseudo-terminal
that lets you see who's connected, kick people off, and a few other handy things.

If you started `pssh` in a plain shell, you'll be immediately transported into
that shell. Just type `exit` to quit and kick everyone else off too.

Check out all the options with the `-h` flag, or list the console commands by
typing `help` when you start up Pssh inside tmux/screen.

There's also support in there for HTTP basic authentication if you're running
behind that layer. But that adds to the complexities.

You know what makes all this even easier? <a href="https://getportly.com">Portly</a> does.
Install Portly in seconds, add `localhost:8022` to your connections, and you can
add authentication and share a classy URL right there on the spot.

Thanks to those who are working on <a href="https://github.com/chjj/term.js/">term.js</a> and <a href="https://github.com/aluzzardi/wssh">WSSH</a> for making the job easier.
